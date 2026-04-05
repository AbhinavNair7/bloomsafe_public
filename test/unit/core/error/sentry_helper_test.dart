import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/error/sentry_helper.dart';
import '../../../helpers/test_setup.dart';

void main() {
  setUpAll(setupTestEnvironment);

  group('SentryHelper', () {
    test('SentryLevel enum matches expected values', () {
      // Simply test that the enum values exist and match expected names
      expect(SentryLevel.debug.toString(), contains('debug'));
      expect(SentryLevel.info.toString(), contains('info'));
      expect(SentryLevel.warning.toString(), contains('warning'));
      expect(SentryLevel.error.toString(), contains('error'));
      expect(SentryLevel.fatal.toString(), contains('fatal'));
    });

    test('captureMessage handles exceptions gracefully', () {
      // This test verifies that calling captureMessage doesn't throw exceptions
      // even if Sentry isn't properly initialized
      expect(
        () => SentryHelper.captureMessage('Test message'),
        returnsNormally,
      );
      expect(
        () => SentryHelper.captureMessage(
          'Test message',
          level: SentryLevel.error,
        ),
        returnsNormally,
      );
    });

    test('captureException handles exceptions gracefully', () {
      // This test verifies that calling captureException doesn't throw exceptions
      // even if Sentry isn't properly initialized
      expect(
        () => SentryHelper.captureException(
          Exception('Test exception'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('configureScope handles errors gracefully', () {
      // This test verifies that configureScope doesn't throw
      expectLater(
        () => SentryHelper.configureScope((scope) {
          // Do nothing with the scope
        }),
        returnsNormally,
      );
    });

    test('addTag handles errors gracefully', () async {
      // This test verifies that addTag doesn't throw
      await expectLater(
        () => SentryHelper.addTag('test_key', 'test_value'),
        returnsNormally,
      );
    });

    test('startTransaction and finishTransaction handle errors gracefully', () {
      // Test transaction methods
      final transaction = SentryHelper.startTransaction('test', 'test_op');

      // Expect no exceptions when transaction is null
      expectLater(() => SentryHelper.finishTransaction(null), returnsNormally);

      // Expect no exceptions when transaction is provided
      expectLater(
        () => SentryHelper.finishTransaction(transaction),
        returnsNormally,
      );
    });
  });
}
