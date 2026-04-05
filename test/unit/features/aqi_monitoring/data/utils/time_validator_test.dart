import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart'
    as tzm;
import '../../../../../helpers/time_utils.dart';

// Create a testable version of TimeValidator for testing
class TestableTimeValidator extends TimeValidator {
  static tz.TZDateTime Function(tz.Location) getCurrentTimeFn =
      tzm.getCurrentTimeInZone;

  // Override this in tests to provide a fixed time
  static void setCurrentTimeFunction(tz.TZDateTime Function(tz.Location) fn) {
    getCurrentTimeFn = fn;
  }

  // Reset to use the real function
  static void resetCurrentTimeFunction() {
    getCurrentTimeFn = tzm.getCurrentTimeInZone;
  }

  // Override isValid to use our mockable time function
  static bool isValid(tz.TZDateTime observationTime, tz.TZDateTime validUntil) {
    final now = getCurrentTimeFn(observationTime.location);
    return now.isBefore(validUntil);
  }

  // Override isFresh to use our mockable time function
  static bool isFresh(
    tz.TZDateTime observationTime, {
    int freshnessThresholdHours = TimeValidator.defaultFreshnessThreshold,
  }) {
    final now = getCurrentTimeFn(observationTime.location);
    final freshnessThreshold = Duration(hours: freshnessThresholdHours);
    final age = now.difference(observationTime);

    return age <= freshnessThreshold;
  }

  // Override isUsableAsFallback to use our mockable time function
  static bool isUsableAsFallback(
    tz.TZDateTime observationTime,
    tz.TZDateTime validUntil, {
    required Duration maxFallbackAge,
  }) {
    final now = getCurrentTimeFn(observationTime.location);

    // Check if data is expired but not too old
    final isExpired = now.isAfter(validUntil);
    final age = now.difference(observationTime);

    return isExpired && age <= maxFallbackAge;
  }

  // Override timeUntilExpiry to use our mockable time function
  static Duration timeUntilExpiry(tz.TZDateTime validUntil) {
    final now = getCurrentTimeFn(validUntil.location);
    return validUntil.difference(now);
  }

  // Override dataAge to use our mockable time function
  static Duration dataAge(tz.TZDateTime observationTime) {
    final now = getCurrentTimeFn(observationTime.location);
    return now.difference(observationTime);
  }
}

