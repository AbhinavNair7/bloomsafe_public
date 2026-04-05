import 'dart:io';

import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart' hide NoDataForZipcodeException;
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/error_test_helper.dart';

void main() {
  group('ErrorProcessor', () {
    group('process', () {
      test('categorizes network exceptions correctly', () {
        // Test SocketException
        final socketError = ErrorProcessor.process(const SocketException('Failed to connect'));
        expect(socketError.category, equals(ErrorCategory.network));
        
        // Test DioException with connectionTimeout
        final dioTimeoutError = ErrorProcessor.process(
          ErrorTestHelper.createTimeoutError(),
        );
        expect(dioTimeoutError.category, equals(ErrorCategory.network));
        
        // Test DioException with connectionError
        final dioConnectionError = ErrorProcessor.process(
          ErrorTestHelper.createConnectionError(),
        );
        expect(dioConnectionError.category, equals(ErrorCategory.network));
      });

      test('categorizes validation exceptions correctly', () {
        final zipCodeError = ErrorProcessor.process(
          InvalidZipcodeException('Invalid ZIP code'),
        );
        expect(zipCodeError.category, equals(ErrorCategory.validation));
      });

      test('categorizes rate limit exceptions correctly', () {
        // Test RateLimitException
        final rateLimitError = ErrorProcessor.process(
          RateLimitException('Rate limit exceeded'),
        );
        expect(rateLimitError.category, equals(ErrorCategory.rateLimit));
        
        // Test DioException with 429 status code
        final dioRateLimitError = ErrorProcessor.process(
          ErrorTestHelper.createRateLimitError(),
        );
        expect(dioRateLimitError.category, equals(ErrorCategory.rateLimit));
      });

      test('categorizes server exceptions correctly', () {
        // Test ServerException
        final serverError = ErrorProcessor.process(
          ServerException('Server error'),
        );
        expect(serverError.category, equals(ErrorCategory.api));
        
        // Test DioException with 500 status code
        final dioServerError = ErrorProcessor.process(
          ErrorTestHelper.createServerError(statusCode: 500),
        );
        expect(dioServerError.category, equals(ErrorCategory.api));
      });

      test('handles HTML error responses correctly', () {
        // Test 504 Gateway Timeout HTML response
        final html504Response = '''<html>
<head><title>504 Gateway Time-out</title></head>
<body>
<center><h1>504 Gateway Time-out</h1></center>
</body>
</html>''';
        
        final serverError504 = ErrorProcessor.process(
          ServerException('Server error: $html504Response'),
        );
        expect(serverError504.category, equals(ErrorCategory.api));
        expect(serverError504.userMessage, equals(apiConnectionErrorMessage));
        
        // Test 502 Bad Gateway HTML response
        final html502Response = '''<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
</body>
</html>''';
        
        final serverError502 = ErrorProcessor.process(
          ServerException('Server error: $html502Response'),
        );
        expect(serverError502.category, equals(ErrorCategory.api));
        expect(serverError502.userMessage, equals(apiConnectionErrorMessage));
        
        // Test non-HTML ServerException (should use original message)
        final regularServerError = ErrorProcessor.process(
          ServerException('Database connection failed'),
        );
        expect(regularServerError.category, equals(ErrorCategory.api));
        expect(regularServerError.userMessage, equals('Database connection failed'));
      });

      test('categorizes business exceptions correctly', () {
        final noDataError = ErrorProcessor.process(
          NoDataForZipcodeException('No data for ZIP code'),
        );
        expect(noDataError.category, equals(ErrorCategory.business));
      });

      test('categorizes unknown exceptions correctly', () {
        final unknownError = ErrorProcessor.process(Exception('Unknown error'));
        expect(unknownError.category, equals(ErrorCategory.unknown));
      });
    });

    group('processToException', () {
      test('preserves original ApiException type', () {
        final originalException = NetworkException('Network error');
        final processedException = ErrorProcessor.processToException(originalException);
        expect(processedException, equals(originalException));
      });

      test('converts to NetworkException for network errors', () {
        final socketException = const SocketException('Failed to connect');
        final processedException = ErrorProcessor.processToException(socketException);
        expect(processedException, isA<NetworkException>());
      });

      test('converts to RateLimitException for rate limit errors', () {
        final rateLimitError = ErrorProcessor.processToException(
          ErrorTestHelper.createRateLimitError(),
        );
        expect(rateLimitError, isA<RateLimitException>());
      });
    });

    group('retryWithBackoff', () {
      test('returns result on successful operation', () async {
        int attempts = 0;
        final result = await ErrorProcessor.retryWithBackoff<String>(
          operation: () async {
            attempts++;
            return 'success';
          },
          retryCount: 3,
        );

        expect(result, equals('success'));
        expect(attempts, equals(1)); // Only one attempt needed
      });

      test('retries until success', () async {
        int attempts = 0;
        final result = await ErrorProcessor.retryWithBackoff<String>(
          operation: () async {
            attempts++;
            if (attempts < 3) {
              throw const SocketException('Test failure');
            }
            return 'success after retry';
          },
          retryCount: 5,
          initialDelay: const Duration(milliseconds: 10), // Lower delay for tests
        );

        expect(result, equals('success after retry'));
        expect(attempts, equals(3)); // Three attempts needed for success
      });

      test('throws exception after max retries', () async {
        int attempts = 0;
        
        expectLater(
          () => ErrorProcessor.retryWithBackoff<String>(
            operation: () async {
              attempts++;
              throw const SocketException('Test failure');
            },
            retryCount: 3,
            initialDelay: const Duration(milliseconds: 10), // Lower delay for tests
          ),
          throwsA(isA<SocketException>()),
        );
        
        // Wait for all retries to complete
        await Future.delayed(const Duration(milliseconds: 100));
        expect(attempts, equals(3)); // Should have made 3 attempts
      });

      test('does not retry if shouldRetry returns false', () async {
        int attempts = 0;
        
        expectLater(
          () => ErrorProcessor.retryWithBackoff<String>(
            operation: () async {
              attempts++;
              throw RateLimitException('Rate limit exceeded');
            },
            retryCount: 3,
            initialDelay: const Duration(milliseconds: 10),
          ),
          throwsA(isA<RateLimitException>()),
        );
        
        // Wait for any potential retries
        await Future.delayed(const Duration(milliseconds: 50));
        expect(attempts, equals(1)); // Should only make 1 attempt, no retries
      });
    });

    group('processAndReport', () {
      test('should process error and report it to ErrorReporter', () {
        // This test would ideally mock ErrorReporter and verify it's called
        // For simplicity, we'll just check the returned ErrorResult
        final error = NetworkException('Network error');
        final result = ErrorProcessor.processAndReport(error);

        expect(result.category, equals(ErrorCategory.network));
        expect(result.userMessage, equals('Network error'));
        expect(result.shouldRetry, isTrue);
        expect(result.originalException, equals(error));
      });
    });
  });
}
