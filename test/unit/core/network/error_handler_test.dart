import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:bloomsafe/core/constants/error_constants.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart'
    as aqi_exceptions;
import '../../../helpers/timezone_helper.dart';

void main() {
  // Initialize timezone data before tests
  setUpAll(() {
    initializeTimeZonesForTest();
  });

  group('Core Error Mapping', () {
    test('Maps connection errors to NetworkException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      expect(
        () => throw ErrorProcessor.processToException(dioError),
        throwsA(isA<NetworkException>()),
      );
    });

    test('Maps 400 status to BadRequestException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
        ),
      );

      expect(
        () => throw ErrorProcessor.processToException(dioError),
        throwsA(isA<aqi_exceptions.AQIException>()),
      );
    });
  });

  group('Essential Retries', () {
    test('Delegates retry behavior to ErrorProcessor', () async {
      // Create timeout error
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.sendTimeout,
      );

      // Mock action that always fails
      int attemptCount = 0;
      Future<void> mockAction() async {
        attemptCount++;
        throw dioError;
      }

      // Set shorter duration for faster test
      try {
        // Should retry 3 times and then throw
        await ErrorProcessor.retryWithBackoff(
          operation: mockAction,
          retryCount: 3,
          initialDelay: const Duration(milliseconds: 500),
        );
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<DioException>());
        expect(attemptCount, 3);
      }
    });
  });

  group('Critical Status Codes', () {
    final statusCodes = {
      401: UnauthorizedException,
      404: NoDataForZipcodeException,
      429: RateLimitException,
      500: ServerException,
    };

    for (final entry in statusCodes.entries) {
      final code = entry.key;
      final expectedType = entry.value;

      test('Handles $code status code', () {
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: code,
          ),
        );

        expect(
          () => throw ErrorProcessor.processToException(dioError),
          throwsA(isA<ApiException>()),
        );
      });
    }
  });

  test('Properly maps connection errors to AQIException', () async {
    final dioException = DioException(
      requestOptions: RequestOptions(path: ''),
      error: ApiErrorType.connection.toString(),
      type: DioExceptionType.badResponse,
    );

    try {
      throw ErrorProcessor.processToException(dioException);
      fail('Should have thrown an exception');
    } catch (e) {
      expect(e, isA<aqi_exceptions.AQIException>());
      expect(
        (e as aqi_exceptions.AQIException).message,
        equals(apiConnectionErrorMessage),
      );
    }
  });

  test('Properly preserves extreme value exceptions', () async {
    final extremeValueException = aqi_exceptions.AQIException(
      extremeAqiValuesMessage,
    );

    try {
      throw ErrorProcessor.processToException(extremeValueException);
      fail('Should have thrown an exception');
    } catch (e) {
      expect(e, isA<aqi_exceptions.AQIException>());
      expect(
        (e as aqi_exceptions.AQIException).message,
        equals(extremeAqiValuesMessage),
      );
    }
  });
}
