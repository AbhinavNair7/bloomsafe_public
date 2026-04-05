import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';

// Using simpler implementations instead of Mockito for clearer tests
class MockApiClient implements ApiClient {
  late Function(
    String, {
    Map<String, String?>? queryParams,
    bool enforceRateLimit,
  })
  onGet;

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String?>? queryParams,
    bool enforceRateLimit = true,
  }) {
    return onGet(
      endpoint,
      queryParams: queryParams,
      enforceRateLimit: enforceRateLimit,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockEnvConfig implements EnvConfig {
  String? _apiKey = 'test_api_key';

  void updateApiKey(String? value) {
    _apiKey = value;
  }

  @override
  Future<bool> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    return true;
  }

  @override
  Future<String?> getSecureApiKey() async {
    return _apiKey;
  }

  @override
  bool get disableRateLimit => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AQIClient', () {
    late AQIClient aqiClient;
    late MockApiClient mockApiClient;
    late MockEnvConfig mockEnvConfig;

    setUp(() {
      mockApiClient = MockApiClient();
      mockEnvConfig = MockEnvConfig();
      aqiClient = AQIClient(mockApiClient, mockEnvConfig);

      // Set default response for API client
      mockApiClient.onGet = (
        String endpoint, {
        Map<String, String?>? queryParams,
        bool enforceRateLimit = true,
      }) async {
        return [
          {'test': 'data'},
        ];
      };
    });

    group('ZIP Code Validation', () {
      test('Valid ZIP codes pass validation', () async {
        // Test with valid ZIP codes
        const validZips = ['94105', '10001', '20001', '30303', '48209'];

        for (final zip in validZips) {
          // This should not throw an exception for valid zips
          await aqiClient.getAirQualityByZipCode(zip, 'json', 25);
        }
      });

      test('Invalid ZIP codes throw InvalidZipcodeException', () async {
        // Test with invalid ZIP codes
        const invalidZips = ['abcde', '1234', '123456', '', '12a45'];

        for (final zip in invalidZips) {
          expect(
            () => aqiClient.getAirQualityByZipCode(zip, 'json', 25),
            throwsA(isA<InvalidZipcodeException>()),
          );
        }
      });
    });
  });
}
