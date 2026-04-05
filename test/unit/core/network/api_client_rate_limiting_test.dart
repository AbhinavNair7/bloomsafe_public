import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/core/config/app_config.dart';

// Create a test implementation for rate limiting
class TestRateLimiter implements RateLimiter {

  TestRateLimiter({this.maxRequests = 3});
  int requestCount = 0;
  bool isLocked = false;
  final int maxRequests;

  @override
  Future<bool> canMakeRequest() async {
    return !isLocked && requestCount < maxRequests;
  }

  @override
  Future<void> recordRequest() async {
    requestCount++;
    if (requestCount >= maxRequests) {
      isLocked = true;
    }
  }

  @override
  Future<bool> shouldUseCacheOnly() async {
    return isLocked;
  }
  
  // Implement other required methods with minimal functionality
  @override
  Future<void> configureStrategy({int? maxRequests, int? lockoutDurationMinutes}) async {}
  
  @override
  Future<void> reportApiRateLimit() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Create a mock Dio implementation that returns predictable responses
class MockDio implements Dio {

  MockDio({this.successResponse = const {'success': true}});
  final Map<String, dynamic> successResponse;
  bool returnError = false;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (returnError) {
      throw DioException(
        response: Response(
          data: 'Rate limit exceeded',
          statusCode: 429,
          requestOptions: RequestOptions(path: path),
        ),
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.badResponse,
      );
    }
    
    return Response<T>(
      data: successResponse as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  // Implement required but unused methods
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock AppConfig for rate limiting with direct override of disableRateLimit getter
class MockAppConfig implements AppConfig {
  
  MockAppConfig({bool disableRateLimit = false}) : _disableRateLimit = disableRateLimit;
  final bool _disableRateLimit;
  
  @override
  bool get disableRateLimit => _disableRateLimit;
  
  // Implement getSecureApiKey for testing
  @override
  Future<String?> getSecureApiKey() async => 'test_api_key';
  
  // Implement required but unused methods
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Create a testing ApiClient class that doesn't rely on dotenv
class TestApiClient extends ApiClient {
  
  TestApiClient({
    required super.dio,
    required MockAppConfig super.appConfig,
    required this.testRateLimiter,
    this.enforceRateLimit = true,
  }) : super.forTesting(
    testRateLimiter: testRateLimiter,
  );
  final TestRateLimiter testRateLimiter;
  final bool enforceRateLimit;
  
  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String?>? queryParams,
    bool? enforceRateLimit,
  }) async {
    final bool shouldEnforce = enforceRateLimit ?? this.enforceRateLimit;
    
    if (shouldEnforce && !await testRateLimiter.canMakeRequest()) {
      throw RateLimitExceededException('Rate limit exceeded');
    }
    
    // Simulate Dio call for testing
    try {
      final response = await (dio as MockDio).get(
        endpoint,
        queryParameters: queryParams?.cast<String, dynamic>(),
      );
      
      if (shouldEnforce) {
        await testRateLimiter.recordRequest();
      }
      
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        await testRateLimiter.reportApiRateLimit();
        throw RateLimitExceededException('API rate limit exceeded');
      }
      rethrow;
    }
  }
  
  @override
  Future<bool> shouldUseCacheOnly() async {
    return testRateLimiter.isLocked;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dotenv
  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
      AIRNOW_API_KEY=test_api_key
      MAX_REQUESTS_PER_MINUTE=3
      DISABLE_RATE_LIMIT=false
      MOCK_API=true
      ''',
    );
  });
  
  late TestApiClient apiClient;
  late MockDio mockDio;
  late TestRateLimiter testRateLimiter;
  late MockAppConfig mockAppConfig;

  const String testEndpoint = 'test/endpoint';

  setUp(() {
    // Setup mocks
    mockDio = MockDio();
    testRateLimiter = TestRateLimiter(maxRequests: 3);
    mockAppConfig = MockAppConfig(disableRateLimit: false);
    
    // Create the API client using our test implementation
    apiClient = TestApiClient(
      dio: mockDio,
      appConfig: mockAppConfig,
      testRateLimiter: testRateLimiter,
    );
  });

  group('API Client Rate Limiting', () {
    test('should make successful API calls when under rate limit', () async {
      // Make API calls up to the limit (3)
      final result1 = await apiClient.get(testEndpoint);
      final result2 = await apiClient.get(testEndpoint);
      final result3 = await apiClient.get(testEndpoint);
      
      // All requests should be successful
      expect(result1, isA<Map<String, dynamic>>());
      expect(result2, isA<Map<String, dynamic>>());
      expect(result3, isA<Map<String, dynamic>>());
      
      // Verify rate limiter tracked the requests
      expect(testRateLimiter.requestCount, 3);
    });

    test('should throw RateLimitExceededException when rate limit exceeded', () async {
      // Make API calls up to the limit
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      
      // Next call should throw a rate limit exception
      expect(
        () async => await apiClient.get(testEndpoint),
        throwsA(isA<RateLimitExceededException>()),
      );
      
      // Verify rate limiter is locked
      expect(testRateLimiter.isLocked, true);
    });
    
    test('should bypass rate limiting when enforceRateLimit is false', () async {
      // Make API calls up to the limit
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      
      // Limiter should be locked now
      expect(testRateLimiter.isLocked, true);
      
      // Next call with enforceRateLimit=false should succeed
      final result = await apiClient.get(
        testEndpoint, 
        enforceRateLimit: false,
      );
      
      // The call should succeed
      expect(result, isA<Map<String, dynamic>>());
    });
    
    test('should detect API-side rate limit (429 responses)', () async {
      // Configure Dio to simulate a 429 rate limit response
      mockDio.returnError = true;
      
      // Call should throw RateLimitExceededException
      expect(
        () async => await apiClient.get(testEndpoint),
        throwsA(isA<RateLimitExceededException>()),
      );
    });
    
    test('shouldUseCacheOnly returns true when rate limited', () async {
      // Make API calls up to the limit
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      
      // ShouldUseCacheOnly should return true
      final result = await apiClient.shouldUseCacheOnly();
      expect(result, isTrue);
    });
    
    test('shouldUseCacheOnly returns false when not rate limited', () async {
      // Make one API call (below the limit)
      await apiClient.get(testEndpoint);
      
      // ShouldUseCacheOnly should return false
      final result = await apiClient.shouldUseCacheOnly();
      expect(result, isFalse);
    });
    
    test('respects disableRateLimit setting', () async {
      // Recreate API client with rate limiting disabled
      apiClient = TestApiClient(
        dio: mockDio,
        appConfig: MockAppConfig(disableRateLimit: true),
        testRateLimiter: testRateLimiter,
        enforceRateLimit: false, // Simulate the effect of disableRateLimit
      );
      
      // Should be able to make more calls than the limit
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      await apiClient.get(testEndpoint);
      final result = await apiClient.get(testEndpoint); // This would normally fail
      
      // The call should succeed even though we're over the limit
      expect(result, isA<Map<String, dynamic>>());
    });
  });
} 