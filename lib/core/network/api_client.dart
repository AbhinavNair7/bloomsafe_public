import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/error/error_reporter.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/core/network/interceptors/error_interceptor.dart';
import 'package:bloomsafe/core/network/interceptors/logging_interceptor.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/constants/aqi_constants.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/config/api_config.dart';
import 'package:sentry_dio/sentry_dio.dart';

/// Extension for API client to access AppConfig properties
extension ApiClientAppConfigExtension on AppConfig {
  /// Pass-through to get the disableRateLimit flag from EnvConfig
  bool get disableRateLimit => EnvConfig().disableRateLimit;
}

/// ApiClient handles all network requests to the AirNow API.
class ApiClient {

  /// Creates a new ApiClient with EnvConfig
  ApiClient(EnvConfig envConfig)
    : _envConfig = envConfig,
      _appConfig = null,
      _dio = _createDioInstance(),
      rateLimiter = RateLimiter() {
    _addSentryReporting();
  }

  /// Creates a new ApiClient with AppConfig
  ApiClient.withAppConfig({required AppConfig appConfig})
    : _appConfig = appConfig,
      _envConfig = null,
      _dio = _createDioInstance(),
      rateLimiter = RateLimiter() {
    _addSentryReporting();
  }

  /// Constructor for testing
  @visibleForTesting
  ApiClient.forTesting({
    required Dio dio,
    required AppConfig appConfig,
    RateLimiter? testRateLimiter,
  }) : _dio = dio,
       _appConfig = appConfig,
       _envConfig = null,
       rateLimiter = testRateLimiter ?? RateLimiter();
  final Dio _dio;
  final EnvConfig? _envConfig;
  final AppConfig? _appConfig;
  final RateLimiter rateLimiter;

