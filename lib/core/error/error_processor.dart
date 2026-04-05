import 'dart:async';
import 'dart:io';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/error/error_reporter.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart'
    hide NoDataForZipcodeException;
import 'package:dio/dio.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Error categories used for classification
enum ErrorCategory {
  /// Network connectivity issues
  network,

  /// Input validation errors
  validation,

  /// API-related issues (timeouts, server errors)
  api,

  /// Business logic errors
  business,

  /// Rate limiting errors
  rateLimit,

  /// Unknown errors that couldn't be classified
  unknown,
}

/// Centralized error processing system for consistent error handling across the app
///
/// The ErrorProcessor provides:
/// 1. Error categorization for consistent UI feedback
/// 2. User-friendly error messages
/// 3. Retry logic for transient errors
/// 4. Standardized error reporting through Sentry
///
/// This class follows the principle of separating processing from reporting,
/// allowing repository layers to handle the actual error reporting.
class ErrorProcessor {
  /// Process any error/exception into a standardized format without reporting it
  /// Returns an [ErrorResult] containing categorized information about the error
  static ErrorResult process(dynamic error, {String? context}) {
    final category = _categorizeError(error);
    final userMessage = _getUserMessage(error, category);
    final shouldRetry = _shouldRetryError(error, category);
    final originalException = error;

    // Do not report to Sentry here to avoid duplicate reporting
    // Repository layer should handle error reporting directly

    return ErrorResult(
      category: category,
      userMessage: userMessage,
      shouldRetry: shouldRetry,
      originalException: originalException,
      context: context,
    );
  }

  /// Process and report error to Sentry (use only when direct reporting is needed)
  static ErrorResult processAndReport(dynamic error, {String? context}) {
    final result = process(error, context: context);
    
    // Report error to Sentry for monitoring
    ErrorReporter.report(
      error,
      StackTrace.current,
      context: context,
      extras: {
        'error_category': result.category.toString(),
        'should_retry': result.shouldRetry,
      },
    );
    
    return result;
  }

  /// Process error and return a specific exception type
  /// This is useful for maintaining the existing exception hierarchy
  static Exception processToException(dynamic error, {String? context}) {
    final result = process(error, context: context);

    // If the original error is already a known exception type, preserve it
    if (error is ApiException) {
      return error;
    }

    // Convert to appropriate exception type based on category
    switch (result.category) {
      case ErrorCategory.network:
        return NetworkException(result.userMessage);
      case ErrorCategory.validation:
        // If context indicates validation for zipcode, return InvalidZipcodeException
        if (context?.toLowerCase().contains('zipcode') == true) {
          return InvalidZipcodeException(result.userMessage);
        }
        return AQIException(result.userMessage);
      case ErrorCategory.rateLimit:
        if (error is RateLimitException) {
          return error;
        }
        return RateLimitException(result.userMessage);
      case ErrorCategory.api:
      case ErrorCategory.business:
      case ErrorCategory.unknown:
        return AQIException(result.userMessage);
    }
  }

