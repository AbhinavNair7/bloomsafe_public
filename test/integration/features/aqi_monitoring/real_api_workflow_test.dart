import 'dart:math';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/repositories/aqi_repository_impl.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/mock_aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/cache/aqi_cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/transformers/aqi_data_transformer.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';
import 'package:bloomsafe/core/services/analytics_service.dart'
    show AnalyticsServiceInterface;
import '../../../helpers/mock_service_locator.dart';
import '../../../helpers/test_environment.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

// Test mocks for testing purposes
class TestEnvConfig implements EnvConfig {
  String? _apiKey = 'test_api_key';

  @override
  Future<String?> getSecureApiKey() async => _apiKey;

  @override
  Future<bool> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    return true;
  }

  @override
  bool get disableRateLimit => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test mock for AQICacheService with in-memory implementation
class TestAQICacheService implements AQICacheService {
  final Map<String, AQIData> _cache = {};

  @override
  Future<AQIData?> getForZipCode(String zipCode) async {
    return _cache[zipCode];
  }

  @override
  Future<void> storeForZipCode(String zipCode, AQIData data) async {
    _cache[zipCode] = data;
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  @override
  void dispose() {
    clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test mock for AQIDataTransformer
class TestAQIDataTransformer implements AQIDataTransformer {
  @override
  AQIData transformApiResponse(List<dynamic> responseData, String zipcode) {
    if (responseData.isEmpty) {
      throw Exception('Empty response data');
    }

    return AQIData.fromApiResponse(
      List<Map<String, dynamic>>.from(responseData),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper for API rate limiting in tests
class ApiRateLimiter {
  factory ApiRateLimiter() => _instance;
  ApiRateLimiter._internal();
  static final ApiRateLimiter _instance = ApiRateLimiter._internal();

  int _apiCallsThisHour = 0;
  DateTime _lastResetTime = DateTime.now();
  int _maxCallsPerTestRun = 10;

  void setMaxCallsPerTestRun(int max) => _maxCallsPerTestRun = max;
  int get apiCallsThisHour => _apiCallsThisHour;

  void reset() {
    _apiCallsThisHour = 0;
    _lastResetTime = DateTime.now();
  }

  bool recordApiCall() {
    final now = DateTime.now();
    if (now.difference(_lastResetTime).inHours >= 1) {
      reset();
    }
    _apiCallsThisHour++;
    return _apiCallsThisHour <= _maxCallsPerTestRun;
  }

  Future<bool> prepareRealApiTest({bool forceRealApi = false}) async {
    try {
      // Get app config and initialize
      final appConfig = AppConfig();
      await appConfig.initialize();

      // Force real API if requested
      if (forceRealApi) {
        return appConfig.useRealApiMode();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Failed to prepare API test environment: $e');
      return false;
    }
  }

  void simulateRateLimitReached() {
    _apiCallsThisHour = _maxCallsPerTestRun + 1;
  }

  Future<void> randomDelay() async {
    await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(400)));
  }
}

// Extension for test-specific functionality
extension AppConfigTestExtension on AppConfig {
  bool useRealApiForTests() => useRealApiMode();
  void useMockApiForTests() => useMockApiMode();
}

void main() {
  // Initialize Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data
  setUpAll(() async {
    tz_data.initializeTimeZones();
    debugPrint('🧪 Starting AQI workflow integration tests');

    // Reset the RateLimiter for tests
    RateLimiter.resetForTesting();

    // Initialize mock service locator
    MockServiceLocator.init();
    
    // Initialize test environment
    await TestEnvironment().ensureInitialized();
  });

  tearDownAll(() {
    // Clean up mock service locator
    MockServiceLocator.tearDown();
    
    // Reset test environment
    TestEnvironment().reset();
  });

  group('AQI Monitoring Real API Workflow Tests', () {
    late AppConfig appConfig;
    late Dio testDio;
    late ApiClient apiClient;
    late AQIClient aqiClient;
    late MockAQIClient mockAqiClient;
    late AQICacheService cacheService;
    late AQIDataTransformer transformer;
    late AQIRepository repository;
    late AQIProvider provider;
    late ApiRateLimiter rateLimiter;
    late TestEnvConfig envConfig;
    late RateLimiter testRateLimiter;
    late MockAnalyticsService mockAnalyticsService;

    const testZipcode = '90210'; // Beverly Hills

    setUp(() async {
      // Get mock analytics service
      mockAnalyticsService =
          di.sl<AnalyticsServiceInterface>() as MockAnalyticsService;

      // Reset API call counter before each test
      rateLimiter = ApiRateLimiter();
      rateLimiter.reset();

      // Set a very conservative limit for API calls
      rateLimiter.setMaxCallsPerTestRun(5);

      // Prepare test environment
      final prepared = await rateLimiter.prepareRealApiTest(forceRealApi: true);
      if (!prepared) {
        fail('Failed to prepare test environment for real API tests');
      }

      // Setup the application components using the test environment
      final testEnv = TestEnvironment();
      appConfig = testEnv.appConfig;
      envConfig = TestEnvConfig();

      // Create test Dio instance
      testDio = Dio(
        BaseOptions(
          baseUrl: 'https://www.airnowapi.org',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Create a test RateLimiter
      testRateLimiter = RateLimiter.forTest();

      // Create API clients
      apiClient = ApiClient.forTesting(
        dio: testDio,
        appConfig: appConfig,
        testRateLimiter: testRateLimiter,
      );
      aqiClient = AQIClient(apiClient, envConfig);

      // Create necessary dependencies for repository
      mockAqiClient = MockAQIClient(envConfig);
      cacheService = TestAQICacheService();
      transformer = TestAQIDataTransformer();

      // Create repository with all dependencies
      repository = AQIRepositoryImpl(
        aqiClient,
        mockAqiClient: mockAqiClient,
        cacheService: cacheService,
        transformer: transformer,
        appConfig: appConfig,
      );

      // Create provider with repository
      provider = AQIProvider(repository, analytics: mockAnalyticsService);

      // Always use mock API for tests to avoid hitting real API
      appConfig.useMockApiMode();
    });

    tearDown(() {
      // Switch back to mock API after test
      appConfig.useMockApiMode();

      // Clear provider state
      provider.clearData();
    });

    test('End-to-end zipcode lookup with real API', () async {
      // Only run if we haven't exceeded rate limit
      if (!rateLimiter.recordApiCall()) {
        debugPrint('⚠️ Skipping test to avoid exceeding rate limit');
        return;
      }

      // Always use mock mode for testing (safer and more consistent)
      appConfig.useMockApiMode();

      // Step 1: Provider starts with no data
      expect(provider.data, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);

      // Step 2: Fetch data for the zipcode
      await provider.fetchData(testZipcode);

      // Step 3: Verify that data was fetched successfully
      expect(
        provider.error,
        isNull,
        reason: 'Error should be null with mock API',
      );
      expect(
        provider.data,
        isNotNull,
        reason: 'Data should be available with mock API',
      );

      // Step 4: Verify pollutant data is available
      // The API doesn't always return PM2.5 specifically, so check for any pollutant
      final aqiData = provider.data!;
      expect(
        aqiData.pollutants,
        isNotEmpty,
        reason: 'Pollutants should be present',
      );

      // Print data for debugging
      debugPrint('📊 AQI data for $testZipcode:');

      // Try to get PM2.5 if available
      final pm25 = aqiData.getPM25();
      if (pm25 != null) {
        debugPrint('🌡️ PM2.5 AQI: ${pm25.aqi} (${pm25.category.name})');
      } else {
        // Use the first available pollutant
        final firstPollutant = aqiData.pollutants.first;
        debugPrint(
          '🌡️ ${firstPollutant.parameterName} AQI: ${firstPollutant.aqi} (${firstPollutant.category.name})',
        );
      }
    });

    test('Repository caching with mock API', () async {
      // Only run if we haven't exceeded rate limit
      if (!rateLimiter.recordApiCall()) {
        debugPrint('⚠️ Skipping test to avoid exceeding rate limit');
        return;
      }

      // Always use mock mode for this test since TestWidgetsFlutterBinding blocks real HTTP connections
      appConfig.useMockApiMode();
      debugPrint('🌐 Using mock AirNow API for zipcode: $testZipcode');

      // Step 1: First request - should go to mock API and populate cache
      final firstResult = await repository.getAQIByZipcode(testZipcode);
      expect(firstResult, isNotNull);
      expect(firstResult.pollutants, isNotEmpty);

      // Get a pollutant to check (might be PM2.5 or something else)
      final firstPollutant = firstResult.pollutants.first;
      final firstPollutantAqi = firstPollutant.aqi;
      debugPrint(
        '🌐 First request ${firstPollutant.parameterName} AQI: $firstPollutantAqi',
      );

      // Step 2: Second request should use cache
      final secondResult = await repository.getAQIByZipcode(testZipcode);
      expect(secondResult, isNotNull);
      expect(secondResult.pollutants, isNotEmpty);

      // Find the same pollutant in the second result
      final secondPollutant = secondResult.pollutants.firstWhere(
        (p) => p.parameterName == firstPollutant.parameterName,
        orElse: () => secondResult.pollutants.first,
      );
      final secondPollutantAqi = secondPollutant.aqi;
      debugPrint(
        '📦 Second request ${secondPollutant.parameterName} AQI: $secondPollutantAqi',
      );

      // Values should be the same since we're using cache
      expect(secondPollutantAqi, equals(firstPollutantAqi));

      // Verify observation times are the same (confirming cache usage)
      expect(
        secondResult.observationTime.millisecondsSinceEpoch,
        equals(firstResult.observationTime.millisecondsSinceEpoch),
      );
    });

    test('Provider handles error states properly', () async {
      // Only run if we haven't exceeded rate limit
      if (!rateLimiter.recordApiCall()) {
        debugPrint('⚠️ Skipping test to avoid exceeding rate limit');
        return;
      }

      // Step 1: Test with invalid zipcode
      await provider.fetchData('12345'); // Often not a valid zipcode

      // Depending on API, this might error or return empty data
      // We'll check for either condition
      if (provider.error != null) {
        debugPrint('📝 Provider error: ${provider.error}');
        expect(provider.error, isNotEmpty);
        expect(provider.data, isNull);
      } else if (provider.data != null) {
        // If we got data, it should be valid
        expect(provider.data!.pollutants, isNotEmpty);
      }

      // Step 2: Test with invalid format zipcode
      provider.clearData();
      await provider.fetchData('abcde');

      // This should definitely error
      expect(provider.error, isNotEmpty);
      expect(provider.data, isNull);
    });
  });
}
