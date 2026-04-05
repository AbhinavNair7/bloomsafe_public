import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/mock_api_client.dart';
import 'package:bloomsafe/core/config/app_config.dart';

// Test implementation of AppConfig
class TestAppConfig implements AppConfig {
  bool _mockApiValue = true;
  String? _apiKeyValue = 'test_api_key';
  int _maxRequestsValue = 5;
  final int _maxRequestsPerHourValue = 500;
  bool _testEnv = false;

  @override
  bool get useMockApi => _mockApiValue;

  @override
  String? get apiKey => _apiKeyValue;

  @override
  int get maxRequestsPerMinute => _maxRequestsValue;

  @override
  int get maxRequestsPerHour => _maxRequestsPerHourValue;

  void setMockApi(bool value) {
    _mockApiValue = value;
  }

  @override
  Future<bool> setApiKey(String apiKey) async {
    _apiKeyValue = apiKey;
    return true;
  }

  void setMaxRequests(int value) {
    _maxRequestsValue = value;
  }

  @override
  Future<void> initialize() async {
    // No-op for tests
    return Future.value();
  }

  @override
  Future<String?> getSecureApiKey() async {
    return _apiKeyValue;
  }

  @override
  bool toggleMockApi() {
    _mockApiValue = !_mockApiValue;
    return _mockApiValue;
  }

  @override
  void useMockApiMode() {
    _mockApiValue = true;
  }

  @override
  bool useRealApiMode() {
    _mockApiValue = false;
    return true;
  }

  @override
  Future<bool> useRealApiModeSecure() async {
    _mockApiValue = false;
    return true;
  }

  @override
  Future<void> useTestEnvironment({bool useTestEnv = true}) async {
    _testEnv = useTestEnv;
  }
}

void main() {
  group('Zipcode Validation Tests', () {
    late MockApiClient mockClient;
    late TestAppConfig testConfig;

    setUp(() {
      testConfig = TestAppConfig();
      testConfig.setMockApi(true);
      mockClient = MockApiClient.withAppConfig(appConfig: testConfig);
    });

    test('All zipcodes with length 5 return valid mock data', () async {
      final testZipcodes = [
        '10001',
        '90210',
        '20500',
        '33139',
        '60611',
        '11223',
      ];

      for (final zipcode in testZipcodes) {
        final response = await mockClient.getAirQualityByZipCode(
          zipcode,
          'json',
          25,
        );

        // Verify we get a response
        expect(
          response,
          isNotNull,
          reason: 'No response for zipcode: $zipcode',
        );
        expect(
          response.isNotEmpty,
          isTrue,
          reason: 'Empty response for zipcode: $zipcode',
        );

        // Verify the response format
        expect(
          response[0]['ParameterName'],
          equals('PM2.5'),
          reason: 'Invalid parameter for zipcode: $zipcode',
        );
        expect(
          response[0]['AQI'],
          isA<int>(),
          reason: 'Invalid AQI for zipcode: $zipcode',
        );
        expect(
          response[0]['Category'],
          isA<Map>(),
          reason: 'Invalid category for zipcode: $zipcode',
        );

        // Print the zipcode that worked
        print('✅ Zipcode $zipcode produced valid mock data');
      }
    });
  });
}
