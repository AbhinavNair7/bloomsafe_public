import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import '../../../../../helpers/timezone_helper.dart';

// Test implementation of AQIRepository for timezone tests
class TestAQIRepository implements AQIRepository {
  final Map<String, List<Map<String, dynamic>>> _mockData = {};

  // Setup mock data for different zipcodes
  void setupMockDataForZipcode(
    String zipcode,
    List<Map<String, dynamic>> data,
  ) {
    _mockData[zipcode] = data;
  }

  @override
  Future<AQIData> getAQIByZipcode(String zipcode) async {
    final data = _mockData[zipcode];
    if (data == null || data.isEmpty) {
      throw Exception('No test data setup for zipcode $zipcode');
    }

    // Create AQIData from the first item
    final item = data.first;
    final pollutants = <PollutantData>[];

    for (final pollutantData in data) {
      pollutants.add(
        PollutantData(
          parameterName: pollutantData['ParameterName'],
          aqi: pollutantData['AQI'],
          category: AQICategory(
            number: pollutantData['Category']['Number'],
            name: pollutantData['Category']['Name'],
          ),
        ),
      );
    }

    return AQIData(
      pollutants: pollutants,
      reportingArea: item['ReportingArea'],
      stateCode: item['StateCode'],
      dateObserved: item['DateObserved'],
      hourObserved: item['HourObserved'],
      localTimeZone: item['LocalTimeZone'],
      latitude: item['Latitude'],
      longitude: item['Longitude'],
    );
  }

  @override
  Future<bool> hasDataForZipCode(String zipCode) async {
    return _mockData.containsKey(zipCode);
  }

  @override
  Future<AQIData?> getCachedDataForZipCode(String zipCode) async {
    if (_mockData.containsKey(zipCode)) {
      return getAQIByZipcode(zipCode);
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    // No-op for tests
  }

  @override
  bool isFromCache() {
    // Simple implementation for testing - always return false
    return false;
  }

  @override
  Duration getCacheAge(String zipCode) {
    // Simple implementation for testing - always return 1 hour
    return const Duration(hours: 1);
  }
}

void main() {
  group('Repository Timezone Handling', () {
    late TestAQIRepository repository;

    setUpAll(() {
      initializeTimeZonesForTest();
    });

    setUp(() {
      repository = TestAQIRepository();
    });

    test('Repository handles data from different timezones correctly', () async {
      // Test data for Eastern timezone
      final easternTz = tz.getLocation('America/New_York');
      final now = tz.TZDateTime.now(easternTz);

      // Format date for API response
      final dateObserved =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Setup Eastern timezone test data
      repository.setupMockDataForZipcode('12345', [
        {
          'ReportingArea': 'Test Eastern',
          'StateCode': 'TE',
          'Latitude': 40.7128,
          'Longitude': -74.0060,
          'DateObserved': dateObserved,
          'HourObserved': now.hour,
          'LocalTimeZone': 'EST',
          'ParameterName': 'PM2.5',
          'AQI': 42,
          'Category': {'Number': 1, 'Name': 'Good'},
        },
      ]);

      // Fetch data for Eastern timezone
      final result = await repository.getAQIByZipcode('12345');

      // Verify the result has correct timezone data
      expect(result, isA<AQIData>());
      expect(result.reportingArea, equals('Test Eastern'));
      expect(result.localTimeZone, equals('EST'));

      // Setup Pacific timezone test data
      repository.setupMockDataForZipcode('94105', [
        {
          'ReportingArea': 'Test Pacific',
          'StateCode': 'TP',
          'Latitude': 37.7749,
          'Longitude': -122.4194,
          'DateObserved': dateObserved,
          'HourObserved': now.hour,
          'LocalTimeZone': 'PST',
          'ParameterName': 'PM2.5',
          'AQI': 42,
          'Category': {'Number': 1, 'Name': 'Good'},
        },
      ]);

      // Fetch data for Pacific timezone
      final pacificResult = await repository.getAQIByZipcode('94105');

      // Verify the result has correct pacific timezone data
      expect(pacificResult, isA<AQIData>());
      expect(pacificResult.reportingArea, equals('Test Pacific'));
      expect(pacificResult.localTimeZone, equals('PST'));
    });
  });
}
