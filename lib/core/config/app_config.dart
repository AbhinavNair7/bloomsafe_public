import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Centralized application configuration
/// Handles environment variables and application modes
class AppConfig {

  /// Factory constructor to return the singleton instance
  factory AppConfig() => _instance;

  /// Private constructor for singleton pattern
  AppConfig._internal();
  /// Singleton instance
  static final AppConfig _instance = AppConfig._internal();

  /// Environment configuration
  final EnvConfig _envConfig = EnvConfig();

  /// Secure storage for API keys
  final SecureStorage _secureStorage = SecureStorage();

  /// Whether to use mock API responses instead of real API calls
  bool get useMockApi => _envConfig.useMockApi;

  /// Gets the API key from environment variables with fallback to secure storage
  String? get apiKey => _envConfig.airnowApiKey;

  /// Gets the maximum number of requests per hour (AirNow limit: 500)
  int get maxRequestsPerHour => _envConfig.maxRequestsPerHour;

  /// Gets the maximum number of requests per minute (Client-side limit: 5)
  int get maxRequestsPerMinute => _envConfig.maxRequestsPerMinute;

  /// Initializes the application configuration
  Future<void> initialize() async {
    // No initialization needed as environment is loaded elsewhere
  }

  /// Gets the API key securely with fallbacks
  Future<String?> getSecureApiKey() async {
    return await _envConfig.getSecureApiKey();
  }

  /// Sets the API key securely in secure storage
  Future<bool> setApiKey(String apiKey) async {
    return await _secureStorage.setApiKey(apiKey);
  }

  /// Toggles between mock API and real API
  /// Returns the new state (true = using mock API)
  bool toggleMockApi() {
    _envConfig.useMockApi = !_envConfig.useMockApi;
    Logger.info('API Mode changed: ${useMockApi ? "MOCK" : "REAL"}');
    return useMockApi;
  }

  /// Forces the use of mock API
  void useMockApiMode() {
    if (!_envConfig.useMockApi) {
      _envConfig.useMockApi = true;
      Logger.info('API Mode set to: MOCK');
    }
  }

  /// Forces the use of real API
  /// Returns false if API key is missing
  bool useRealApiMode() {
    // Check if API key is available
    if (apiKey == null || apiKey!.isEmpty) {
      Logger.warning('Cannot use real API: API key is missing');
      return false;
    }

    if (_envConfig.useMockApi) {
      _envConfig.useMockApi = false;
      Logger.info('API Mode set to: REAL');
    }
    return true;
  }

  /// Forces the use of real API with secure key retrieval
  Future<bool> useRealApiModeSecure() async {
    // Get API key from secure storage with fallback
    final secureApiKey = await getSecureApiKey();

    // Check if we have a valid API key
    if (secureApiKey == null || secureApiKey.isEmpty) {
      Logger.warning('Cannot use real API: No valid API key found');
      return false;
    }

    // Switch to real API mode
    if (_envConfig.useMockApi) {
      _envConfig.useMockApi = false;
      Logger.info('API Mode set to: REAL (using secure key)');
    }
    return true;
  }
}
