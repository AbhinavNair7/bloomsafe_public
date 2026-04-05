import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/aqi_parser.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';

void main() {
  final parser = AQIParser();

  // Initialize timezone data
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('Timezone-Aware DateTime Parsing', () {
    test(
      'Creates proper TZDateTime from DateObserved+HourObserved+LocalTimeZone',
      () {
        final apiItem = {
          'DateObserved': '2025-03-23',
          'HourObserved': 9,
          'LocalTimeZone': 'EST',
        };

        final result = parser.createObservationDateTime(apiItem);

        expect(result, isA<tz.TZDateTime>());
        expect(result.year, 2025);
        expect(result.month, 3);
        expect(result.day, 23);
        expect(result.hour, 9); // Direct hour assignment
        expect(result.location.name, 'America/New_York');
      },
    );

    test('Properly handles DST end transition', () {
      // November 2, 2025 is DST end in the US
      // 1:00 AM occurs twice this day
      final apiItem = {
        'DateObserved': '2025-11-02',
        'HourObserved': 1, // This hour occurs twice during DST fallback
        'LocalTimeZone': 'EST',
      };

      final result = parser.createObservationDateTime(apiItem);

      expect(result, isA<tz.TZDateTime>());
      expect(result.year, 2025);
      expect(result.month, 11);
      expect(result.day, 2); // Direct day assignment
      expect(result.hour, 1); // Direct hour assignment

      // Just check that we got a valid time, timezone name might vary
      // between EDT and EST during DST transitions
      expect(result.location.name, 'America/New_York');

      // Check that the timezone offset is correct for this date (after DST end)
      // The first 1am is still in EDT with -4 offset
      expect(result.timeZoneOffset.inHours, -4);
    });

    test('Properly handles day boundary when calculating expiry', () {
      final apiItem = {
        'DateObserved': '2025-03-23',
        'HourObserved': 23,
        'LocalTimeZone': 'EST',
      };

      final observationTime = parser.createObservationDateTime(apiItem);
      final validUntil = parser.calculateValidUntil(observationTime);

      // Expected validation time is 2 hours after observation time (day boundary crossing)
      expect(validUntil.year, 2025);
      expect(validUntil.month, 3);
      expect(validUntil.day, 24); // Crosses to next day
      expect(validUntil.hour, 1); // 23 + 2 = 25, which becomes 1 on next day
    });

    test('isDataFresh calculation with fixed test times', () {
      // Create a fixed reference time
      final nyZone = tz.getLocation('America/New_York');
      final referenceTime = tz.TZDateTime(
        nyZone,
        2025,
        3,
        26,
        10,
        0,
      ); // 10:00 AM

      // Create test data with observation 4 hours before reference time
      final fourHoursBefore = referenceTime.subtract(const Duration(hours: 4));

      final formattedDate =
          '${fourHoursBefore.year}-${fourHoursBefore.month.toString().padLeft(2, '0')}-${fourHoursBefore.day.toString().padLeft(2, '0')}';

      final testData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: formattedDate,
        hourObserved: fourHoursBefore.hour,
        localTimeZone: 'EST',
      );

      // Use referenceTime to check if the data is fresh
      final isDataFresh = !referenceTime.isAfter(testData.validUntil);

      // Data should be expired since validUntil is 2 hours after observation time
      // and the reference time is 4 hours after observation time
      expect(
        isDataFresh,
        false,
        reason: 'Data observed 4 hours ago should not be fresh',
      );
    });
  });
}
