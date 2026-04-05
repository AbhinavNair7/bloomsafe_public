import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// A class to securely store keys and tokens using flutter_secure_storage
class SecureStorage {

  /// Factory constructor for singleton
  factory SecureStorage() => _instance;

  /// Private constructor for singleton
  SecureStorage._internal();

  /// Creates a testable instance with a custom storage implementation
  @visibleForTesting
  factory SecureStorage.forTesting(FlutterSecureStorage testStorage) {
    final storage = SecureStorage._internal();
    storage._secureStorage = testStorage;
    storage._initialized = true;
    return storage;
  }
  /// Singleton instance
  static SecureStorage _instance = SecureStorage._internal();

  /// Storage keys for secure values
  static const String _apiKeyKey = 'airnow_api_key';
  static const String _webhookUrlKey = 'discord_webhook_url';
  static const String _sentryDsnKey = 'sentry_dsn';

  /// Memory cache for different types of values
  final Map<String, String> _memoryCache = {};

  /// Indicates whether the storage is initialized
  bool _initialized = false;

  /// The secure storage instance
  late FlutterSecureStorage _secureStorage;

  /// Initialize the secure storage
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _secureStorage = FlutterSecureStorage(
        aOptions: _getAndroidOptions(),
        iOptions: _getIOSOptions(),
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('⚠️ Error initializing secure storage: $e');
      }
      _initialized = true;
    }
  }

  /// iOS options to prevent keychain issues
  IOSOptions _getIOSOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  /// Android options for maximum security
  AndroidOptions _getAndroidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  /// Generic method to read a value from secure storage
  /// Returns null if not found or error occurs
  Future<String?> _readValue(String key, String item) async {
    await initialize();

    try {
      final value = await _secureStorage.read(key: key);

      // Return the stored value if it exists
      if (value != null && value.isNotEmpty) {
        _memoryCache[key] = value;
        return value;
      }

      // Return from memory cache as fallback
      return _memoryCache[key];
    } catch (e) {
      if (kDebugMode) {
        Logger.error('⚠️ Error reading $item from secure storage: $e');
      }

      return _memoryCache[key];
    }
  }

  /// Generic method to store a value in secure storage
  /// Returns whether operation was successful
  Future<bool> _writeValue(String key, String value, String item) async {
    await initialize();

    try {
      await _secureStorage.write(key: key, value: value);
      _memoryCache[key] = value; // Update memory cache
      return true;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('⚠️ Error storing $item in secure storage: $e');
        Logger.warning('⚠️ Using memory storage as fallback.');
      }

      // At least store in memory if secure storage fails
      _memoryCache[key] = value;
      return true; // Still return true for non-critical error
    }
  }

  /// Generic method to delete a value from secure storage
  /// Returns whether operation was successful
  Future<bool> _deleteValue(String key, String item) async {
    await initialize();

    try {
      await _secureStorage.delete(key: key);
      _memoryCache.remove(key); // Clear memory cache
      return true;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('⚠️ Error deleting $item from secure storage: $e');
      }

      // At least clear memory cache
      _memoryCache.remove(key);
      return false;
    }
  }

  /// Get the AirNow API key from secure storage
  /// Returns null if not found or error occurs
  Future<String?> getApiKey() async {
    return _readValue(_apiKeyKey, 'API key');
  }

  /// Store the AirNow API key in secure storage
  /// Returns whether operation was successful
  Future<bool> setApiKey(String apiKey) async {
    return _writeValue(_apiKeyKey, apiKey, 'API key');
  }

  /// Delete the AirNow API key from secure storage
  /// Returns whether operation was successful
  Future<bool> deleteApiKey() async {
    return _deleteValue(_apiKeyKey, 'API key');
  }

  /// Get the Discord webhook URL from secure storage
  /// Returns null if not found or error occurs
  Future<String?> getWebhookUrl() async {
    return _readValue(_webhookUrlKey, 'webhook URL');
  }

  /// Store the Discord webhook URL in secure storage
  /// Returns whether operation was successful
  Future<bool> setWebhookUrl(String webhookUrl) async {
    return _writeValue(_webhookUrlKey, webhookUrl, 'webhook URL');
  }

  /// Delete the Discord webhook URL from secure storage
  /// Returns whether operation was successful
  Future<bool> deleteWebhookUrl() async {
    return _deleteValue(_webhookUrlKey, 'webhook URL');
  }

  /// Gets the Sentry DSN from secure storage
  /// Returns null if not found
  Future<String?> getSentryDsn() async {
    return _readValue(_sentryDsnKey, 'Sentry DSN');
  }

  /// Sets the Sentry DSN in secure storage
  /// Returns true if successful
  Future<bool> setSentryDsn(String sentryDsn) async {
    return _writeValue(_sentryDsnKey, sentryDsn, 'Sentry DSN');
  }

  /// Validation methods - grouped together for better code organization

  /// Validate API key format
  bool isValidApiKeyFormat(String apiKey) {
    if (apiKey.isEmpty) return false;

    // For UUID format validation
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    return uuidRegExp.hasMatch(apiKey);
  }

  /// Validate webhook URL format
  bool isValidWebhookUrl(String webhookUrl) {
    if (webhookUrl.isEmpty) return false;

    // Check for Discord webhook URL pattern
    final discordWebhookRegExp = RegExp(
      r'^https://discord\.com/api/webhooks/\d+/[\w-]+$',
    );

    return discordWebhookRegExp.hasMatch(webhookUrl);
  }

  /// Validates a Sentry DSN format
  /// Sentry DSNs have the format: https://PUBLIC_KEY@HOST/PROJECT_ID
  bool isValidSentryDsn(String sentryDsn) {
    if (sentryDsn.isEmpty) return false;

    // Basic validation pattern
    final pattern = RegExp(
      r'^https://[a-zA-Z0-9]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/\d+$',
    );
    return pattern.hasMatch(sentryDsn);
  }

  /// Static method to globally override storage implementation for testing
  @visibleForTesting
  static void overrideForTesting(FlutterSecureStorage mockStorage) {
    final storage = SecureStorage._internal();
    storage._secureStorage = mockStorage;
    storage._initialized = true;
    _instance = storage;
  }
}
