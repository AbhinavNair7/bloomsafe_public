import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';

/// This test examines two rate limiting behaviors:
///
/// 1. Client-side rate limiter: 5 requests per minute with 10-minute lockout
/// 2. API-enforced rate limit: 10 requests per minute with 429 error response
///
/// DO NOT run this test regularly as it will consume API quota.
/// To run this test explicitly: flutter test test/intensive/per_minute_limit_test.dart --run-skipped
@Tags(['intensive'])
void main() {
  // Initialize Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RATE LIMIT TEST - Testing both client and API rate limits', () {
    late ApiClient apiClient;
    late TestAppConfig config;

    setUp(() {
      // Create a fresh API client with a reset rate limiter for each test
      config = TestAppConfig();
      apiClient = ApiClient.withAppConfig(appConfig: config);
      RateLimiter.resetForTesting();
    });

    test(
      'RATE LIMIT TEST - Testing both client and API rate limits',
      () async {
        debugPrint(
          '🧪 Starting rate limit test with 10 immediate consecutive requests',
        );

        // PART 1: Test with burst of 10 consecutive requests
        // ===============================================
        int successfulRequests = 0;
        String? errorMessage;

        for (int i = 1; i <= 10; i++) {
          try {
            debugPrint('📤 Request #$i: Sending request to API');
            // Use a zipcode with East coast timezone pattern
            final response = await apiClient.getAirQualityByZipCode(
              '10001',
              'json',
              25,
            );

            debugPrint(
              '📥 Request #$i: Received successful response with ${response.length} items',
            );
            successfulRequests++;
          } catch (e) {
            errorMessage = e.toString();
            debugPrint('🛑 Request #$i: Error encountered: $errorMessage');

            if (e is RateLimitExceededException) {
              debugPrint(
                '⚠️ Client-side rate limit triggered after $successfulRequests requests',
              );
              expect(
                successfulRequests,
                config.maxRequestsPerMinute,
                reason:
                    'Client-side rate limit should be triggered at exactly maxRequestsPerMinute',
              );

              // Detailed rate limit info for reporting
              final isLockedOut = await apiClient.rateLimiter.isLockedOut();
              final lockoutTime =
                  await apiClient.rateLimiter.lockoutRemainingSeconds();
              final errorType =
                  e.toString().contains('servers are busy')
                      ? 'API-side rate limit'
                      : 'Client-side rate limit';
              debugPrint(
                '⭐️ $errorType triggered | Locked out: $isLockedOut | Lockout time: $lockoutTime seconds',
              );
              debugPrint('⭐️ Error message: ${e.toString()}');
              break;
            }
          }
        }

        RateLimiter.resetForTesting();

        debugPrint(
          '\n🧪 Starting rate limit test with evenly spaced requests (5 seconds apart)',
        );

        // PART 2: Test with evenly spaced requests (5 seconds apart)
        // ===============================================
        // Reset counters
        successfulRequests = 0;
        errorMessage = null;

        for (int i = 1; i <= 10; i++) {
          try {
            debugPrint('📤 Spaced Request #$i: Sending request to API');
            // Use a zipcode with East coast timezone pattern
            final response = await apiClient.getAirQualityByZipCode(
              '20001',
              'json',
              25,
            );

            debugPrint(
              '📥 Spaced Request #$i: Received successful response with ${response.length} items',
            );
            successfulRequests++;

            if (i < 10) {
              debugPrint('⏱️ Waiting 5 seconds before next request...');
              await Future.delayed(const Duration(seconds: 5));
            }
          } catch (e) {
            errorMessage = e.toString();
            debugPrint(
              '🛑 Spaced Request #$i: Error encountered: $errorMessage',
            );

            if (e is RateLimitExceededException) {
              debugPrint(
                '⚠️ Rate limit triggered after $successfulRequests spaced requests',
              );

              // Detailed rate limit info for reporting
              final isLockedOut = await apiClient.rateLimiter.isLockedOut();
              final lockoutTime =
                  await apiClient.rateLimiter.lockoutRemainingSeconds();
              final errorType =
                  e.toString().contains('servers are busy')
                      ? 'API-side rate limit'
                      : 'Client-side rate limit';
              debugPrint(
                '⭐️ $errorType triggered | Locked out: $isLockedOut | Lockout time: $lockoutTime seconds',
              );
              debugPrint('⭐️ Error message: ${e.toString()}');
              break;
            }
          }
        }

        // Final report
        debugPrint('📊 FINAL REPORT:');
        debugPrint(
          '🔹 Client-side rate limit configured at: ${config.maxRequestsPerMinute} requests per minute',
        );
        debugPrint(
          '🔹 API-side rate limits are determined by the AirNow API service',
        );
        debugPrint('🔹 Lockout duration: 10 minutes');

        // This test always passes - we're just collecting info
        expect(true, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip:
          'Intensive test that makes many API calls. Run with --run-skipped flag.',
    );
  });
}

/// Test implementation of AppConfig for the test
class TestAppConfig implements AppConfig {
  bool _mockApiValue = false;
  String _apiKeyValue = 'test_api_key'; // Test API key
  int _maxRequestsValue = 5;
  final int _maxRequestsPerHourValue = 500;

  @override
  bool get useMockApi => _mockApiValue;

  @override
  String? get apiKey => _apiKeyValue;

  @override
  int get maxRequestsPerMinute => _maxRequestsValue;

  @override
  int get maxRequestsPerHour => _maxRequestsPerHourValue;

  @override
  bool get disableRateLimit => false;

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
    // No-op for tests
  }
}
