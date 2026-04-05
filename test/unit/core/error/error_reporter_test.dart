import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/error/error_reporter.dart';

// This test file covers the ErrorReporter class functionality
void main() {
  group('ErrorReporter', () {
    test('report handles errors gracefully', () async {
      // This test verifies that the method doesn't throw
      await expectLater(
        () => ErrorReporter.report(
          Exception('Test exception'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('reportMessage handles messages gracefully', () async {
      // This test verifies that the method doesn't throw
      await expectLater(
        () => ErrorReporter.reportMessage('Test message'),
        returnsNormally,
      );
    });

    // Test PII handling with complete inputs
    test('report sanitizes PII data without crashing', () async {
      await expectLater(
        () => ErrorReporter.report(
          Exception('User email: user@example.com, phone: (123) 456-7890'),
          StackTrace.current,
          context: 'User ZIP: 12345 and IP: 192.168.1.1',
          extras: {
            'email': 'user@example.com',
            'phone': '(123) 456-7890',
            'nested': {'ssn': '123-45-6789'},
            'list': ['192.168.1.1', 'user@example.com'],
          },
        ),
        returnsNormally,
      );
    });

    test('reportMessage sanitizes PII data without crashing', () async {
      await expectLater(
        () => ErrorReporter.reportMessage(
          'User email: user@example.com, phone: (123) 456-7890, ZIP: 12345, IP: 192.168.1.1',
          extras: {
            'email': 'user@example.com',
            'phone': '(123) 456-7890',
            'nested': {'ssn': '123-45-6789'},
          },
        ),
        returnsNormally,
      );
    });
  });
}
