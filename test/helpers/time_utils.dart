import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// A utility class for manipulating time in tests
///
/// This helps test time-dependent functionality like:
/// - Cache expiration
/// - Rate limiting
/// - Timezone transitions
/// - Date/time validation
class TimeTestUtils {
  /// Initialize timezone database
  static void initializeTimeZones() {
    try {
      tz_data.initializeTimeZones();
    } catch (e) {
      // Already initialized, ignore
    }
  }

  /// Returns a specific time in a specific timezone for consistent testing
  ///
  /// This is useful for tests that need to run with a consistent time
  /// regardless of when the test is actually executed.
  static tz.TZDateTime fixedTime({
    String location = 'America/New_York',
    int year = 2023,
    int month = 1,
    int day = 15,
    int hour = 12,
    int minute = 0,
    int second = 0,
  }) {
    initializeTimeZones();
    return tz.TZDateTime(
      tz.getLocation(location),
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  /// Returns a time during DST transition for testing edge cases
  ///
  /// This creates dates that are useful for testing Daylight Saving Time transitions:
  /// - Spring forward (losing an hour)
  /// - Fall back (gaining an hour)
  static tz.TZDateTime dstTransitionTime({
    bool springForward = true,
    String location = 'America/New_York',
    int year = 2023,
  }) {
    initializeTimeZones();
    final tzLocation = tz.getLocation(location);

    // US DST transition dates for 2023 (these vary by year)
    if (springForward) {
      // Spring forward (second Sunday in March at 2 AM)
      return tz.TZDateTime(tzLocation, year, 3, 12, 1, 59, 0);
    } else {
      // Fall back (first Sunday in November at 2 AM)
      return tz.TZDateTime(tzLocation, year, 11, 5, 1, 59, 0);
    }
  }

  /// Waits for a rate limit window to expire in tests
  ///
  /// This is useful for testing rate limiting functionality without having
  /// to actually wait for the full duration in real time.
  static Future<void> waitForRateLimitWindow({
    Duration duration = const Duration(milliseconds: 10),
  }) async {
    // Small delay to simulate time passing in tests
    await Future.delayed(duration);
  }

  /// Creates a time that's just about to expire
  ///
  /// This is useful for testing edge cases around expiration times.
  static tz.TZDateTime almostExpiredTime({
    required tz.TZDateTime expiryTime,
    Duration buffer = const Duration(milliseconds: 100),
  }) {
    return expiryTime.subtract(buffer);
  }

  /// Creates a time that has just expired
  ///
  /// This is useful for testing edge cases around expiration times.
  static tz.TZDateTime justExpiredTime({
    required tz.TZDateTime expiryTime,
    Duration buffer = const Duration(milliseconds: 100),
  }) {
    return expiryTime.add(buffer);
  }

  /// Returns a map of test times for testing DST transitions
  ///
  /// This provides a set of times before, during, and after DST transitions
  /// to test time-sensitive functionality across transition boundaries.
  static Map<String, tz.TZDateTime> dstTestTimes(String location, int year) {
    initializeTimeZones();
    final tzLocation = tz.getLocation(location);

    // Get transition times
    final springForward = tz.TZDateTime(tzLocation, year, 3, 12, 1, 59, 0);
    final springForwardAfter = tz.TZDateTime(tzLocation, year, 3, 12, 3, 1, 0);
    final fallBack = tz.TZDateTime(tzLocation, year, 11, 5, 1, 59, 0);
    final fallBackAfter = tz.TZDateTime(tzLocation, year, 11, 5, 1, 1, 0, 0, 1);

    return {
      'springBefore': springForward,
      'springAfter': springForwardAfter,
      'fallBefore': fallBack,
      'fallAfter': fallBackAfter,
    };
  }
}
