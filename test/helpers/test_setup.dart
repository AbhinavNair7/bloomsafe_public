import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bloomsafe/core/config/secure_storage.dart';
import 'secure_storage_mock.dart';
import 'shared_prefs_mock.dart';

/// Initialize test environment with mocks for platform channels
void initializeTestEnvironment() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Replace the secure storage with our mock implementation globally
  SecureStorage.overrideForTesting(MockSecureStorage());

  // Set up SharedPreferences mock with empty values
  setupSharedPreferencesMock();

  // Set up test environment variables
  _setupTestEnv();
}

/// Use this in test files to ensure test environment is initialized
/// Example: setUpAll(setupTestEnvironment);
void setupTestEnvironment() {
  initializeTestEnvironment();
}

/// Sets up test environment variables for code that uses dotenv directly
void _setupTestEnv() {
  try {
    // Try to load actual test env file
    dotenv.testLoad(
      fileInput: '''
      # This is loaded if .env.test isn't available
      ''',
    );

    // Try to load the real env file if it exists
    dotenv.load(fileName: '.env.test').catchError((_) {
      // Fail silently - we already have defaults
    });
  } catch (_) {
    // If that fails, load minimal default values
    dotenv.testLoad(
      fileInput: '''
        AIRNOW_API_KEY=test_key_123
        MAX_REQUESTS_PER_MINUTE=30
        MOCK_API=true
        FIREBASE_ANALYTICS_ENABLED=false
        SENTRY_DSN=https://00000000000000000000000000000000@test.ingest.sentry.io/0000000
      ''',
    );
  }
}

/// Determine if this environment supports running integration tests
/// with platform plugins (shared preferences, secure storage, etc)
bool canRunIntegrationTests() {
  try {
    // Try operations that would fail if plugins aren't supported
    final secureStorage = const FlutterSecureStorage();
    return true;
  } catch (e) {
    if (e.toString().contains('MissingPluginException')) {
      print(
        '⚠️ Platform does not support required plugins for integration tests',
      );
      return false;
    }
    return true;
  }
}
