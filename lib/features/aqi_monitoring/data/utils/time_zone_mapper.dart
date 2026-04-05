library;

import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/core/utils/logger.dart';

/// Utility library for mapping time zone abbreviations to IANA timezone identifiers
/// and handling timezone-aware date conversions.
///
/// This provides conversion from AirNow API's timezone abbreviations to standard IANA
/// timezone identifiers which properly handle DST transitions.

/// Maps US timezone abbreviations to their IANA identifiers
/// These IANA timezones handle Daylight Saving Time automatically
const Map<String, String> timeZoneAbbreviationMap = {
  // US mainland timezones
  'EST': 'America/New_York',
  'EDT': 'America/New_York',
  'CST': 'America/Chicago',
  'CDT': 'America/Chicago',
  'MST': 'America/Denver',
  'MDT': 'America/Denver',
  'PST': 'America/Los_Angeles',
  'PDT': 'America/Los_Angeles',

  // US non-contiguous timezones
  'AKST': 'America/Anchorage',
  'AKDT': 'America/Anchorage',
  'HST': 'Pacific/Honolulu',
  'AST': 'America/Puerto_Rico',

  // Canadian timezones
  'NST': 'America/St_Johns',
  'NDT': 'America/St_Johns',
  'AT': 'America/Halifax',
  'ADT': 'America/Halifax',
  'ET': 'America/Toronto',
  'CT': 'America/Winnipeg',
  'MT': 'America/Edmonton',
  'PT': 'America/Vancouver',
};

/// Converts a timezone abbreviation to a TZ database identifier
///
/// Parameters:
/// - [abbreviation]: The timezone abbreviation (e.g., "EST", "PST")
///
/// Returns the corresponding IANA timezone, falling back to 'UTC' if not found
String getIanaTimeZone(String? abbreviation) {
  if (abbreviation == null || abbreviation.isEmpty) {
    return 'UTC';
  }

  // Clean abbreviation by removing whitespace and normalizing to uppercase
  final cleanAbbreviation = abbreviation.trim().toUpperCase();

  // Return the mapped timezone or UTC if not found
  return timeZoneAbbreviationMap[cleanAbbreviation] ?? 'UTC';
}

/// Gets a timezone location object from a timezone abbreviation
///
/// Parameters:
/// - [abbreviation]: The timezone abbreviation (e.g., "EST", "PST")
///
/// Returns the corresponding tz.Location object
tz.Location getTimeZoneLocation(String? abbreviation) {
  final ianaTimeZone = getIanaTimeZone(abbreviation);
  return tz.getLocation(ianaTimeZone);
}

/// Parses a date string into a DateTime object
///
/// Parameters:
/// - [dateString]: The date string to parse
/// - [hour]: Optional hour to use (0-23)
///
/// Returns a DateTime object or null if parsing fails
DateTime? parseDateString(String dateString, {int hour = 0}) {
  try {
    // Handle full ISO format with time component
    if (dateString.contains('T')) {
      try {
        // Parse the full ISO string directly
        return DateTime.parse(dateString);
      } catch (_) {
        // If full parsing fails, extract just the date part and continue
        final datePart = dateString.split('T')[0];
        return _parseDateOnly(datePart, hour);
      }
    }

    // Handle date-only formats
    return _parseDateOnly(dateString, hour);
  } catch (e) {
    Logger.debug('Error parsing date: $e');
    return null;
  }
}

/// Internal helper to parse date-only strings
DateTime? _parseDateOnly(String dateString, int hour) {
  if (dateString.contains('-')) {
    // ISO format: YYYY-MM-DD
    final parts = dateString.split('-');
    if (parts.length == 3 && parts[0].length == 4) {
      return DateTime(
        int.parse(parts[0]), // year
        int.parse(parts[1]), // month
        int.parse(parts[2]), // day
        hour,
      );
    }
  } else if (dateString.contains('/')) {
    // US format: MM/DD/YYYY
    final parts = dateString.split('/');
    if (parts.length == 3 && parts[2].length == 4) {
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[0]), // month
        int.parse(parts[1]), // day
        hour,
      );
    }
  }

  // If we got here, the format wasn't recognized
  return null;
}

