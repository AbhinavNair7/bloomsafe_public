import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_test/flutter_test.dart';

/// Initializes timezone data for tests that depend on timezone functionality
void initializeTimeZonesForTest() {
  // Only initialize once to avoid multiple initialization errors
  try {
    tz_data.initializeTimeZones();
  } catch (e) {
    // If timezone data is already initialized, this will throw an error
    // We can safely ignore this and continue
    // print('Timezone data already initialized: ${e.toString()}');
  }
}

/// Utility function to set up a test group with timezone initialization
///
/// Use this helper for any test group that depends on timezone functionality
void setupTimezoneTests({
  required void Function() testFunction,
  void Function()? beforeSetup,
  void Function()? afterTearDown,
}) {
  setUpAll(() {
    if (beforeSetup != null) {
      beforeSetup();
    }
    initializeTimeZonesForTest();
  });

  testFunction();

  tearDownAll(() {
    if (afterTearDown != null) {
      afterTearDown();
    }
  });
}
