import 'package:shared_preferences/shared_preferences.dart';

/// Sets up mock SharedPreferences for testing
void setupSharedPreferencesMock() {
  // Set up SharedPreferences mock with empty values
  SharedPreferences.setMockInitialValues({});
}

/// Sets up mock SharedPreferences with specific initial values for testing
void setupSharedPreferencesMockWithValues(Map<String, Object> initialValues) {
  SharedPreferences.setMockInitialValues(initialValues);
}
