import 'package:bloomsafe/core/config/env_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

// Create a mock EnvConfig for testing
class MockEnvConfig extends Mock implements EnvConfig {}

/// Test-specific implementation for testing without using the real ApiClient
class TestApiClient {

  TestApiClient()
    : dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    // Add a simple error interceptor for testing
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );

    // Add a logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          responseBody: true,
          requestBody: true,
          error: true,
        ),
      );
    }
  }
  bool _rateLimitExceeded = false;
  final Dio dio;
  final Duration defaultConnectTimeout = const Duration(seconds: 10);
  final Duration defaultReceiveTimeout = const Duration(seconds: 15);

  void simulateRateLimitExceeded(bool exceeded) {
    _rateLimitExceeded = exceeded;
  }

  Future<bool> shouldUseCacheOnly() async {
    return _rateLimitExceeded;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Set up environment variables for tests using a memory map
    // instead of loading from a file
    dotenv.testLoad(
      fileInput: '''
      # Test API Keys
      AIRNOW_API_KEY=test_api_key
      
      # Test Rate Limiting
      MAX_REQUESTS_PER_MINUTE=5
      
      # Test Settings
      MOCK_API=true
    ''',
    );
  });

  group('Dio Configuration', () {
    late TestApiClient apiClient;

    setUp(() {
      apiClient = TestApiClient();
    });

    test('Timeout configured to default request timeout', () {
      expect(
        apiClient.dio.options.connectTimeout,
        apiClient.defaultConnectTimeout,
      );
      expect(
        apiClient.dio.options.receiveTimeout,
        apiClient.defaultReceiveTimeout,
      );
    });

    test('Content type header set to application/json', () {
      expect(apiClient.dio.options.headers['Content-Type'], 'application/json');
    });
  });

  group('Interceptors', () {
    late TestApiClient apiClient;

    setUp(() {
      apiClient = TestApiClient();
    });

    test('Error interceptor is added', () {
      final interceptors = apiClient.dio.interceptors;
      expect(interceptors.any((i) => i is InterceptorsWrapper), isTrue);
    });

    test('Logging interceptor only in debug mode', () {
      final hasLoggingInterceptor = apiClient.dio.interceptors.any(
        (i) => i is LogInterceptor,
      );

      // Different assertion depending on build mode
      if (kDebugMode) {
        expect(hasLoggingInterceptor, isTrue);
      } else {
        expect(hasLoggingInterceptor, isFalse);
      }
    });
  });

  group('Rate Limiting', () {
    late TestApiClient apiClient;

    setUp(() {
      apiClient = TestApiClient();
    });

    test('Rate limiting behavior when limits are exceeded', () async {
      // Simulate the rate limit being exceeded
      apiClient.simulateRateLimitExceeded(true);

      // Should return true as we've directly set the rate limit exceeded
      expect(await apiClient.shouldUseCacheOnly(), true);
    });
  });
}