  /// Create and configure a Dio instance
  static Dio _createDioInstance() {
    final dio = Dio(
      BaseOptions(
        baseUrl: aqiBaseUrl,
        connectTimeout: defaultConnectTimeout,
        receiveTimeout: defaultReceiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add default interceptors
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(LoggingInterceptor());

    // Add Sentry integration for request monitoring
    _addSentryToDio(dio);

    return dio;
  }

  /// Safely add Sentry integration to Dio
  static void _addSentryToDio(Dio dio) {
    try {
      // Add Sentry to Dio using the extension method
      dio.addSentry(captureFailedRequests: true);
      Logger.debug('Sentry integration added to Dio client');
    } catch (e) {
      // Never fail initialization due to Sentry integration issues
      Logger.warning('Sentry Dio integration unavailable: $e');
    }
  }

  /// Add privacy-focused error reporting to Dio
  void _addSentryReporting() {
    try {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Only sanitize zipcode data in requests, leaving other data intact
            if (options.queryParameters.containsKey(aqiZipCodeParam)) {
              // Create sanitized parameters for logging, protecting only zipcode
              final sanitizedParams = Map<String, dynamic>.from(options.queryParameters);
              if (sanitizedParams.containsKey(aqiZipCodeParam) && 
                  sanitizedParams[aqiZipCodeParam] is String) {
                // Get the zipcode value
                final zipcode = sanitizedParams[aqiZipCodeParam] as String;
                // Only sanitize if it looks like a 5-digit zipcode
                if (RegExp(r'^\d{5}$').hasMatch(zipcode)) {
                  // Keep first 3 digits for general location, mask last 2
                  sanitizedParams[aqiZipCodeParam] = '${zipcode.substring(0, 3)}XX';
                }
              }
              
              Logger.debug(
                'API Request to ${options.path} with params: $sanitizedParams',
              );
            }
            handler.next(options);
          },
          onError: (error, handler) {
            // Extract safely loggable data for error reporting
            final extras = {
              'method': error.requestOptions.method,
              'path': error.requestOptions.path,
              'status': error.response?.statusCode,
              'request_type': 'dio_request',
              'network_error': true,
            };
            
            // Report network errors with proper privacy measures
            ErrorReporter.report(
              error,
              StackTrace.current,
              context: 'network_request',
              extras: extras,
            );
            handler.next(error);
          },
          onResponse: (response, handler) {
            // Only capture error responses (4xx, 5xx)
            if (response.statusCode != null && response.statusCode! >= 400) {
              final extras = {
                'method': response.requestOptions.method,
                'path': response.requestOptions.path,
                'status': response.statusCode,
              };
              
              ErrorReporter.reportMessage(
                'HTTP Error ${response.statusCode}',
                extras: extras,
              );
            }
            handler.next(response);
          },
        ),
      );
    } catch (e) {
      // Never fail initialization due to error reporting issues
      Logger.warning('Failed to add error reporting to Dio: $e');
    }
  }

  /// Get access to dio for tests
  @visibleForTesting
  Dio get dio => _dio;

  /// Gets the AirQuality data by ZIP code
  Future<List<dynamic>> getAirQualityByZipCode(
    String zipCode,
    String format,
    int distance, [
    String? apiKey,
  ]) async {
    final key = apiKey ?? await _getApiKey();
    if (key == null || key.isEmpty) {
      throw GenericApiException('API key not available');
    }

    final queryParams = {
      aqiZipCodeParam: zipCode,
      aqiFormatParam: format,
      aqiDistanceParam: distance.toString(),
      aqiApiKeyParam: key,
    };

    final data = await get(aqiBaseUrl, queryParams: queryParams);
    if (data == null || (data is List && data.isEmpty)) {
      throw NotFoundException('No air quality data found for this location.');
    }

    return data as List<dynamic>;
  }

  /// Gets the API key from the appropriate config
  Future<String?> _getApiKey() async {
    if (_appConfig != null) {
      return await _appConfig.getSecureApiKey();
    } else if (_envConfig != null) {
      return await _envConfig.getSecureApiKey();
    }
    return null;
  }

  /// Executes a GET request with rate limiting
  Future<dynamic> get(
    String endpoint, {
    Map<String, String?>? queryParams,
    bool enforceRateLimit = true,
  }) async {
    if (enforceRateLimit) {
      await verifyRateLimit(endpoint);
    }

    try {
      final response = await _makeRequest(
        () =>
            _dio.get(endpoint, queryParameters: _cleanQueryParams(queryParams)),
      );

      if (enforceRateLimit) {
        await recordRequest(endpoint);
      }

      return response.data;
    } on DioException catch (e) {
      _handleDioException(e, endpoint);
    } catch (e) {
      Logger.error('ApiClient: Unexpected error on GET $endpoint: $e');
      rethrow;
    }
  }

  /// Records a request for rate limiting
  Future<void> recordRequest(String endpoint) async {
    await rateLimiter.recordRequest();
    final status = await rateLimiter.status;
    Logger.debug('ApiClient: Rate limit status: $status');
  }

  /// Checks if rate limit allows the request
  Future<void> verifyRateLimit(String endpoint) async {
    final isDisabled = _getRateLimitDisabledStatus();
    if (isDisabled) {
      Logger.debug('ApiClient: Rate limiting is disabled by configuration');
      return;
    }

    final isAllowed = await rateLimiter.isRequestAllowed();
    if (!isAllowed) {
      Logger.error(
        'ApiClient: Rate limit exceeded. Request to $endpoint denied.',
      );
      final remainingSeconds = await rateLimiter.lockoutRemainingSeconds();
      throw RateLimitExceededException(
        maxSearchesReachedMessage,
        RateLimitType.clientSide,
        remainingSeconds,
      );
    }
  }

  /// Helper to get rate limit disabled status
  bool _getRateLimitDisabledStatus() {
    if (_appConfig != null) {
      return _appConfig.disableRateLimit;
    } else if (_envConfig != null) {
      return _envConfig.disableRateLimit;
    }
    return false;
  }

  /// Gets current rate limit status
  Future<RateLimitStatus> getRateLimitStatus() async {
    return await rateLimiter.status;
  }

  /// Determines if only cache should be used
  Future<bool> shouldUseCacheOnly() async {
    final status = await getRateLimitStatus();
    return status == RateLimitStatus.exceeded;
  }

  /// Executes a POST request with rate limiting
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool enforceRateLimit = true,
  }) async {
    if (enforceRateLimit) {
      await verifyRateLimit(endpoint);
    }

    try {
      final response = await _makeRequest(
        () => _dio.post(endpoint, data: body),
      );

      if (enforceRateLimit) {
        await recordRequest(endpoint);
      }

      return response.data;
    } on DioException catch (e) {
      _handleDioException(e, endpoint);
    } catch (e) {
      Logger.error('ApiClient: Unexpected error on POST $endpoint: $e');
      rethrow;
    }
  }

  // Convert DioExceptions to ApiExceptions
  Never _handleDioException(DioException e, String endpoint) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 429) {
        Logger.error('ApiClient: API rate limit exceeded on $endpoint');
        final responseString = e.response?.data.toString() ?? '';
        if (responseString.contains('Web service request limit exceeded')) {
          throw RateLimitExceededException(
            apiHourlyRateLimitExceededMessage,
            RateLimitType.serverHourly,
          );
        } else {
          throw RateLimitExceededException(
            apiRateLimitExceededMessage,
            RateLimitType.serverMinute,
          );
        }
      } else if (statusCode == 404) {
        throw NotFoundException('Resource not found: $endpoint');
      } else if (statusCode == 401) {
        throw UnauthorizedException();
      } else if (statusCode == 403) {
        throw ForbiddenException();
      } else if (statusCode != null && statusCode >= 500) {
        throw ServerException('Server error: ${e.response?.data ?? e.message}');
      } else {
        throw GenericApiException(
          'API error: ${e.response?.data ?? e.message}',
        );
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw TimeoutException();
    } else if (e.type == DioExceptionType.connectionError) {
      throw ConnectivityException();
    } else {
      throw GenericApiException('Request failed: ${e.message}');
    }
  }

  // Clean query parameters by removing null values
  Map<String, dynamic> _cleanQueryParams(Map<String, String?>? params) {
    if (params == null) return {};

    final cleanedParams = <String, dynamic>{};
    params.forEach((key, value) {
      if (value != null) {
        cleanedParams[key] = value;
      }
    });
    return cleanedParams;
  }

  // Make a request with one retry for transient errors
  Future<Response<dynamic>> _makeRequest(
    Future<Response<dynamic>> Function() requestFn,
  ) async {
    try {
      return await requestFn();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          (statusCode != null && statusCode >= 500)) {
        try {
          Logger.warning(
            'ApiClient: Retrying request after error: ${e.message}',
          );
          return await requestFn();
        } catch (retryError) {
          rethrow;
        }
      }
      rethrow;
    }
  }
}
