import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';

void main() {
  group('RateLimitType enum', () {
    test('should have all expected values', () {
      expect(RateLimitType.values.length, equals(3));
      expect(RateLimitType.values, contains(RateLimitType.clientSide));
      expect(RateLimitType.values, contains(RateLimitType.serverMinute));
      expect(RateLimitType.values, contains(RateLimitType.serverHourly));
    });
  });

  group('ClientSideRateLimitingStrategy', () {
    late ClientSideRateLimitingStrategy strategy;

    setUp(() {
      strategy = ClientSideRateLimitingStrategy();
    });

    test('should have correct type', () {
      expect(strategy.rateLimitType, equals(RateLimitType.clientSide));
    });

    test('should have correct limits', () {
      expect(strategy.maxRequests, equals(5));
      expect(strategy.lockoutDurationMinutes, equals(10));
    });

    test('should have correct thresholds', () {
      expect(strategy.warningThreshold, equals(0.7));
      expect(strategy.criticalThreshold, equals(0.9));
    });

    test('should calculate usage percentage correctly', () {
      expect(strategy.calculateUsagePercentage(0), equals(0.0));
      expect(strategy.calculateUsagePercentage(1), equals(0.2));
      expect(strategy.calculateUsagePercentage(3), equals(0.6));
      expect(strategy.calculateUsagePercentage(5), equals(1.0));
      expect(strategy.calculateUsagePercentage(6), equals(1.2));
    });

    test('should correctly determine if request is allowed', () {
      // Not in lockout, under limit
      expect(strategy.isRequestAllowed(0, false), isTrue);
      expect(strategy.isRequestAllowed(4, false), isTrue);

      // Not in lockout, at/over limit
      expect(strategy.isRequestAllowed(5, false), isFalse);
      expect(strategy.isRequestAllowed(6, false), isFalse);

      // In lockout, any count
      expect(strategy.isRequestAllowed(0, true), isFalse);
      expect(strategy.isRequestAllowed(3, true), isFalse);
      expect(strategy.isRequestAllowed(5, true), isFalse);
    });

    test('should correctly determine warning threshold', () {
      // Below warning threshold
      expect(strategy.isWarning(0), isFalse);
      expect(strategy.isWarning(3), isFalse);

      // At/above warning threshold but below critical
      expect(strategy.isWarning(4), isTrue); // 0.8 > 0.7

      // Above critical threshold (also counts as warning)
      expect(strategy.isWarning(5), isTrue);
    });

    test('should correctly determine critical threshold', () {
      // Below critical threshold
      expect(strategy.isCritical(0), isFalse);
      expect(strategy.isCritical(4), isFalse);

      // At/above critical threshold
      expect(strategy.isCritical(5), isTrue);
      expect(strategy.isCritical(6), isTrue);
    });
  });

  group('BaseRateLimitingStrategy', () {
    late TestStrategy strategy;

    setUp(() {
      strategy = TestStrategy();
    });

    test('should calculate usage percentage correctly', () {
      expect(strategy.calculateUsagePercentage(0), equals(0.0));
      expect(strategy.calculateUsagePercentage(5), equals(0.5));
      expect(strategy.calculateUsagePercentage(10), equals(1.0));
    });

    test('should determine request allowance correctly', () {
      expect(strategy.isRequestAllowed(0, false), isTrue);
      expect(strategy.isRequestAllowed(9, false), isTrue);
      expect(strategy.isRequestAllowed(10, false), isFalse);
      expect(strategy.isRequestAllowed(0, true), isFalse);
    });

    test('should determine warning correctly', () {
      expect(strategy.isWarning(0), isFalse);
      expect(strategy.isWarning(6), isFalse);
      expect(strategy.isWarning(7), isTrue); // 0.7
      expect(strategy.isWarning(10), isTrue);
    });

    test('should determine critical correctly', () {
      expect(strategy.isCritical(0), isFalse);
      expect(strategy.isCritical(8), isFalse);
      expect(strategy.isCritical(9), isTrue); // 0.9
      expect(strategy.isCritical(10), isTrue);
    });

    test('should determine status correctly', () {
      expect(strategy.getStatus(0, false), equals(RateLimitStatus.normal));
      expect(strategy.getStatus(7, false), equals(RateLimitStatus.warning));
      expect(strategy.getStatus(9, false), equals(RateLimitStatus.critical));
      expect(strategy.getStatus(0, true), equals(RateLimitStatus.exceeded));
    });
  });
}

/// Test implementation of BaseRateLimitingStrategy for testing
class TestStrategy extends BaseRateLimitingStrategy {
  @override
  RateLimitType get rateLimitType => RateLimitType.clientSide;

  @override
  int get maxRequests => 10;

  @override
  int get lockoutDurationMinutes => 5;

  @override
  double get warningThreshold => 0.7;

  @override
  double get criticalThreshold => 0.9;
}
