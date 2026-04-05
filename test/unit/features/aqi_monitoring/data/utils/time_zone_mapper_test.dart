import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart';

void main() {
  // Initialize the timezone database once before all tests
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('TimeZoneMapper', () {
    test('getIanaTimeZone returns mapped timezone for valid abbreviation', () {
      // Arrange
      const abbreviation = 'PST';

      // Act
      final result = getIanaTimeZone(abbreviation);

      // Assert
      expect(result, equals('America/Los_Angeles'));
    });

    test('getIanaTimeZone returns UTC for unknown abbreviation', () {
      // Arrange
      const abbreviation = 'UNKNOWN';

      // Act
      final result = getIanaTimeZone(abbreviation);

      // Assert
      expect(result, equals('UTC'));
    });

    test('getIanaTimeZone handles null input', () {
      // Arrange
      const String? abbreviation = null;

      // Act
      final result = getIanaTimeZone(abbreviation);

      // Assert
      expect(result, equals('UTC'));
    });

    test('getTimeZoneLocation returns correct location for abbreviation', () {
      // Arrange
      const abbreviation = 'EST';

      // Act
      final result = getTimeZoneLocation(abbreviation);

      // Assert
      expect(result, isA<tz.Location>());
      expect(result.name, equals('America/New_York'));
    });

    test('parseDateString handles ISO format with T separator', () {
      // Arrange
      const dateString = '2023-01-15T10:30:00';

      // Act
      final result = parseDateString(dateString);

      // Assert
      expect(result, isNotNull);
      expect(result?.year, equals(2023));
      expect(result?.month, equals(1));
      expect(result?.day, equals(15));
      expect(result?.hour, equals(10));
      expect(result?.minute, equals(30));
    });

    test('parseDateString handles ISO date format without time', () {
      // Arrange
      const dateString = '2023-01-15';
      const hour = 5;

      // Act
      final result = parseDateString(dateString, hour: hour);

      // Assert
      expect(result, isNotNull);
      expect(result?.year, equals(2023));
      expect(result?.month, equals(1));
      expect(result?.day, equals(15));
      expect(result?.hour, equals(hour));
    });

    test('parseDateString handles US date format (MM/DD/YYYY)', () {
      // Arrange
      const dateString = '01/15/2023';
      const hour = 12;

      // Act
      final result = parseDateString(dateString, hour: hour);

      // Assert
      expect(result, isNotNull);
      expect(result?.year, equals(2023));
      expect(result?.month, equals(1));
      expect(result?.day, equals(15));
      expect(result?.hour, equals(hour));
    });

    test('createTimeZoneAwareDateTime creates correct TZDateTime', () {
      // Arrange
      const dateObserved = '2023-01-15';
      const hourObserved = 10;
      const localTimeZone = 'EST';

      // Act
      final result = createTimeZoneAwareDateTime(
        dateObserved: dateObserved,
        hourObserved: hourObserved,
        localTimeZone: localTimeZone,
      );

      // Assert
      expect(result, isA<tz.TZDateTime>());
      expect(result.year, equals(2023));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
      expect(result.hour, equals(hourObserved));
      expect(result.location.name, equals('America/New_York'));
    });

    test(
      'createObservationDateTime returns correctly formatted TZDateTime',
      () {
        // Arrange
        const dateObserved = '2023-01-15';
        const hourObserved = 10;
        const localTimeZone = 'PST';

        // Act
        final result = createObservationDateTime(
          dateObserved: dateObserved,
          hourObserved: hourObserved,
          localTimeZone: localTimeZone,
        );

        // Assert
        expect(result, isA<tz.TZDateTime>());
        expect(result.year, equals(2023));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
        expect(result.hour, equals(hourObserved));
        expect(result.location.name, equals('America/Los_Angeles'));
      },
    );

    test('addHours correctly adds hours to a TZDateTime', () {
      // Arrange
      final location = tz.getLocation('America/New_York');
      final dateTime = tz.TZDateTime(location, 2023, 1, 15, 10);
      const hoursToAdd = 5;

      // Act
      final result = addHours(dateTime, hoursToAdd);

      // Assert
      expect(result.hour, equals(15));
      expect(result.day, equals(15)); // Should still be same day
    });

    test('calculateExpiryTime adds the specified expiry hours', () {
      // Arrange
      final location = tz.getLocation('America/New_York');
      final dateTime = tz.TZDateTime(location, 2023, 1, 15, 10);
      const expiryHours = 3;

      // Act
      final result = calculateExpiryTime(dateTime, expiryHours: expiryHours);

      // Assert
      expect(result, isA<tz.TZDateTime>());
      expect(result.year, equals(2023));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
      expect(result.hour, equals(13)); // 10 + 3
    });
  });
}
