import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limit_storage.dart';

void main() {
  // Initialize the Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RateLimiter', () {
    late RateLimiter rateLimiter;
    late InMemoryRateLimitStorage storage;

    setUp(() async {
      // Reset the instance for testing
      RateLimiter.resetForTesting();

      // Use in-memory storage for testing
      storage = InMemoryRateLimitStorage();

      // Create a new instance with in-memory storage and use client-side strategy
      rateLimiter = RateLimiter(storage: storage);
      rateLimiter.useClientSideStrategy();
    });

    test('should start with normal status', () async {
      expect(await rateLimiter.status, equals(RateLimitStatus.normal));
    });

    test('should record request and update count', () async {
      await rateLimiter.recordRequest();
      expect(await rateLimiter.requestsThisMinute, equals(1));
    });

    test('should return max requests from strategy', () {
      expect(rateLimiter.maxRequestsPerMinute, equals(5));
    });

    test('should allow request when under limit and not in lockout', () async {
      expect(await rateLimiter.isRequestAllowed(), isTrue);
    });

    test('should not allow request when in lockout', () async {
      // Manually trigger API lockout
      await rateLimiter.enterApiLockout();
      expect(await rateLimiter.isRequestAllowed(), isFalse);
    });
  });
}
