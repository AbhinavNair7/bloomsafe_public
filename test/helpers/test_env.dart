import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/config/env_config.dart';

/// Utility class to help manage test environments
class TestEnv {

  /// Factory constructor returns the singleton instance
  factory TestEnv() => _instance;

  /// Private constructor for singleton
  TestEnv._internal();
  /// Singleton instance
  static final TestEnv _instance = TestEnv._internal();

  /// Flag to track if environment has been initialized
  bool _initialized = false;

  /// Initializes the test environment
  /// [useRealApi] - Whether to use the real API or mock API
  /// [useTestEnvFile] - Whether to use .env.test instead of .env
  Future<bool> initialize({
    bool useRealApi = false,
    bool useTestEnvFile = true,
  }) async {
    if (_initialized) {
      return true;
    }

    try {
      // Check for test env file
      final envFilePath = useTestEnvFile ? '.env.test' : '.env';
      final envFile = File(envFilePath);

      // If test env file doesn't exist, create it
      if (!await envFile.exists() && useTestEnvFile) {
        await _createTestEnvFile();
      }

      // Initialize environment with the appropriate file
      await EnvConfig().initialize(fileName: envFilePath);

      // Setup app config
      final appConfig = AppConfig();
      await appConfig.initialize();

      // Set API mode
      if (useRealApi) {
        final bool success = appConfig.useRealApiMode();
        if (!success) {
          debugPrint('❌ Could not use real API - missing or invalid API key');
          return false;
        }
      } else {
        appConfig.useMockApiMode();
      }

      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('❌ Test environment initialization failed: $e');
      return false;
    }
  }

  /// Creates a test environment file
  Future<void> _createTestEnvFile() async {
    // Check if .env exists to copy from
    final mainEnvFile = File('.env');

    if (await mainEnvFile.exists()) {
      // Create .env.test based on .env but with MOCK_API=true
      final envContent = await mainEnvFile.readAsString();
      final envLines = const LineSplitter().convert(envContent).toList();

      // Update MOCK_API line or add it
      bool foundMockApi = false;
      for (int i = 0; i < envLines.length; i++) {
        if (envLines[i].startsWith('MOCK_API=')) {
          envLines[i] = 'MOCK_API=true';
          foundMockApi = true;
          break;
        }
      }

      if (!foundMockApi) {
        envLines.add('MOCK_API=true');
      }

      // Add test specific comments
      envLines.add('');
      envLines.add('# Auto-generated test env file');
      envLines.add(
        '# This file is used for testing and should not be committed',
      );

      await File('.env.test').writeAsString(envLines.join('\n'));
      debugPrint('✅ Created test environment file from .env');
    } else {
      // Create a default test env file
      await File('.env.test').writeAsString('''
# Test environment configuration
AIRNOW_API_KEY=test_key_for_testing
MOCK_API=true
MAX_REQUESTS_PER_MINUTE=5
MAX_REQUESTS_PER_HOUR=500

# Auto-generated test env file
# This file is used for testing and should not be committed
''');
      debugPrint('✅ Created default test environment file');
    }
  }

  /// Switches between mock and real API modes for testing
  /// Returns true if successful, false if API key is missing or invalid
  Future<bool> useRealApi() async {
    if (!_initialized) {
      return await initialize(useRealApi: true);
    }

    final appConfig = AppConfig();
    return appConfig.useRealApiMode();
  }

  /// Switches to mock API mode for testing
  void useMockApi() {
    if (!_initialized) {
      initialize(useRealApi: false);
      return;
    }

    final appConfig = AppConfig();
    appConfig.useMockApiMode();
  }

  /// Validates the API key to check if it's usable
  Future<bool> validateApiKey() async {
    if (!_initialized) {
      await initialize();
    }

    final envConfig = EnvConfig();
    final apiKey = envConfig.airnowApiKey;
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'your_airnow_api_key_here') {
      return false;
    }

    // Basic format validation (AirNow API keys are typically UUID format)
    final uuidPattern = RegExp(
      r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$',
      caseSensitive: false,
    );

    return uuidPattern.hasMatch(apiKey);
  }
}

/// Extension on AppConfig to provide test-specific functionality
extension AppConfigTestHelpers on AppConfig {
  /// Sets up API mode for testing
  /// Returns true if real API mode was successfully enabled
  /// Returns false if mock API mode was used (due to missing/invalid API key)
  Future<bool> setupTestMode({bool useRealApi = false}) async {
    if (useRealApi) {
      return useRealApiMode();
    } else {
      useMockApiMode();
      return false;
    }
  }
}
