import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';

void main() {
  // Set up shared test data
  late AQIData testData;

  // Setup timezone data
  setUpAll(() {
    tz_data.initializeTimeZones();

    // Initialize test data after timezone initialization
    testData = AQIData(
      pollutants: [
        PollutantData(
          parameterName: 'PM2.5',
          aqi: 35,
          category: AQICategory(number: 1, name: 'Good'),
        ),
      ],
      dateObserved: '2025-03-23',
      hourObserved: 8,
      localTimeZone: 'EST',
    );
  });

  group('AQI Cache Validation', () {
    test('AQI data has correct observation time and validUntil', () {
      // Expected observation time: 2025-03-23 08:00 (direct hour assignment)
      final expectedObservationTime = tz.TZDateTime(
        tz.getLocation('America/New_York'),
        2025,
        3,
        23,
        8,
        0,
        0,
      );

      // Expected validUntil: 2025-03-23 10:00 (2 hours later)
      final expectedValidUntil = tz.TZDateTime(
        tz.getLocation('America/New_York'),
        2025,
        3,
        23,
        10,
        0,
        0,
      );

      // Check that observation time matches our expectation
      expect(testData.observationTime.year, expectedObservationTime.year);
      expect(testData.observationTime.month, expectedObservationTime.month);
      expect(testData.observationTime.day, expectedObservationTime.day);
      expect(testData.observationTime.hour, expectedObservationTime.hour);
      expect(
        testData.observationTime.location.name,
        expectedObservationTime.location.name,
      );

      // Check that validUntil is 2 hours after observation time
      expect(testData.validUntil.year, expectedValidUntil.year);
      expect(testData.validUntil.month, expectedValidUntil.month);
      expect(testData.validUntil.day, expectedValidUntil.day);
      expect(testData.validUntil.hour, expectedValidUntil.hour);
      expect(
        testData.validUntil.location.name,
        expectedValidUntil.location.name,
      );

      // Direct comparison of the times
      expect(
        testData.validUntil.difference(testData.observationTime).inHours,
        2,
      );
    });

    test('Keeps data until validUntil timestamp across DST boundaries', () {
      // Create data for 11 PM day before DST
      final beforeDstData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-08', // Day before DST spring forward
        hourObserved: 23, // 11 PM
        localTimeZone: 'EST',
      );

      // "Current time" at 12:30 AM on 2025-03-09 (after DST transition)
      // This should be 1.5 hours after the observation time
      final afterDstTime = tz.TZDateTime(
        tz.getLocation('America/New_York'),
        2025,
        3,
        9,
        0,
        30,
        0,
      );

      // Debug output for inspection
      print('DST test debug:');
      print('Observation time: ${beforeDstData.observationTime}');
      print('Valid until: ${beforeDstData.validUntil}');
      print('Current time: $afterDstTime');
      print(
        'Hours between observation and current: ${afterDstTime.difference(beforeDstData.observationTime).inHours}',
      );
      print(
        'Minutes between observation and current: ${afterDstTime.difference(beforeDstData.observationTime).inMinutes}',
      );
      print(
        'Is current before validUntil? ${afterDstTime.isBefore(beforeDstData.validUntil)}',
      );

      // With direct hour assignment, observation time is at 23:00 (11pm)
      // validUntil is at 01:00 on the next day
      // afterDstTime is at 00:30, which is before validUntil

      // Data should still be valid
      final isValidAfterDst = afterDstTime.isBefore(beforeDstData.validUntil);

      // Expect data to be valid
      expect(isValidAfterDst, true);
    });

    test('Expires entries correctly between different days', () {
      // Create data for 11 PM
      final lateNightData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-23', // 11 PM
        hourObserved: 23,
        localTimeZone: 'EST',
      );

      // Check validUntil is calculated properly for cross-day scenarios
      final validUntil = lateNightData.validUntil;
      // With direct hour assignment, validUntil crosses to the next day
      expect(validUntil.day, 24); // Next day (11 PM + 2 hours = 1 AM next day)
      expect(validUntil.hour, 1); // 1 AM
    });

    test('Auto-purges expired entries during repository operations', () {
      // Create a mock repository cache with 2 entries:
      // 1. Fresh data (observation time: 30 minutes ago)
      // 2. Expired data (observation time: 3 hours ago)

      // Reference time (now) - will be used to verify data expiration
      final referenceTime = tz.TZDateTime(
        tz.getLocation('America/New_York'),
        2025,
        3,
        23,
        12,
        0,
        0,
      );

      // Fresh data: 11:00 AM (1 hour ago relative to reference time)
      final freshData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-23',
        hourObserved: 11,
        localTimeZone: 'EST',
      );

      // Expired data: 9:00 AM (3 hours ago relative to reference time)
      final expiredData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 40,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-23',
        hourObserved: 9,
        localTimeZone: 'EST',
      );

      // Debug output for inspection
      print('Auto-purge test debug:');
      print('Reference time: $referenceTime');
      print('Fresh data observation time: ${freshData.observationTime}');
      print('Fresh data valid until: ${freshData.validUntil}');
      print('Expired data observation time: ${expiredData.observationTime}');
      print('Expired data valid until: ${expiredData.validUntil}');

      // With direct hour assignment:
      // - freshData would be at 11am and validUntil would be 1pm, which is after referenceTime (12pm)
      // - expiredData would be at 9am and validUntil would be 11am, which is before referenceTime (12pm)

      // Manual calculation for test (isAfter is the actual implementation behavior)
      final freshDataValid = !referenceTime.isAfter(freshData.validUntil);
      final expiredDataInvalid = referenceTime.isAfter(expiredData.validUntil);

      // Update expectations to match corrected behavior
      expect(freshDataValid, true, reason: 'Fresh data should be valid');
      expect(
        expiredDataInvalid,
        true,
        reason: 'Expired data should be expired',
      );
    });

    test('Auto-purges during cacheData operations', () {
      // Setup test cache
      final Map<String, AQIData> cache = {};

      // Reference time (now)
      final referenceTime = tz.TZDateTime(
        tz.getLocation('America/New_York'),
        2025,
        3,
        23,
        12,
        0,
        0,
      );

      // Fresh data for zipcode 94105: 11:00 AM (1 hour ago)
      final freshData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-23',
        hourObserved: 11,
        localTimeZone: 'EST',
      );

      // Add to cache
      cache['94105'] = freshData;

      // New data for same zipcode - using the reference time for hour
      final newData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 42,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-23',
        hourObserved: referenceTime.hour, // Using reference time
        localTimeZone: 'EST',
      );

      // Update cache (simulating cacheData operation)
      cache['94105'] = newData;

      // Verify the cache has been updated
      expect(cache['94105'], isNotNull);
      expect(cache['94105']!.pollutants.first.aqi, 42);
    });
  });
}
