import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/repositories/aqi_repository_impl.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/mock_aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/cache/aqi_cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/transformers/aqi_data_transformer.dart';
import 'package:bloomsafe/core/services/cache_service.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes for normal AQI client
class TestAQIClient extends Mock implements AQIClient {
  @override
  Future<List<dynamic>> getAirQualityByZipCode(
      String zipCode, String format, int distance, [String? apiKey,]) async {
    // Return a simple mock response
    return [
      {
        'DateObserved': '2025-03-15',
        'HourObserved': 12,
        'LocalTimeZone': 'UTC',
        'ReportingArea': 'Test City',
        'StateCode': 'TC',
        'Latitude': 40.0,
        'Longitude': -75.0,
        'ParameterName': 'PM2.5',
        'AQI': 42,
        'Category': {'Number': 1, 'Name': 'Good'},
      }
    ];
  }
  
  @override
  Future<bool> shouldUseCacheOnly() async {
    return false;
  }
}

// Separate mock class for the mock client
class TestMockAQIClient extends Mock implements MockAQIClient {
  @override
  Future<List<Map<String, dynamic>>> getAirQualityByZipCode(
      String zipCode, String format, int distance,) async {
    // Return a simple mock response
    return [
      {
        'DateObserved': '2025-03-15',
        'HourObserved': 12,
        'LocalTimeZone': 'UTC',
        'ReportingArea': 'Mock City',
        'StateCode': 'MC',
        'Latitude': 40.0,
        'Longitude': -75.0,
        'ParameterName': 'PM2.5',
        'AQI': 35,
        'Category': {'Number': 1, 'Name': 'Good'},
      }
    ];
  }
}

class TestAppConfig extends Mock implements AppConfig {
  @override
  bool get useMockApi => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  setUpAll(() {
    tz.initializeTimeZones();
  });
  
  group('AQI Lookup Flow Integration Test', () {
    late AQIRepositoryImpl repository;
    late TestAQIClient testClient;
    late TestMockAQIClient testMockClient;
    late AQICacheService cacheService;
    late AQIDataTransformer transformer;
    late TestAppConfig testConfig;
    
    setUp(() async {
      // Setup fake SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Set mock time to ensure cache entries don't expire during test
      CacheService.setMockTimeForTesting(DateTime(2025, 3, 15, 12, 0, 0));
      
      // Create all the components
      testClient = TestAQIClient();
      testMockClient = TestMockAQIClient();
      cacheService = AQICacheService(enableAutomaticCleanup: false);
      transformer = AQIDataTransformer();
      testConfig = TestAppConfig();
      
      // Create repository with required parameters
      repository = AQIRepositoryImpl(
        testClient,
        mockAqiClient: testMockClient,
        cacheService: cacheService,
        transformer: transformer,
        appConfig: testConfig,
      );
      
      // Clear any existing cache data
      await cacheService.clear();
    });
    
    tearDown(() {
      // Reset mock time after each test
      CacheService.setMockTimeForTesting(null);
    });
    
    test('End-to-end AQI lookup flow test', () async {
      const zipCode = '12345';
      
      // Perform lookup
      final result = await repository.getAQIByZipcode(zipCode);
      
      // Verify result
      expect(result, isNotNull);
      expect(result.reportingArea, equals('Test City'));
      expect(result.stateCode, equals('TC'));
      expect(result.pollutants.length, equals(1));
      expect(result.pollutants.first.parameterName, equals('PM2.5'));
      expect(result.pollutants.first.aqi, equals(42));
      
      // Verify this was from the network, not cache
      expect(repository.isFromCache(), isFalse);
      
      // Perform a second lookup which should use cache
      final secondResult = await repository.getAQIByZipcode(zipCode);
      
      // Verify second result is also valid
      expect(secondResult, isNotNull);
      expect(secondResult.reportingArea, equals('Test City'));
      
      // And this one should have come from the cache
      expect(repository.isFromCache(), isTrue);
    });
  });
} 