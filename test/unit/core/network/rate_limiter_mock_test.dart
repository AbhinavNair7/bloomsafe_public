import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';

void main() {
  late RateLimiter rateLimiter;

  setUp(() {
    // Initialize Flutter binding
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Reset the singleton to ensure a clean test environment
    RateLimiter.resetForTesting();
    
    // Create a test-specific instance
    rateLimiter = RateLimiter.forTest();
    
    // Configure the rate limiter with a small limit for testing
    rateLimiter.configureStrategy(
      maxRequests: 3,
      lockoutDurationMinutes: 1,
    );
  });

  tearDown(() {
    RateLimiter.resetForTesting();
  });

  group('RateLimiter Basic Functionality', () {
    test('initial status should be normal', () async {
      final status = await rateLimiter.status;
      expect(status, equals(RateLimitStatus.normal));
    });

    test('should allow requests when under limit', () async {
      expect(await rateLimiter.isRequestAllowed(), isTrue);
    });

    test('maximum requests should be configurable', () {
      expect(rateLimiter.maxRequestsPerMinute, equals(3));
    });

    test('should have lockout duration configurable', () {
      expect(rateLimiter.lockoutDurationMinutes, equals(1));
    });
  });

  group('Request Counting', () {
    test('should track request count correctly', () async {
      // Initial count should be 0
      expect(await rateLimiter.requestsThisMinute, equals(0));
      
      // Record requests
      await rateLimiter.recordRequest();
      expect(await rateLimiter.requestsThisMinute, equals(1));
      
      await rateLimiter.recordRequest();
      expect(await rateLimiter.requestsThisMinute, equals(2));
    });

    test('usage percentage should reflect request count', () async {
      // Initial usage should be 0%
      expect(await rateLimiter.usagePercentage, equals(0.0));
      
      // Record requests
      await rateLimiter.recordRequest();
      expect(await rateLimiter.usagePercentage, closeTo(1/3, 0.01));
      
      await rateLimiter.recordRequest();
      expect(await rateLimiter.usagePercentage, closeTo(2/3, 0.01));
    });
  });

  group('Rate Limit Status Transitions', () {
    test('status should change with different thresholds', () async {
      // Initial status
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));
      
      // Record requests to reach warning threshold (70% of 3 = ~2.1)
      await rateLimiter.recordRequest(); // 1/3 = 33%
      await rateLimiter.recordRequest(); // 2/3 = 67% - still normal
      
      // With 2/3 requests (66.6%), we should still be normal 
      // since it's below the warning threshold of 70%
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));
      
      // Configure a rate limiter with a larger threshold to test all states
      rateLimiter.configureStrategy(
        maxRequests: 10,
        lockoutDurationMinutes: 1,
      );
      
      // Reset the counter
      RateLimiter.resetForTesting();
      rateLimiter = RateLimiter.forTest();
      rateLimiter.configureStrategy(
        maxRequests: 10, 
        lockoutDurationMinutes: 1,
      );
      
      // Normal: 0-6 requests (0-60%)
      await rateLimiter.recordRequest(); // 1/10 = 10%
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));
      
      // Warning: 7-8 requests (70-89%)
      await rateLimiter.recordRequest(); // 2/10 = 20%
      await rateLimiter.recordRequest(); // 3/10 = 30%
      await rateLimiter.recordRequest(); // 4/10 = 40%
      await rateLimiter.recordRequest(); // 5/10 = 50%
      await rateLimiter.recordRequest(); // 6/10 = 60%
      await rateLimiter.recordRequest(); // 7/10 = 70% - should be warning
      expect(await rateLimiter.status, equals(RateLimitStatus.warning));
      
      // Critical: 9 requests (90%)
      await rateLimiter.recordRequest(); // 8/10 = 80%
      await rateLimiter.recordRequest(); // 9/10 = 90% - should be critical
      expect(await rateLimiter.status, equals(RateLimitStatus.critical));
      
      // Exceeded: 10+ requests (100%+)
      await rateLimiter.recordRequest(); // 10/10 = 100% - should be exceeded
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
    });

    test('status should change to exceeded when over limit', () async {
      // Record enough requests to exceed the limit
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest();
      
      // This should push us over the limit
      await rateLimiter.recordRequest();
      
      // Status should be exceeded
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
      
      // Requests should no longer be allowed
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });
  });

  group('Lockout Behavior', () {
    test('should enter lockout when rate limit exceeded', () async {
      // Record enough requests to exceed the limit
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest(); // This exceeds the limit (3)
      
      // Should be in lockout mode
      expect(await rateLimiter.isLockedOut(), isTrue);
      
      // Request should be denied
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });
    
    test('manual API lockout should work', () async {
      // Trigger a manual API lockout
      await rateLimiter.enterApiLockout();
      
      // Should be in lockout
      expect(await rateLimiter.isLockedOut(), isTrue);
      
      // Status should be exceeded
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
    });
    
    test('lockout remaining time should be calculated correctly', () async {
      // Trigger lockout
      await rateLimiter.enterApiLockout();
      
      // Remaining time should be approximately the configured lockout time
      final remainingSeconds = await rateLimiter.lockoutRemainingSeconds();
      
      // Should be close to 60 seconds (1 minute)
      expect(remainingSeconds > 0, isTrue);
      expect(remainingSeconds <= 60, isTrue);
    });
  });
  
  group('Strategy Configuration', () {
    test('should allow changing strategy', () {
      // Test setting a different strategy
      final customStrategy = ClientSideRateLimitingStrategy(
        maxRequests: 10,
        lockoutDurationMinutes: 5,
      );
      
      rateLimiter.setStrategy(customStrategy);
      
      // Verify the changes took effect
      expect(rateLimiter.maxRequestsPerMinute, equals(10));
      expect(rateLimiter.lockoutDurationMinutes, equals(5));
    });
    
    test('should have correct rate limit type', () {
      expect(rateLimiter.activeRateLimitType, equals(RateLimitType.clientSide));
      
      // Use a different strategy
      rateLimiter.useClientSideStrategy();
      expect(rateLimiter.activeRateLimitType, equals(RateLimitType.clientSide));
    });
  });
} 