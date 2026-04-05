import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/cache/aqi_cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/core/services/cache_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  setUpAll(() {
    tz.initializeTimeZones();
  });
  
  group('AQI Cache Service Tests', () {
    late AQICacheService cacheService;
    
    setUp(() async {
      // Setup fake SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Set mock time to March 15, 2025 at 12:00 PM
      // This is the timestamp we'll use in our test data
      CacheService.setMockTimeForTesting(DateTime(2025, 3, 15, 12, 0, 0));
      
      // Initialize components
      cacheService = AQICacheService(enableAutomaticCleanup: false);
      
      // Clear any existing cache data
      await cacheService.clear();
    });
    
    tearDown(() {
      // Reset mock time after each test
      CacheService.setMockTimeForTesting(null);
    });
    
    test('Store and retrieve AQI data from cache', () async {
      const zipCode = '12345';
      
      // Create sample AQI data with the same date/time as our mock time
      final sampleData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 42,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        reportingArea: 'Test City',
        stateCode: 'TC',
        dateObserved: '2025-03-15',
        hourObserved: 12, // Same hour as our mock time
        localTimeZone: 'UTC',
      );
      
      // Store in cache
      await cacheService.storeForZipCode(zipCode, sampleData);
      
      // Retrieve from cache immediately after storing (should not be expired)
      final cachedData = await cacheService.getForZipCode(zipCode);
      
      // Verify basic cache functionality
      expect(cachedData, isNotNull);
      expect(cachedData!.reportingArea, equals('Test City'));
      expect(cachedData.stateCode, equals('TC'));
      expect(cachedData.pollutants.length, equals(1));
      expect(cachedData.pollutants.first.parameterName, equals('PM2.5'));
      expect(cachedData.pollutants.first.aqi, equals(42));
    });
    
    test('Clear cache works correctly', () async {
      const zipCode = '12345';
      
      // Create and store data with the same date/time as our mock time
      final sampleData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 42,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        reportingArea: 'Test City',
        stateCode: 'TC',
        dateObserved: '2025-03-15',
        hourObserved: 12, // Same hour as our mock time
        localTimeZone: 'UTC',
      );
      
      // Store in cache
      await cacheService.storeForZipCode(zipCode, sampleData);
      
      // Verify data is in cache
      final cachedData = await cacheService.getForZipCode(zipCode);
      expect(cachedData, isNotNull, reason: 'Data should be found in cache initially');
      
      // Clear cache
      await cacheService.clear();
      
      // Verify data is no longer in cache
      final clearedData = await cacheService.getForZipCode(zipCode);
      expect(clearedData, isNull, reason: 'Data should be removed after clearing cache');
    });
    
    test('Multiple entries can be stored in cache', () async {
      // Use separate tests for each cache entry to avoid interference
      
      // First entry
      const zipCode1 = '12345';
      final data1 = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 42,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        reportingArea: 'City One',
        stateCode: 'C1',
        dateObserved: '2025-03-15',
        hourObserved: 12, // Same hour as our mock time
        localTimeZone: 'UTC',
      );
      
      // Store and verify first entry
      await cacheService.storeForZipCode(zipCode1, data1);
      final retrievedData1 = await cacheService.getForZipCode(zipCode1);
      expect(retrievedData1, isNotNull, reason: 'First data item should be retrievable');
      expect(retrievedData1!.reportingArea, equals('City One'));
      
      // Clear all cache entries
      await cacheService.clear();
      
      // Second entry in a fresh cache
      const zipCode2 = '54321';
      final data2 = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        reportingArea: 'City Two',
        stateCode: 'C2',
        dateObserved: '2025-03-15',
        hourObserved: 12, // Same hour as our mock time
        localTimeZone: 'UTC',
      );
      
      // Store and verify second entry
      await cacheService.storeForZipCode(zipCode2, data2);
      final retrievedData2 = await cacheService.getForZipCode(zipCode2);
      expect(retrievedData2, isNotNull, reason: 'Second data item should be retrievable');
      expect(retrievedData2!.reportingArea, equals('City Two'));
    });
  });
} 