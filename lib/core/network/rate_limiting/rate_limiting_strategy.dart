/// Enum representing different types of rate limiting
enum RateLimitType {
  /// Client-side rate limiting to prevent excessive API calls
  clientSide,

  /// Server-side per-minute rate limiting
  serverMinute,

  /// Server-side hourly rate limiting
  serverHourly,
}

/// Enum representing rate limiter status levels
enum RateLimitStatus {
  /// Normal operation, well below threshold
  normal,

  /// Warning level, approaching rate limit
  warning,

  /// Critical level, very close to rate limit
  critical,

  /// Exceeded rate limit, in lockout period
  exceeded,
}

/// Base interface for rate limiting strategies
abstract class RateLimitingStrategy {
  /// The type of rate limiting this strategy implements
  RateLimitType get rateLimitType;

  /// Maximum number of requests allowed in the time window
  int get maxRequests;

  /// Duration of lockout in minutes when rate limit is exceeded
  int get lockoutDurationMinutes;

  /// Threshold percentage (0.0-1.0) at which to issue warnings
  double get warningThreshold;

  /// Threshold percentage (0.0-1.0) at which usage becomes critical
  double get criticalThreshold;

  /// Calculate the percentage of rate limit used
  ///
  /// Returns a value between 0.0 and 1.0+ where:
  /// - 0.0 means no usage
  /// - 1.0 means limit reached
  /// - >1.0 means limit exceeded
  double calculateUsagePercentage(int currentCount);

  /// Determine if a request should be allowed based on the current
  /// request count and lockout state
  bool isRequestAllowed(int currentCount, bool isInLockout);

  /// Determine if usage has reached warning level
  bool isWarning(int currentCount);

  /// Determine if usage has reached critical level
  bool isCritical(int currentCount);

  /// Get the current rate limit status
  RateLimitStatus getStatus(int currentCount, bool isInLockout);
}

/// Base implementation with common functionality for rate limiting strategies
abstract class BaseRateLimitingStrategy implements RateLimitingStrategy {
  @override
  double calculateUsagePercentage(int currentCount) {
    // Prevent division by zero
    if (maxRequests <= 0) return 1.0;
    return currentCount / maxRequests;
  }

  @override
  bool isRequestAllowed(int currentCount, bool isInLockout) {
    if (isInLockout) return false;
    return currentCount < maxRequests;
  }

  @override
  bool isWarning(int currentCount) {
    final percentage = calculateUsagePercentage(currentCount);
    return percentage >= warningThreshold;
  }

  @override
  bool isCritical(int currentCount) {
    final percentage = calculateUsagePercentage(currentCount);
    return percentage >= criticalThreshold;
  }

  @override
  RateLimitStatus getStatus(int currentCount, bool isInLockout) {
    if (isInLockout) {
      return RateLimitStatus.exceeded;
    } else if (isCritical(currentCount)) {
      return RateLimitStatus.critical;
    } else if (isWarning(currentCount)) {
      return RateLimitStatus.warning;
    } else {
      return RateLimitStatus.normal;
    }
  }
}

/// Client-side rate limiting strategy to prevent excessive API calls
class ClientSideRateLimitingStrategy extends BaseRateLimitingStrategy {

  ClientSideRateLimitingStrategy({
    int? maxRequests,
    int? lockoutDurationMinutes,
  }) : _maxRequests = maxRequests ?? 5,
       _lockoutDurationMinutes = lockoutDurationMinutes ?? 10;
  final int _maxRequests;
  final int _lockoutDurationMinutes;

  @override
  RateLimitType get rateLimitType => RateLimitType.clientSide;

  @override
  int get maxRequests => _maxRequests; // Default: Allow 5 requests per minute

  @override
  int get lockoutDurationMinutes => _lockoutDurationMinutes; // Default: 10 minute lockout

  @override
  double get warningThreshold => 0.7; // 70% of max requests

  @override
  double get criticalThreshold => 0.9; // 90% of max requests
}
