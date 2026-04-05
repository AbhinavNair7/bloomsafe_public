import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// EnvConfig handles loading and accessing environment variables
/// with secure storage fallback for sensitive data
class EnvConfig {
  /// Factory constructor to return the singleton instance
  factory EnvConfig() => _instance;

  /// Private constructor for singleton pattern
  EnvConfig._internal();
  
  /// Singleton instance
  static final EnvConfig _instance = EnvConfig._internal();

  /// Secure storage for API keys
  final SecureStorage _secureStorage = SecureStorage();

  /// Environment variable keys
  static const String envAirnowApiKey = 'AIRNOW_API_KEY';
  static const String envDisableRateLimit = 'DISABLE_RATE_LIMIT';
  static const String envDiscordWebhookUrl = 'DISCORD_WEBHOOK_URL';
  static const String envSentryDsn = 'SENTRY_DSN';
  static const String envMockApi = 'MOCK_API';
  static const String envFirebaseAnalyticsEnabled = 'FIREBASE_ANALYTICS_ENABLED';

  /// Current environment file being used
  String _currentEnvFile = '.env.dev';

  /// Get the current environment file being used
  String get currentEnvFile => _currentEnvFile;

  /// Whether API calls should use mock responses
  bool _useMockApi = false;

  /// Returns whether to use mock API responses
  bool get useMockApi => _useMockApi;

  /// Sets whether to use mock API responses
  set useMockApi(bool value) {
    _useMockApi = value;
    dotenv.env[envMockApi] = value.toString();
  }

  /// Whether rate limiting should be disabled (for development only)
  bool get disableRateLimit =>
      dotenv.env[envDisableRateLimit]?.toLowerCase() == 'true';

  /// Returns the AirNow API key from environment variables
  String? get airnowApiKey => dotenv.env[envAirnowApiKey];

  /// Returns the Discord webhook URL from environment variables
  String? get discordWebhookUrl => dotenv.env[envDiscordWebhookUrl];

  /// Returns the Sentry DSN from environment variables
  String? get sentryDsn => dotenv.env[envSentryDsn];

  /// Returns whether Firebase Analytics is enabled
  bool get firebaseAnalyticsEnabled {
    final value = dotenv.env[envFirebaseAnalyticsEnabled];
    return value?.toLowerCase() == 'true';
  }

  /// Returns the maximum number of requests per hour (default: 500)
  int get maxRequestsPerHour =>
      int.tryParse(dotenv.env['MAX_REQUESTS_PER_HOUR'] ?? '') ?? 500;

  /// Returns the maximum number of requests per minute (default: 5)
  int get maxRequestsPerMinute =>
      int.tryParse(dotenv.env['MAX_REQUESTS_PER_MINUTE'] ?? '') ?? 5;

  /// Initializes the environment configuration
  Future<void> initialize({String? fileName}) async {
    final targetFile = fileName ?? _currentEnvFile;
    
    // Skip if already initialized with the same file
    if (_currentEnvFile == targetFile && dotenv.env.isNotEmpty) {
      Logger.debug('Environment already initialized with $targetFile');
      return;
    }

    _currentEnvFile = targetFile;
    
    // Load mock API setting from environment
    _loadConfigFromEnv();

    // Initialize secure storage and transfer sensitive keys
    try {
      await _secureStorage.initialize();
      await _transferSensitiveKeysToSecureStorage();
    } catch (e) {
      Logger.warning('Secure storage initialization error (non-critical): $e');
    }

    Logger.info('EnvConfig initialized with $_currentEnvFile');
  }

  /// Loads configuration from environment variables
  void _loadConfigFromEnv() {
    final mockApiValue = dotenv.env[envMockApi];
    _useMockApi = mockApiValue?.toLowerCase() == 'true';
  }

  /// Transfers sensitive keys from .env to secure storage
  Future<void> _transferSensitiveKeysToSecureStorage() async {
    final transfers = [
      _TransferConfig(envAirnowApiKey, _secureStorage.getApiKey, _secureStorage.setApiKey),
      _TransferConfig(envDiscordWebhookUrl, _secureStorage.getWebhookUrl, _secureStorage.setWebhookUrl),
      _TransferConfig(envSentryDsn, _secureStorage.getSentryDsn, _secureStorage.setSentryDsn),
    ];

    for (final transfer in transfers) {
      await _processKeyTransfer(transfer);
    }
  }

  /// Processes individual key transfer to secure storage
  Future<void> _processKeyTransfer(_TransferConfig config) async {
    final envValue = dotenv.env[config.envKey];
    if (envValue != null && envValue.isNotEmpty) {
      final storedValue = await config.getMethod();
      if (storedValue != envValue) {
        await config.setMethod(envValue);
      }
    }
  }

  /// Gets the API key securely with fallback to environment
  Future<String?> getSecureApiKey() async {
    return _getSecureValue(
      secureGet: _secureStorage.getApiKey,
      secureSet: _secureStorage.setApiKey,
      envGet: () => airnowApiKey,
      validator: _secureStorage.isValidApiKeyFormat,
    );
  }

  /// Gets the Sentry DSN securely with fallback to environment
  Future<String?> getSecureSentryDsn() async {
    return _getSecureValue(
      secureGet: _secureStorage.getSentryDsn,
      secureSet: _secureStorage.setSentryDsn,
      envGet: () => sentryDsn,
      validator: _secureStorage.isValidSentryDsn,
    );
  }

  /// Generic method to get secure values with environment fallback
  Future<String?> _getSecureValue({
    required Future<String?> Function() secureGet,
    required Future<bool> Function(String) secureSet,
    required String? Function() envGet,
    bool Function(String)? validator,
  }) async {
    try {
      // Try secure storage first
      String? value = await secureGet();

      // Fallback to environment variable
      if (value == null || value.isEmpty) {
        value = envGet();
        // Store in secure storage for next time
        if (value != null && value.isNotEmpty) {
          await secureSet(value);
        }
      }

      // Validate if validator provided
      if (value != null && validator != null && !validator(value)) {
        Logger.warning('Invalid format for secure value');
        return null;
      }

      return value;
    } catch (e) {
      Logger.error('Error retrieving secure value: $e');
      return null;
    }
  }
}

/// Configuration for transferring keys to secure storage
class _TransferConfig {
  const _TransferConfig(this.envKey, this.getMethod, this.setMethod);
  
  final String envKey;
  final Future<String?> Function() getMethod;
  final Future<bool> Function(String) setMethod;
}