/// Creates a timezone-aware DateTime from date components and timezone
///
/// Parameters:
/// - [dateObserved]: The date string in various formats (ISO, MM/DD/YYYY)
/// - [hourObserved]: The hour of observation (0-23)
/// - [localTimeZone]: The timezone abbreviation
///
/// Returns a timezone-aware DateTime (TZDateTime)
tz.TZDateTime createTimeZoneAwareDateTime({
  required String dateObserved,
  required int hourObserved,
  String? localTimeZone,
}) {
  // Get the appropriate timezone
  final tzLocation = getTimeZoneLocation(localTimeZone);

  // Parse the date string to a standard DateTime
  final dateTime = parseDateString(dateObserved, hour: hourObserved);

  if (dateTime != null) {
    // Create a timezone-aware DateTime directly in the target timezone
    return tz.TZDateTime(
      tzLocation,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      hourObserved,
      0, // minutes
      0, // seconds
    );
  } else {
    // Fallback to current time in the target timezone
    Logger.debug(
      'Using current time as fallback for invalid date: $dateObserved',
    );
    return tz.TZDateTime.now(tzLocation);
  }
}

/// Combines date, hour, and timezone into a timezone-aware DateTime
///
/// Parameters:
/// - [dateObserved]: The date string in various formats (ISO, MM/DD/YYYY)
/// - [hourObserved]: The hour of observation (0-23)
/// - [localTimeZone]: The timezone abbreviation
///
/// Returns a timezone-aware DateTime (TZDateTime)
tz.TZDateTime createObservationDateTime({
  required String dateObserved,
  required int hourObserved,
  String? localTimeZone,
}) {
  return createTimeZoneAwareDateTime(
    dateObserved: dateObserved,
    hourObserved: hourObserved,
    localTimeZone: localTimeZone,
  );
}

/// Gets the current time in a specific timezone
///
/// Parameters:
/// - [location]: The timezone location
///
/// Returns the current time in the specified timezone
tz.TZDateTime getCurrentTimeInZone(tz.Location location) {
  return tz.TZDateTime.now(location);
}

/// Adds hours to a timezone-aware DateTime
///
/// Parameters:
/// - [dateTime]: The base timezone-aware DateTime
/// - [hours]: The number of hours to add
///
/// Returns a new timezone-aware DateTime with the hours added
tz.TZDateTime addHours(tz.TZDateTime dateTime, int hours) {
  return dateTime.add(Duration(hours: hours));
}

/// Adds a duration to a timezone-aware DateTime
///
/// Parameters:
/// - [dateTime]: The base timezone-aware DateTime
/// - [duration]: The duration to add
///
/// Returns a new timezone-aware DateTime with the duration added
tz.TZDateTime addDuration(tz.TZDateTime dateTime, Duration duration) {
  return dateTime.add(duration);
}

/// Calculate expiry time by adding hours to a date
///
/// Parameters:
/// - [dateTime]: The base timezone-aware DateTime
/// - [expiryHours]: Number of hours until expiry
///
/// Returns a new datetime representing when the data expires
tz.TZDateTime calculateExpiryTime(
  tz.TZDateTime dateTime, {
  int expiryHours = 2,
}) {
  return addHours(dateTime, expiryHours);
}

/// Normalizes a standard DateTime to a specific timezone
///
/// Parameters:
/// - [dateTime]: The standard DateTime to normalize
/// - [tzAbbreviation]: The timezone abbreviation (e.g., "EST", "PST")
///
/// Returns a timezone-aware DateTime in the specified timezone
tz.TZDateTime normalizeToTimeZone(DateTime dateTime, String tzAbbreviation) {
  final location = getTimeZoneLocation(tzAbbreviation);
  return tz.TZDateTime.from(dateTime, location);
}
