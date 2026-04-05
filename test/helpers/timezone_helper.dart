import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Initialize timezone data for tests
void initializeTimeZonesForTest() {
  tz.initializeTimeZones();
}

/// Set up common timezone test utilities
void setupTimezoneTests({String mockTzLocation = 'America/New_York'}) {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation(mockTzLocation));
}

/// Create a fixed TZDateTime for testing
tz.TZDateTime createTestTZDateTime(
  String location,
  int year,
  int month,
  int day, {
  int hour = 0,
  int minute = 0,
  int second = 0,
}) {
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

/// Get the current timezone offset as a string
String getCurrentTimezoneOffset() {
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final offsetHours = offset.inHours;
  final offsetMinutes = offset.inMinutes % 60;
  final sign = offset.isNegative ? '-' : '+';
  return '$sign${offsetHours.abs().toString().padLeft(2, '0')}:${offsetMinutes.abs().toString().padLeft(2, '0')}';
}

/// Convert UTC date to local timezone
DateTime convertUtcToLocal(DateTime utcDate) {
  return utcDate.toLocal();
}

/// Format date for standardized test output
String formatTestDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