  /// Get a fallback error message for the given error category
  static String getFallbackErrorMessage(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.network:
        return noInternetConnectionMessage;
      case ErrorCategory.validation:
        return invalidZipCodeLengthError;
      case ErrorCategory.api:
        return apiConnectionErrorMessage;
      case ErrorCategory.business:
        return apiConnectionErrorMessage;
      case ErrorCategory.rateLimit:
        return maxSearchesReachedMessage;
      case ErrorCategory.unknown:
        return apiConnectionErrorMessage;
    }
  }

  /// Attempt to retry an operation with exponential backoff
  ///
  /// [operation] is the function to retry
  /// [retryCount] is the maximum number of retry attempts
  /// [initialDelay] is the delay before the first retry
  /// Returns the result of the operation or throws if all retries fail
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int retryCount = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    Duration delay = initialDelay;

    // Try initial attempt
    try {
      return await operation();
    } catch (e) {
      // If we shouldn't retry this error type or we have no retries left, rethrow
      final actualShouldRetry =
          shouldRetry?.call(e) ?? _shouldRetryError(e, _categorizeError(e));

      if (!actualShouldRetry || retryCount <= 0) {
        rethrow;
      }

      // Wait before first retry
      Logger.info('🔄 Retry attempt 1 after $delay: ${e.toString()}');
      await Future.delayed(delay);
    }

    // Handle retries with exponential backoff
    for (int attempt = 1; attempt < retryCount; attempt++) {
      try {
        return await operation();
      } catch (e) {
        final actualShouldRetry =
            shouldRetry?.call(e) ?? _shouldRetryError(e, _categorizeError(e));

        // If this is the last attempt or we shouldn't retry, rethrow
        if (attempt >= retryCount - 1 || !actualShouldRetry) {
          rethrow;
        }

        // Double the delay for exponential backoff
        delay *= 2;

        // Log and wait before next retry
        Logger.info(
          '🔄 Retry attempt ${attempt + 1} after $delay: ${e.toString()}',
        );
        await Future.delayed(delay);
      }
    }

    // Final attempt
    return await operation();
  }

  /// Categorize an error based on its type and properties
  static ErrorCategory _categorizeError(dynamic error) {
    // Handle ApiException subtypes
    if (error is NetworkException) return ErrorCategory.network;
    if (error is InvalidZipcodeException) return ErrorCategory.validation;
    if (error is RateLimitException) return ErrorCategory.rateLimit;
    if (error is ServerException) return ErrorCategory.api;
    if (error is NoDataForZipcodeException) return ErrorCategory.business;
    if (error is AQIException) return ErrorCategory.api;

    // Handle standard network exceptions
    if (error is SocketException || 
        error is HttpException || 
        error is TimeoutException) {
      return ErrorCategory.network;
    }

    // Handle Dio errors
    if (error is DioException) {
      return _categorizeDioException(error);
    }

    // Default fallback
    return ErrorCategory.unknown;
  }
  
  /// Categorize DioException by type and status code
  static ErrorCategory _categorizeDioException(DioException error) {
    // Network-related errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.cancel ||
        error.type == DioExceptionType.badCertificate) {
      return ErrorCategory.network;
    }
    
    // Handle HTTP response errors
    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      
      if (statusCode == 429) return ErrorCategory.rateLimit;
      if (statusCode != null && statusCode >= 500) return ErrorCategory.api;
      if (statusCode != null && statusCode >= 400) return ErrorCategory.business;
      return ErrorCategory.api;
    }
    
    // Unknown errors with socket exception
    if (error.type == DioExceptionType.unknown && 
        (error.error is SocketException || error.error is HttpException)) {
      return ErrorCategory.network;
    }
    
    return ErrorCategory.unknown;
  }

  /// Determine if an error should be retried
  static bool _shouldRetryError(dynamic error, ErrorCategory category) {
    // Categories that should never be retried
    if (category == ErrorCategory.rateLimit || 
        category == ErrorCategory.validation) {
      return false;
    }

    // Categories that are generally retryable
    if (category == ErrorCategory.network || 
        category == ErrorCategory.api) {
      return true;
    }

    // Specific exception types
    if (error is NetworkException || error is ServerException) {
      return true;
    }

    // For Dio errors, check status codes and error types
    if (error is DioException) {
      // Network errors and timeouts can be retried
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }
      
      // Server errors (5xx) can be retried
      if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      }
    }

    return false;
  }

  /// Extract user-friendly message from the error
  static String _getUserMessage(dynamic error, ErrorCategory category) {
    // Try to extract message from ApiException
    if (error is ApiException) {
      // For ServerException, check if message contains HTML error page
      if (error is ServerException && _isHtmlErrorResponse(error.message)) {
        return apiConnectionErrorMessage;
      }
      return error.message;
    }

    // Try to extract message from DioException
    if (error is DioException) {
      return _getDioErrorMessage(error);
    }

    // Use fallback messages based on category
    return getFallbackErrorMessage(category);
  }

  /// Check if error message contains HTML response
  static bool _isHtmlErrorResponse(String message) {
    return message.contains('<html>') || message.contains('<title>');
  }

  /// Extract user-friendly message specifically from DioException
  static String _getDioErrorMessage(DioException error) {
    final errorType = error.type;
    final statusCode = error.response?.statusCode;
    
    // Handle network and timeout errors
    if (errorType == DioExceptionType.connectionError || 
        error.error is SocketException) {
      return noInternetConnectionMessage;
    }
    
    // Handle timeouts
    if (errorType == DioExceptionType.connectionTimeout ||
        errorType == DioExceptionType.sendTimeout ||
        errorType == DioExceptionType.receiveTimeout) {
      return apiConnectionErrorMessage;
    }
    
    // Handle HTTP status code errors
    if (errorType == DioExceptionType.badResponse && statusCode != null) {
      // Rate limit errors
      if (statusCode == 429) {
        final responseString = error.response?.data.toString() ?? '';
        return responseString.contains('Web service request limit exceeded')
            ? apiHourlyRateLimitExceededMessage
            : apiRateLimitExceededMessage;
      }
      
      // Authentication errors
      if (statusCode == 401 || statusCode == 403) {
        return 'Authentication error. Please check your API key.';
      }
      
      // Not found errors
      if (statusCode == 404) {
        return 'No data available for this location.';
      }
      
      // Server errors
      if (statusCode >= 500) {
        return apiConnectionErrorMessage;
      }
    }
    
    // Connection errors with specific API error type
    if (error.error?.toString().contains('ApiErrorType.connection') == true) {
      return apiConnectionErrorMessage;
    }
    
    // Default error message
    return 'Error retrieving data: ${error.message}';
  }
}

/// Standardized error result containing all necessary information
class ErrorResult {

  /// Creates a new ErrorResult
  const ErrorResult({
    required this.category,
    required this.userMessage,
    required this.shouldRetry,
    required this.originalException,
    this.context,
  });
  /// The category of the error
  final ErrorCategory category;

  /// User-friendly error message
  final String userMessage;

  /// Whether this error can be retried
  final bool shouldRetry;

  /// The original exception that caused this error
  final dynamic originalException;

  /// Optional context information (e.g., zipcode)
  final String? context;

  @override
  String toString() {
    return 'ErrorResult{category: $category, message: $userMessage, shouldRetry: $shouldRetry, context: $context}';
  }
}

/// Gets a user-friendly error message from an exception
String getErrorMessage(dynamic error) {
  // Handle Dio errors
  if (error is DioException) {
    return ErrorProcessor._getDioErrorMessage(error);
  }

  // Handle API exceptions
  if (error is ApiException) {
    return error.message;
  }

  // Return the error message or a generic error message
  return error?.toString() ?? 'Unknown error occurred';
}
