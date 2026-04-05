import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('TimeValidator', () {
    late tz.Location location;
    late tz.TZDateTime referenceTime;
    late tz.TZDateTime futureTime;
    late tz.TZDateTime pastTime;

    setUp(() {
      // Create test times in America/New_York timezone
      location = tz.getLocation('America/New_York');

      // Current time as reference
      final now = tz.TZDateTime.now(location);

      // Reference time for tests (use current timestamp)
      referenceTime = now;

      // Future time (2 hours in future from reference)
      futureTime = referenceTime.add(const Duration(hours: 2));

      // Past time (2 hours before reference)
      pastTime = referenceTime.subtract(const Duration(hours: 2));
    });

    group('isValid', () {
      test('returns correct validity for timestamps', () {
        // Current time is before futureTime, so data is valid
        expect(TimeValidator.isValid(referenceTime, futureTime), isTrue);

        // Current time is after pastTime, so data is invalid
        expect(TimeValidator.isValid(pastTime, referenceTime), isFalse);
      });
    });

    group('isFresh', () {
      test('identifies fresh data correctly', () {
        // Very recent data (created just now)
        expect(TimeValidator.isFresh(referenceTime), isTrue);

        // Old data (created 2 hours ago)
        expect(TimeValidator.isFresh(pastTime), isFalse);

        // Custom threshold allows even old data to be fresh
        expect(
          TimeValidator.isFresh(pastTime, freshnessThresholdHours: 3),
          isTrue,
        );
      });
    });

    group('isUsableAsFallback', () {
      test('identifies usable fallback data correctly', () {
        // Data that just expired
        final justExpired = referenceTime.subtract(const Duration(minutes: 10));
        final expiredValidUntil = referenceTime.subtract(
          const Duration(minutes: 5),
        );

        // Fallback window of 1 hour - should be usable
        expect(
          TimeValidator.isUsableAsFallback(
            justExpired,
            expiredValidUntil,
            maxFallbackAge: const Duration(hours: 1),
          ),
          isTrue,
        );

        // Very old data
        final veryOldData = referenceTime.subtract(const Duration(days: 2));
        final oldValidUntil = referenceTime.subtract(const Duration(days: 1));

        // Fallback window of 12 hours - should not be usable
        expect(
          TimeValidator.isUsableAsFallback(
            veryOldData,
            oldValidUntil,
            maxFallbackAge: const Duration(hours: 12),
          ),
          isFalse,
        );
      });
    });

    group('timeUntilExpiry and dataAge', () {
      test('calculates durations correctly', () {
        // Time until a future expiry
        final until = TimeValidator.timeUntilExpiry(futureTime);
        expect(until.inHours, greaterThanOrEqualTo(1));

        // Age of past data
        final age = TimeValidator.dataAge(pastTime);
        expect(age.inHours, greaterThanOrEqualTo(1));
      });
    });

    group('calculateExpiryTime', () {
      test('calculates expiry times correctly', () {
        // Default expiry (2 hours)
        final defaultExpiry = TimeValidator.calculateExpiryTime(referenceTime);
        expect(defaultExpiry.difference(referenceTime).inHours, 2);

        // Custom expiry (5 hours)
        final customExpiry = TimeValidator.calculateExpiryTime(
          referenceTime,
          expiryThresholdHours: 5,
        );
        expect(customExpiry.difference(referenceTime).inHours, 5);
      });
    });

    group('containsDstTransition', () {
      test('identifies DST transitions correctly', () {
        // March 12, 2023 was DST transition in US
        // Create time before DST transition
        final beforeDst = tz.TZDateTime(location, 2023, 3, 11, 12, 0, 0);

        // Create time after DST transition
        final afterDst = tz.TZDateTime(location, 2023, 3, 12, 12, 0, 0);

        expect(
          TimeValidator.containsDstTransition(beforeDst, afterDst),
          isTrue,
        );

        // Create two times within same DST period (both in January)
        final time1 = tz.TZDateTime(location, 2023, 1, 1, 12, 0, 0);

        final time2 = tz.TZDateTime(location, 2023, 1, 8, 12, 0, 0);

        expect(TimeValidator.containsDstTransition(time1, time2), isFalse);
      });
    });
  });
}
