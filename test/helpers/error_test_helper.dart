import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

/// A helper class for testing error handling scenarios
class ErrorTestHelper {
  /// Creates a DioError for network timeout testing
  static DioException createTimeoutError({String path = '/test'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionTimeout,
      error: 'Connection timeout',
    );
  }

  /// Creates a DioError for network connection error testing
  static DioException createConnectionError({String path = '/test'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
      error: 'Connection failed',
    );
  }

  /// Creates a DioError for server error testing
  static DioException createServerError({
    String path = '/test',
    int statusCode = 500,
    String message = 'Internal server error',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        statusMessage: message,
      ),
      error: message,
    );
  }

  /// Creates a DioError for invalid data error testing
  static DioException createInvalidDataError({
    String path = '/test',
    int statusCode = 200,
    Map<String, dynamic>? data,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: data ?? <String, dynamic>{},
      ),
      error: 'Invalid data structure',
    );
  }

  /// Creates a DioError for unauthorized error testing
  static DioException createUnauthorizedError({String path = '/test'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 401,
        statusMessage: 'Unauthorized',
      ),
      error: 'Unauthorized',
    );
  }

  /// Creates a DioError for forbidden error testing
  static DioException createForbiddenError({String path = '/test'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 403,
        statusMessage: 'Forbidden',
      ),
      error: 'Forbidden',
    );
  }

  /// Creates a DioError for rate limit error testing
  static DioException createRateLimitError({String path = '/test'}) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 429,
        statusMessage: 'Too Many Requests',
      ),
      error: 'Rate limit exceeded',
    );
  }

  /// Checks if an exception is of the expected type
  static void expectExceptionType<T extends Exception>(
    Function() function,
  ) {
    expect(() => function(), throwsA(isA<T>()));
  }

  /// Checks if a failure is of the expected type
  static void expectFailureType<T>(
    Function() function,
  ) {
    expect(() => function(), throwsA(isA<T>()));
  }
} 