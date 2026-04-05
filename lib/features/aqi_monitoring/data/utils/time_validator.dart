library;

import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart'
    as tzm;
import 'package:bloomsafe/core/utils/logger.dart';

/// A utility class that validates time-related criteria with timezone awareness
///
/// Provides methods to check:
/// - If a timestamp is valid (not expired)
/// - If data is fresh enough for various purposes
/// - How much time remains until expiration
class TimeValidator {
  /// Default freshness threshold (hours)
  static const int defaultFreshnessThreshold = 1;

  /// Default expiry threshold (hours)
  static const int defaultExpiryThreshold = 2;

  /// Checks if data is still valid based on its observation time and expiration time
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [validUntil]: The timestamp after which data is considered expired
  ///
  /// Returns true if data is still valid (current time is before validUntil)
  static bool isValid(tz.TZDateTime observationTime, tz.TZDateTime validUntil) {
    final now = tzm.getCurrentTimeInZone(observationTime.location);
    return now.isBefore(validUntil);
  }

  /// Checks if data is considered fresh based on its observation time
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [freshnessThreshold]: Optional threshold in hours (default: 1 hour)
  ///
  /// Returns true if data was observed within the freshness threshold
  static bool isFresh(
    tz.TZDateTime observationTime, {
    int freshnessThresholdHours = defaultFreshnessThreshold,
  }) {
    final now = tzm.getCurrentTimeInZone(observationTime.location);
    final freshnessThreshold = Duration(hours: freshnessThresholdHours);
    final age = now.difference(observationTime);

    return age <= freshnessThreshold;
  }

  /// Checks if data is expired but still usable as a fallback
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [validUntil]: The timestamp after which data is considered expired
  /// - [maxFallbackAge]: Maximum age for fallback in hours
  ///
  /// Returns true if data is expired but still within the fallback window
  static bool isUsableAsFallback(
    tz.TZDateTime observationTime,
    tz.TZDateTime validUntil, {
    required Duration maxFallbackAge,
  }) {
    final now = tzm.getCurrentTimeInZone(observationTime.location);

    // Check if data is expired but not too old
    final isExpired = now.isAfter(validUntil);
    final age = now.difference(observationTime);

    return isExpired && age <= maxFallbackAge;
  }

  /// Calculates how much time remains until data expires
  ///
  /// Parameters:
  /// - [validUntil]: The expiration timestamp
  ///
  /// Returns a Duration representing time until expiration
  /// (negative duration if already expired)
  static Duration timeUntilExpiry(tz.TZDateTime validUntil) {
    final now = tzm.getCurrentTimeInZone(validUntil.location);
    return validUntil.difference(now);
  }

  /// Calculates how old the data is relative to observation time
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  ///
  /// Returns a Duration representing the age of the data
  static Duration dataAge(tz.TZDateTime observationTime) {
    final now = tzm.getCurrentTimeInZone(observationTime.location);
    return now.difference(observationTime);
  }

  /// Calculates the expiry time for data based on observation time
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [expiryThresholdHours]: Hours until expiry (default: 2)
  ///
  /// Returns the timestamp when data should be considered expired
  static tz.TZDateTime calculateExpiryTime(
    tz.TZDateTime observationTime, {
    int expiryThresholdHours = defaultExpiryThreshold,
  }) {
    return tzm.calculateExpiryTime(
      observationTime,
      expiryHours: expiryThresholdHours,
    );
  }

  /// Checks if data crosses a DST transition boundary
  ///
  /// This is useful to detect edge cases where time calculations
  /// might be affected by Daylight Saving Time transitions
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [validUntil]: The timestamp after which data is considered expired
  ///
  /// Returns true if there's a DST transition between the two timestamps
  static bool containsDstTransition(
    tz.TZDateTime observationTime,
    tz.TZDateTime validUntil,
  ) {
    return observationTime.timeZoneOffset != validUntil.timeZoneOffset;
  }

  /// Logs metrics about data validity and freshness (for debugging)
  ///
  /// Parameters:
  /// - [observationTime]: The time when data was observed/created
  /// - [validUntil]: The timestamp after which data is considered expired
  /// - [label]: Optional label for the log message
  static void logValidityMetrics(
    tz.TZDateTime observationTime,
    tz.TZDateTime validUntil, {
    String label = 'Data',
  }) {
    final now = tzm.getCurrentTimeInZone(observationTime.location);
    final isDataValid = now.isBefore(validUntil);
    final age = now.difference(observationTime);
    final timeToExpiry = validUntil.difference(now);

    final ageHours = age.inHours;
    final ageMinutes = age.inMinutes % 60;

    final validityStatus = isDataValid ? 'valid' : 'expired';
    final dstInfo =
        containsDstTransition(observationTime, validUntil)
            ? ' (crosses DST transition)'
            : '';

    Logger.debug(
      '$label is $validityStatus: Age=${ageHours}h ${ageMinutes}m$dstInfo',
    );

    if (isDataValid) {
      final expiryHours = timeToExpiry.inHours;
      final expiryMinutes = timeToExpiry.inMinutes % 60;
      Logger.debug('  Expires in: ${expiryHours}h ${expiryMinutes}m');
    } else {
      final expiredForHours = -timeToExpiry.inHours;
      final expiredForMinutes = -timeToExpiry.inMinutes % 60;
      Logger.debug('  Expired for: ${expiredForHours}h ${expiredForMinutes}m');
    }
  }
}
