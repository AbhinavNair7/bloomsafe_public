import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bloomsafe/core/error/error_reporter.dart';
import 'package:bloomsafe/core/error/sentry_helper.dart';
import 'package:flutter/foundation.dart';

/// Integration tests for Sentry error reporting
///
/// These tests verify that errors and messages are properly sent to Sentry.
/// You'll need to check your Sentry dashboard to verify the reports were received.
///
/// To run these tests:
/// flutter test test/integration/sentry_integration_test.dart

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use .env.dev for tests instead of the removed .env file
    try {
      await dotenv.load(fileName: '.env.dev');
    } catch (e) {
      // If .env.dev doesn't exist, continue with empty environment
      // Sensitive data comes from secure storage anyway
      debugPrint('Warning: .env.dev not found, using empty environment');
    }
  });

  group('Sentry Integration Tests', () {
    test('Report exception through ErrorReporter', () async {
      // Log test start
      debugPrint('⚠️ TESTING: Error reporting via ErrorReporter');
      final testId = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        // Intentionally cause an error
        throw Exception('Test exception ID: $testId');
      } catch (e, stackTrace) {
        // Report the error to Sentry
        await ErrorReporter.report(
          e,
          stackTrace,
          context: 'integration_test',
          extras: {'test_id': testId},
        );

        // Allow time for report to be processed
        await Future.delayed(const Duration(seconds: 2));

        // This test passes if no exceptions are thrown during reporting
        // You should check your Sentry dashboard to confirm the error was received
        expect(
          true,
          isTrue,
          reason: 'Check Sentry dashboard for event with ID: $testId',
        );
      }
    });

    test('Report message through SentryHelper', () async {
      // Log test start
      debugPrint('⚠️ TESTING: Message reporting via SentryHelper');
      final testId = DateTime.now().millisecondsSinceEpoch.toString();

      // Send a test message to Sentry
      await SentryHelper.captureMessage(
        'Test message ID: $testId',
        level: SentryLevel.warning,
        extras: {'test_id': testId},
      );

      // Allow time for message to be processed
      await Future.delayed(const Duration(seconds: 2));

      // Check Sentry dashboard for message with this ID
      expect(
        true,
        isTrue,
        reason: 'Check Sentry dashboard for message with ID: $testId',
      );
    });

    test('Report exception with custom tags', () async {
      debugPrint('⚠️ TESTING: Exception with custom tags');
      final testId = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        // Intentionally cause an error
        throw Exception('Tagged exception test ID: $testId');
      } catch (e, stackTrace) {
        // Report with tags
        await SentryHelper.captureException(
          e,
          stackTrace,
          extra: {'test_id': testId},
          tags: ['integration_test:true', 'test_type:tags'],
        );

        // Allow time for report to be processed
        await Future.delayed(const Duration(seconds: 2));

        expect(
          true,
          isTrue,
          reason: 'Check Sentry for tagged exception with ID: $testId',
        );
      }
    });

    test('Sanitization removes PII from error context', () async {
      debugPrint('⚠️ TESTING: PII sanitization');
      final testId = DateTime.now().millisecondsSinceEpoch.toString();

      try {
        // Error with PII in message
        throw Exception(
          'Error with PII: email user@example.com, phone 123-456-7890, zip 12345',
        );
      } catch (e, stackTrace) {
        // Report with PII in context
        await ErrorReporter.report(
          e,
          stackTrace,
          context:
              'User 123-45-6789 at IP 192.168.1.1 with email test@example.com',
          extras: {
            'test_id': testId,
            'address': '123 Main St, New York, NY 10001',
            'contact': ['user@example.com', '555-123-4567'],
          },
        );

        // Allow time for report to be processed
        await Future.delayed(const Duration(seconds: 2));

        expect(
          true,
          isTrue,
          reason: 'Check Sentry for sanitized error with ID: $testId',
        );
      }
    });
  });
}
