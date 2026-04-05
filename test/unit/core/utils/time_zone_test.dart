import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart'
    as tzm;

void main() {
  // Initialize timezone data
  setUpAll(() {
    // Initialize timezones
    tz_data.initializeTimeZones();
  });

  group('TimeZoneMapper', () {
    group('getIanaTimeZone', () {
      test('maps EST to America/New_York', () {
        expect(tzm.getIanaTimeZone('EST'), 'America/New_York');
      });

      test('maps CST to America/Chicago', () {
        expect(tzm.getIanaTimeZone('CST'), 'America/Chicago');
      });

      test('maps MST to America/Denver', () {
        expect(tzm.getIanaTimeZone('MST'), 'America/Denver');
      });

      test('maps PST to America/Los_Angeles', () {
        expect(tzm.getIanaTimeZone('PST'), 'America/Los_Angeles');
      });

      test('handles lowercase input', () {
        expect(tzm.getIanaTimeZone('est'), 'America/New_York');
      });

      test('handles whitespace', () {
        expect(tzm.getIanaTimeZone(' EST '), 'America/New_York');
      });

      test('returns UTC for null input', () {
        expect(tzm.getIanaTimeZone(null), 'UTC');
      });

      test('returns UTC for empty input', () {
        expect(tzm.getIanaTimeZone(''), 'UTC');
      });

      test('returns UTC for unknown timezone', () {
        expect(tzm.getIanaTimeZone('UNKNOWN'), 'UTC');
      });
    });

    group('getTimeZoneLocation', () {
      test('returns correct location object for EST', () {
        final location = tzm.getTimeZoneLocation('EST');
        expect(location.name, 'America/New_York');
      });

      test('returns UTC location for unknown timezone', () {
        final location = tzm.getTimeZoneLocation('UNKNOWN');
        expect(location.name, 'UTC');
      });
    });

    group('parseDateString', () {
      test('parses ISO format date string', () {
        final result = tzm.parseDateString('2025-03-23');
        expect(result, isNotNull);
        expect(result?.year, 2025);
        expect(result?.month, 3);
        expect(result?.day, 23);
        expect(result?.hour, 0); // Default hour
      });

      test('parses ISO format with custom hour', () {
        final result = tzm.parseDateString('2025-03-23', hour: 14);
        expect(result, isNotNull);
        expect(result?.year, 2025);
        expect(result?.month, 3);
        expect(result?.day, 23);
        expect(result?.hour, 14);
      });

      test('parses US format date string', () {
        final result = tzm.parseDateString('03/23/2025');
        expect(result, isNotNull);
        expect(result?.year, 2025);
        expect(result?.month, 3);
        expect(result?.day, 23);
      });

      test('parses ISO format with T separator', () {
        final result = tzm.parseDateString('2025-03-23T14:30:00Z');
        expect(result, isNotNull);
        expect(result?.year, 2025);
        expect(result?.month, 3);
        expect(result?.day, 23);
        expect(result?.hour, 14);
        expect(result?.minute, 30);
      });

      test('returns null for invalid date', () {
        final result = tzm.parseDateString('invalid-date');
        expect(result, isNull);
      });
    });

    group('createObservationDateTime', () {
      test('parses YYYY-MM-DD format', () {
        final dateTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 5,
          localTimeZone: 'EST',
        );

        expect(dateTime.year, 2025);
        expect(dateTime.month, 3);
        expect(dateTime.day, 23);
        expect(dateTime.hour, 5); // Direct hour assignment in target timezone
        expect(dateTime.location.name, 'America/New_York');
      });

      test('parses MM/DD/YYYY format', () {
        final dateTime = tzm.createObservationDateTime(
          dateObserved: '03/23/2025',
          hourObserved: 0,
          localTimeZone: 'PST',
        );

        expect(dateTime.year, 2025);
        expect(dateTime.month, 3);
        expect(dateTime.day, 23); // Correct direct day assignment
        expect(dateTime.hour, 0); // Correct direct hour assignment
        expect(dateTime.location.name, 'America/Los_Angeles');
      });

      test('parses ISO format with T separator', () {
        final dateTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23T14:30:00Z',
          hourObserved: 10,
          localTimeZone: 'EST',
        );

        expect(dateTime.year, 2025);
        expect(dateTime.month, 3);
        expect(dateTime.day, 23);
        expect(
          dateTime.hour,
          10,
        ); // Uses hourObserved, not the one from the string
        expect(dateTime.location.name, 'America/New_York');
      });

      test('handles DST transition dates correctly', () {
        // March 12, 2023 was the start of DST in the US
        final beforeDst = tzm.createObservationDateTime(
          dateObserved: '2023-03-11',
          hourObserved: 12,
          localTimeZone: 'EST',
        );

        final afterDst = tzm.createObservationDateTime(
          dateObserved: '2023-03-12',
          hourObserved: 12,
          localTimeZone: 'EST',
        );

        // The UTC offset should be different due to DST
        expect(beforeDst.timeZoneOffset.inHours, -5);
        expect(afterDst.timeZoneOffset.inHours, -4);
      });

      test('handles invalid date format gracefully', () {
        final dateTime = tzm.createObservationDateTime(
          dateObserved: 'invalid-date',
          hourObserved: 13,
          localTimeZone: 'EST',
        );

        // Should return current time in the requested timezone
        expect(dateTime.location.name, 'America/New_York');
      });
    });

    group('addDuration and addHours', () {
      test('adds duration correctly', () {
        final baseTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 13,
          localTimeZone: 'EST',
        );

        final newTime = tzm.addDuration(
          baseTime,
          const Duration(hours: 3, minutes: 30),
        );

        expect(newTime.year, baseTime.year);
        expect(newTime.month, baseTime.month);
        expect(newTime.day, baseTime.day);
        expect(newTime.hour, baseTime.hour + 3);
        expect(newTime.minute, 30);
        expect(newTime.location, baseTime.location);
      });

      test('adds hours correctly', () {
        final baseTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 13,
          localTimeZone: 'EST',
        );

        final newTime = tzm.addHours(baseTime, 5);

        expect(newTime.year, baseTime.year);
        expect(newTime.month, baseTime.month);
        expect(newTime.day, baseTime.day);
        expect(newTime.hour, baseTime.hour + 5);
        expect(newTime.location, baseTime.location);
      });

      test('handles day boundary correctly when adding hours', () {
        final baseTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 23,
          localTimeZone: 'EST',
        );

        final newTime = tzm.addHours(baseTime, 3);

        expect(newTime.day, 24); // Next day
        expect(newTime.hour, 2); // 23 + 3 = 26, which is 2 AM on next day
      });
    });

    group('calculateExpiryTime', () {
      test('adds 2 hours to observation time by default', () {
        final observationTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 13,
          localTimeZone: 'EST',
        );

        final expiryTime = tzm.calculateExpiryTime(observationTime);

        expect(expiryTime.year, observationTime.year);
        expect(expiryTime.month, observationTime.month);
        expect(expiryTime.day, observationTime.day);
        expect(expiryTime.hour, observationTime.hour + 2);
        expect(expiryTime.location, observationTime.location);
      });

      test('respects custom expiry hours', () {
        final observationTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 13,
          localTimeZone: 'EST',
        );

        final expiryTime = tzm.calculateExpiryTime(
          observationTime,
          expiryHours: 5,
        );

        expect(expiryTime.hour, observationTime.hour + 5);
      });

      test('handles day boundary correctly', () {
        final observationTime = tzm.createObservationDateTime(
          dateObserved: '2025-03-23',
          hourObserved: 23,
          localTimeZone: 'EST',
        );

        final expiryTime = tzm.calculateExpiryTime(observationTime);

        // Expected expiry time (should be 2 hours later, crossing to next day)
        expect(expiryTime.year, 2025);
        expect(expiryTime.month, 3);
        expect(expiryTime.day, 24); // Should advance to next day
        expect(expiryTime.hour, 1); // 23 + 2 = 25, which becomes 1 on next day
        expect(expiryTime.location, observationTime.location);
      });
    });

    group('normalizeToTimeZone', () {
      test('converts standard DateTime to timezone-aware DateTime', () {
        final standardDateTime = DateTime(2025, 3, 23, 12, 0);
        final tzDateTime = tzm.normalizeToTimeZone(standardDateTime, 'PST');

        expect(tzDateTime.year, 2025);
        expect(tzDateTime.month, 3);
        expect(tzDateTime.day, 23);
        // Don't assert the hour as it may vary based on the local timezone
        expect(tzDateTime.location.name, 'America/Los_Angeles');
      });
    });

    group('DST transition edge cases', () {
      test('handles spring and fall DST transitions correctly', () {
        // March 12, 2023 was DST transition in US
        final location = tz.getLocation('America/New_York');

        // Create time before DST transition
        final beforeDst = tz.TZDateTime(location, 2023, 3, 11, 12, 0, 0);

        // Create time after DST transition
        final afterDst = tz.TZDateTime(location, 2023, 3, 12, 12, 0, 0);

        // Test timezone offsets
        expect(beforeDst.timeZoneOffset.inHours, -5);
        expect(afterDst.timeZoneOffset.inHours, -4);

        // November 5, 2023 was fall back DST transition in US
        final beforeFallback = tz.TZDateTime(location, 2023, 11, 4, 12, 0, 0);

        final afterFallback = tz.TZDateTime(location, 2023, 11, 6, 12, 0, 0);

        // Check offset change
        expect(beforeFallback.timeZoneOffset.inHours, -4);
        expect(afterFallback.timeZoneOffset.inHours, -5);
      });
    });
  });
}
