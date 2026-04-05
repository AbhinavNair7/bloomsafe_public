import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import '../../../helpers/test_setup.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limit_storage.dart';

void main() {
  setUpAll(setupTestEnvironment);

  group('RateLimiter', () {
    late RateLimiter rateLimiter;
    late InMemoryRateLimitStorage storage;

    setUp(() {
      // Reset the instance for testing
      RateLimiter.resetForTesting();

      // Use in-memory storage for testing
      storage = InMemoryRateLimitStorage();

      // Create a new instance with in-memory storage and use client-side strategy
      rateLimiter = RateLimiter(storage: storage);
      rateLimiter.useClientSideStrategy();

      // Configure the rate limiter with a fixed strategy for testing
      rateLimiter.configureStrategy(
        maxRequests: 10,
        lockoutDurationMinutes: 10,
      );
    });

    test('tracks API requests', () async {
      // Act - record a request
      await rateLimiter.recordRequest();

      // Assert - request count should increase
      expect(await rateLimiter.requestsThisMinute, equals(1));
    });

    test('limits requests based on configured thresholds', () async {
      // Make requests up to the limit
      for (int i = 0; i < 10; i++) {
        expect(await rateLimiter.isRequestAllowed(), isTrue);
        await rateLimiter.recordRequest();
      }

      // Assert - now we should be at the limit
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });

    test('updates status based on usage percentage', () async {
      // Initially normal
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));

      // Make 6 requests (60% of limit) - still normal since it's below the 70% warning threshold
      for (int i = 0; i < 6; i++) {
        await rateLimiter.recordRequest();
      }

      // Should be normal still (below 70% threshold)
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));

      // Make one more to get to 70% (7/10)
      await rateLimiter.recordRequest();

      // Should now be in warning zone (at 70% exactly)
      expect(await rateLimiter.status, equals(RateLimitStatus.warning));

      // Make more requests to reach 90% (9/10)
      await rateLimiter.recordRequest();
      await rateLimiter.recordRequest();

      // Should now be in critical zone (at 90% exactly)
      expect(await rateLimiter.status, equals(RateLimitStatus.critical));

      // Make one more to get to 100% (10/10)
      await rateLimiter.recordRequest();

      // Should now be in exceeded state
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
    });

    test('enters lockout when limits exceeded', () async {
      // Make 5 requests (50% of limit) - should still be normal
      for (int i = 0; i < 5; i++) {
        await rateLimiter.recordRequest();
      }
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));

      // Make 5 more requests to reach the limit
      for (int i = 0; i < 5; i++) {
        await rateLimiter.recordRequest();
      }

      // Now it should be in exceeded state since we've reached the limit
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });

    test('can manually trigger API lockout', () async {
      // Initially should allow requests
      expect(await rateLimiter.isRequestAllowed(), isTrue);

      // Manually trigger lockout
      await rateLimiter.enterApiLockout();

      // Should now be in exceeded state
      expect(await rateLimiter.status, equals(RateLimitStatus.exceeded));
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });

    test('calculates usage percentage correctly', () async {
      // Initially 0%
      expect(await rateLimiter.usagePercentage, equals(0.0));

      // Make 5 requests (50% of 10)
      for (int i = 0; i < 5; i++) {
        await rateLimiter.recordRequest();
      }

      // Should be at 50%
      expect(await rateLimiter.usagePercentage, equals(0.5));
    });
  });
}