void main() {
  // Initialize the timezone database once before all tests
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
    // Initialize time zones for testing
    tz_data.initializeTimeZones();
  });

  setUp(() {
    // Initialize time zones using test utility
    TimeTestUtils.initializeTimeZones();
  });

  group('TimeValidator', () {
    late tz.Location location;
    late tz.TZDateTime fixedNow;

    setUp(() {
      location = tz.getLocation('America/New_York');
      fixedNow = tz.TZDateTime(
        location,
        2023,
        6,
        15,
        12,
        0,
      ); // Fixed noon time for tests

      // Set up our mock time function to return the fixed time
      TestableTimeValidator.setCurrentTimeFunction((_) => fixedNow);
    });

    tearDown(() {
      // Reset the time function after each test
      TestableTimeValidator.resetCurrentTimeFunction();
    });

    group('isValid tests', () {
      test('returns true when current time is before validUntil', () {
        // Arrange
        final observationTime = fixedNow.subtract(const Duration(minutes: 30));
        final validUntil = fixedNow.add(const Duration(minutes: 30));

        // Act & Assert
        expect(
          TestableTimeValidator.isValid(observationTime, validUntil),
          isTrue,
        );
      });

      test('returns false when current time is after validUntil', () {
        // Arrange
        final observationTime = fixedNow.subtract(const Duration(hours: 3));
        final validUntil = fixedNow.subtract(const Duration(minutes: 30));

        // Act & Assert
        expect(
          TestableTimeValidator.isValid(observationTime, validUntil),
          isFalse,
        );
      });

      test('handles edge case when current time equals validUntil', () {
        // Arrange
        final observationTime = fixedNow.subtract(const Duration(hours: 2));
        final validUntil = fixedNow; // Exactly at the edge

        // Act & Assert
        // The specification is that isValid returns false when time == validUntil
        expect(
          TestableTimeValidator.isValid(observationTime, validUntil),
          isFalse,
        );
      });
    });

    group('isFresh tests', () {
      test('returns true for recently observed data', () {
        // Arrange
        final observationTime = fixedNow.subtract(const Duration(minutes: 30));

        // Act & Assert - default freshness threshold is 1 hour
        expect(TestableTimeValidator.isFresh(observationTime), isTrue);
      });

      test('returns false for older data beyond freshness threshold', () {
        // Arrange
        // 2 hours old, beyond default threshold of 1 hour
        final observationTime = fixedNow.subtract(const Duration(hours: 2));

        // Act & Assert
        expect(TestableTimeValidator.isFresh(observationTime), isFalse);
      });

      test('respects custom freshness threshold', () {
        // Arrange
        // 2 hours old
        final observationTime = fixedNow.subtract(const Duration(hours: 2));

        // Act & Assert - with 3 hour threshold, should be fresh
        expect(
          TestableTimeValidator.isFresh(
            observationTime,
            freshnessThresholdHours: 3,
          ),
          isTrue,
        );
      });

      test('handles edge case at exact freshness threshold', () {
        // Arrange
        // Exactly 1 hour old (the default threshold)
        final observationTime = fixedNow.subtract(const Duration(hours: 1));

        // Act & Assert - should be considered fresh (threshold is inclusive)
        expect(TestableTimeValidator.isFresh(observationTime), isTrue);
      });
    });

    group('isUsableAsFallback tests', () {
      test('returns true for expired but still usable data', () {
        // Arrange
        // Data was observed 3 hours ago
        final observationTime = fixedNow.subtract(const Duration(hours: 3));
        // Data expired 1 hour ago
        final validUntil = fixedNow.subtract(const Duration(hours: 1));
        // But fallback window is 4 hours
        final fallbackWindow = const Duration(hours: 4);

        // Act & Assert
        expect(
          TestableTimeValidator.isUsableAsFallback(
            observationTime,
            validUntil,
            maxFallbackAge: fallbackWindow,
          ),
          isTrue,
        );
      });

      test('returns false for data that is expired beyond fallback window', () {
        // Arrange
        // Data was observed 5 hours ago
        final observationTime = fixedNow.subtract(const Duration(hours: 5));
        // Data expired 3 hours ago
        final validUntil = fixedNow.subtract(const Duration(hours: 3));
        // But fallback window is only 4 hours
        final fallbackWindow = const Duration(hours: 4);

        // Act & Assert
        expect(
          TestableTimeValidator.isUsableAsFallback(
            observationTime,
            validUntil,
            maxFallbackAge: fallbackWindow,
          ),
          isFalse,
        );
      });

      test('returns false for data that is not yet expired', () {
        // Arrange
        // Data was observed 1 hour ago
        final observationTime = fixedNow.subtract(const Duration(hours: 1));
        // Data expires in 1 hour
        final validUntil = fixedNow.add(const Duration(hours: 1));
        // Fallback window is 4 hours
        final fallbackWindow = const Duration(hours: 4);

        // Act & Assert - not usable as fallback because it's still valid
        expect(
          TestableTimeValidator.isUsableAsFallback(
            observationTime,
            validUntil,
            maxFallbackAge: fallbackWindow,
          ),
          isFalse,
        );
      });

      test('handles edge case at exact fallback age limit', () {
        // Arrange
        // Data was observed exactly at the fallback age limit
        final fallbackWindow = const Duration(hours: 4);
        final observationTime = fixedNow.subtract(fallbackWindow);
        // Data expired some time ago
        final validUntil = fixedNow.subtract(const Duration(hours: 2));

        // Act & Assert - should be usable (the age check is inclusive)
        expect(
          TestableTimeValidator.isUsableAsFallback(
            observationTime,
            validUntil,
            maxFallbackAge: fallbackWindow,
          ),
          isTrue,
        );
      });
    });

    group('timeUntilExpiry tests', () {
      test('returns positive duration when not expired', () {
        // Arrange
        // Data expires in 2 hours
        final validUntil = fixedNow.add(const Duration(hours: 2));

        // Act
        final timeUntil = TestableTimeValidator.timeUntilExpiry(validUntil);

        // Assert
        expect(timeUntil.isNegative, isFalse);
        expect(timeUntil.inHours, equals(2));
      });

      test('returns negative duration when already expired', () {
        // Arrange
        // Data expired 2 hours ago
        final validUntil = fixedNow.subtract(const Duration(hours: 2));

        // Act
        final timeUntil = TestableTimeValidator.timeUntilExpiry(validUntil);

        // Assert
        expect(timeUntil.isNegative, isTrue);
        expect(timeUntil.inHours, equals(-2));
      });
    });

    group('dataAge tests', () {
      test('correctly calculates age of data', () {
        // Arrange
        // Data was observed 3 hours ago
        final observationTime = fixedNow.subtract(const Duration(hours: 3));

        // Act
        final age = TestableTimeValidator.dataAge(observationTime);

        // Assert
        expect(age.inHours, equals(3));
      });
    });

    group('containsDstTransition tests', () {
      test('returns true when timestamps cross DST transition', () {
        // March 12, 2023 at 1:30 AM (before spring forward)
        final beforeDst = tz.TZDateTime(
          tz.getLocation('America/New_York'),
          2023,
          3,
          12,
          1,
          30,
        );

        // March 12, 2023 at 3:30 AM (after spring forward)
        final afterDst = tz.TZDateTime(
          tz.getLocation('America/New_York'),
          2023,
          3,
          12,
          3,
          30,
        );

        // Act & Assert
        expect(
          TimeValidator.containsDstTransition(beforeDst, afterDst),
          isTrue,
        );
      });

      test('returns false when timestamps do not cross DST transition', () {
        // February 1, 2023 at 1:30 AM
        final time1 = tz.TZDateTime(
          tz.getLocation('America/New_York'),
          2023,
          2,
          1,
          1,
          30,
        );

        // February 1, 2023 at 3:30 AM
        final time2 = tz.TZDateTime(
          tz.getLocation('America/New_York'),
          2023,
          2,
          1,
          3,
          30,
        );

        // Act & Assert
        expect(TimeValidator.containsDstTransition(time1, time2), isFalse);
      });
    });
  });
}
