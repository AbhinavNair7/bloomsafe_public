import 'package:dio/dio.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Custom error interceptor for handling various API error scenarios
/// Now uses the centralized ErrorProcessor for consistent error handling
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Use the ErrorProcessor to process the error
    try {
      // Get request information for context
      final endpoint = err.requestOptions.path;
      final params = err.requestOptions.queryParameters;

      // Create a context string with relevant information
      final context = 'Endpoint: $endpoint, Params: $params';

      // Process the error using the ErrorProcessor
      final Exception customException = ErrorProcessor.processToException(
        err,
        context: context,
      );

      // Log specific rate limit details if applicable
      if (customException is RateLimitException) {
        _logRateLimitDetails(err, customException);
      }

      // Create a new error with our custom exception
      final customError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: customException,
      );

      // Pass modified error to next interceptor
      handler.next(customError);
    } catch (e) {
      // If something goes wrong during processing, default to GenericApiException
      Logger.error('Error during exception processing: ${e.toString()}');

      final customError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: GenericApiException(apiConnectionErrorMessage),
      );

      handler.next(customError);
    }
  }

  /// Log detailed information about rate limit errors
  void _logRateLimitDetails(DioException error, RateLimitException exception) {
    // Log headers that might contain rate limit information
    final headers = error.response?.headers;
    if (headers != null) {
      final rateLimitHeaders =
          headers.map.entries
              .where(
                (e) =>
                    e.key.toLowerCase().contains('rate') ||
                    e.key.toLowerCase().contains('limit'),
              )
              .toList();

      if (rateLimitHeaders.isNotEmpty) {
        Logger.error(
          'Rate limit headers: ${rateLimitHeaders.map((e) => '${e.key}: ${e.value.join(',')}').join(', ')}',
        );
      }
    }

    // Log response data for debugging
    if (error.response?.data != null) {
      Logger.error('Rate limit response data: ${error.response?.data}');
    }

    Logger.error('User message for rate limit: ${exception.message}');
  }

  /// Extract the 'Retry-After' header to determine when to retry the request
  int? _extractRetryAfterHeader(DioException err) {
    final String? retryAfter = err.response?.headers['retry-after']?.first;
    if (retryAfter != null) {
      try {
        return int.parse(retryAfter);
      } catch (_) {
        // If it's a date instead of seconds, we'd parse the date
        // (Skipping this implementation for brevity)
      }
    }
    return null;
  }
}
