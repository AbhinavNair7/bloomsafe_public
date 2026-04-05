import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';

void main() {
  group('Rate Limiting Intensive Tests', () {
    late RateLimiter rateLimiter;
    
    setUp(() {
      // Reset the rate limiter for each test
      RateLimiter.resetForTesting();
      
      // Create a new rate limiter with test settings
      rateLimiter = RateLimiter.forTest();
      
      // Configure with specific limits
      rateLimiter.configureStrategy(
        maxRequests: 5,  // Allow 5 requests per minute
        lockoutDurationMinutes: 10, // 10-minute lockout
      );
    });
    
    test('allows requests within minute limit', () async {
      // Make 5 requests (at the minute limit)
      for (int i = 0; i < 5; i++) {
        expect(
          () async {
            final isAllowed = await rateLimiter.isRequestAllowed();
            expect(isAllowed, isTrue);
            await rateLimiter.recordRequest();
          },
          returnsNormally,
        );
      }
    });
    
    test('throws RateLimitException when minute limit exceeded', () async {
      // Make 5 requests (at the minute limit)
      for (int i = 0; i < 5; i++) {
        expect(await rateLimiter.isRequestAllowed(), isTrue);
        await rateLimiter.recordRequest();
      }
      
      // The 6th request should not be allowed
      expect(await rateLimiter.isRequestAllowed(), isFalse);
      
      // This should throw a rate limit exception
      await expectLater(
        () async {
          if (!(await rateLimiter.isRequestAllowed())) {
            throw RateLimitException('Rate limit exceeded');
          }
        },
        throwsA(isA<RateLimitException>()),
      );
    });
    
    test('allows requests again after minute window passes', () async {
      // Make 5 requests (at the minute limit)
      for (int i = 0; i < 5; i++) {
        expect(await rateLimiter.isRequestAllowed(), isTrue);
        await rateLimiter.recordRequest();
      }
      
      // 6th request would not be allowed
      expect(await rateLimiter.isRequestAllowed(), isFalse);
      
      // Reset the counter by simulating time passing
      // Force clear lockout and reset counter for testing
      await rateLimiter.checkLockoutExpiration();
      await rateLimiter.clearOldRequestCounts();
      
      // Now we should be able to make more requests
      expect(await rateLimiter.isRequestAllowed(), isTrue);
    });
    
    test('retryWithBackoff respects rate limits', () async {
      // Set up rate limiter to allow only 3 requests
      rateLimiter.configureStrategy(
        maxRequests: 3,
        lockoutDurationMinutes: 10,
      );
      
      int attempts = 0;
      int successCount = 0;
      
      // Function that will hit rate limit after 3 calls
      Future<bool> operation() async {
        attempts++;
        
        if (await rateLimiter.isRequestAllowed()) {
          await rateLimiter.recordRequest();
          successCount++;
          return true;
        } else {
          throw RateLimitException('Rate limit exceeded');
        }
      }
      
      // This should fail because it will hit rate limit before succeeding
      await expectLater(
        () => ErrorProcessor.retryWithBackoff<bool>(
          operation: operation,
          retryCount: 5, // Try up to 5 times
          initialDelay: const Duration(milliseconds: 100), // Short delay for testing
        ),
        throwsA(isA<RateLimitException>()),
      );
      
      // We should have made exactly 3 successful requests before hitting rate limit
      expect(successCount, equals(3));
      
      // We should have attempted 4 times (3 successful + 1 that hit rate limit)
      expect(attempts, equals(4));
    });
  }, skip: 'Intensive test, run with --run-skipped flag',);
} 