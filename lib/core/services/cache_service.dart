import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Private class for cache items with metadata
@visibleForTesting
class CachedItem<T> {

  CachedItem({required this.data, required this.expiresAt, DateTime? timestamp})
    : timestamp = timestamp ?? CacheService.getCurrentTime();

  /// Factory constructor to create a cached item from JSON
  factory CachedItem.fromJson(
    Map<String, dynamic> json,
    T Function(Object?)? fromJsonData,
  ) {
    final data =
        fromJsonData != null ? fromJsonData(json['data']) : json['data'] as T;

    return CachedItem<T>(
      data: data,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
  final T data;
  final DateTime timestamp;
  final DateTime expiresAt;

  /// Converts the cached item to a JSON map
  Map<String, dynamic> toJson(Object? Function(T)? toJsonData) {
    return {
      'timestamp': timestamp.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'data': toJsonData != null ? toJsonData(data) : data,
    };
  }
}

/// Generic cache service for managing cached data with expiration
class CacheService<T> {

  /// Creates a new CacheService with optional automatic cleanup
  ///
  /// If [persistEnabled] is true, cache will be saved to SharedPreferences
  /// [toJsonData] and [fromJsonData] are required for persistence of complex objects
  CacheService({
    bool enableAutomaticCleanup = true,
    bool persistEnabled = true,
    bool isTestMode = false,
    String storageKeyPrefix = 'cache_',
    Object? Function(T)? toJsonData,
    T Function(Object?)? fromJsonData,
  }) : _persistEnabled = persistEnabled,
       _storageKeyPrefix = storageKeyPrefix,
       _toJsonData = toJsonData,
       _fromJsonData = fromJsonData,
       _isTestMode = isTestMode {
    if (enableAutomaticCleanup) {
      _startCleanupTimer();
    }

    // Initialize persistence if enabled and not in test mode
    if (persistEnabled && !isTestMode) {
      _initPersistence();
    }
  }
  /// In-memory cache storage
  final Map<String, CachedItem<T>> _cache = {};

  /// Shared preferences instance for persistent storage
  SharedPreferences? _prefs;

  /// Key prefix for shared preferences storage
  final String _storageKeyPrefix;

  /// When true, cache will be persisted to disk
  final bool _persistEnabled;

  /// Functions to convert data to/from JSON for persistence
  final Object? Function(T)? _toJsonData;
  final T Function(Object?)? _fromJsonData;

  /// When true, this is a test instance that won't try to use SharedPreferences
  final bool _isTestMode;

  /// Timer for periodic cache cleanup
  Timer? _cleanupTimer;

  /// Mock current time for testing
  static DateTime? _mockTime;

  /// Creates a test instance of CacheService with mocked features
  @visibleForTesting
  static CacheService<T> forTesting<T>() {
    return CacheService<T>(persistEnabled: false, isTestMode: true);
  }

  /// Set a mock time for testing purposes
  @visibleForTesting
  static void setMockTimeForTesting(DateTime? mockTime) {
    _mockTime = mockTime;
  }

  /// Get the current time, using mock time if set for testing
  static DateTime getCurrentTime() {
    return _mockTime ?? DateTime.now();
  }

  /// Initializes persistence and loads cached data from disk
  Future<void> _initPersistence() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadFromDisk();
    } catch (e) {
      Logger.error('Error initializing cache persistence: $e');
    }
  }

  /// Loads cached data from disk
  Future<void> _loadFromDisk() async {
    if (_prefs == null || !_persistEnabled || _isTestMode) return;

    try {
      // Find all keys with our prefix
      final allKeys = _prefs!.getKeys();
      final cacheKeys = allKeys.where((k) => k.startsWith(_storageKeyPrefix));

      // Load each cached item
      for (final prefKey in cacheKeys) {
        try {
          final jsonStr = _prefs!.getString(prefKey);
          if (jsonStr != null) {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            final key = prefKey.substring(_storageKeyPrefix.length);

            // Skip entries without proper conversion functions for complex objects
            if (_fromJsonData == null && json['data'] is! T) {
              continue;
            }

            final item = CachedItem<T>.fromJson(json, _fromJsonData);

            // Only restore valid items
            if (_isValidByTimestamp(item)) {
              _cache[key] = item;
            } else {
              // Remove expired items from storage
              await _prefs!.remove(prefKey);
            }
          }
        } catch (e) {
          Logger.error('Error loading cached item: $e');
          // Skip this item if there was an error
        }
      }

      Logger.debug('Loaded ${_cache.length} items from persistent cache');
    } catch (e) {
      Logger.error('Error loading cache from disk: $e');
    }
  }

  /// Saves the cache to disk
  Future<void> _saveToDisk(String key, CachedItem<T> item) async {
    if (_prefs == null || !_persistEnabled || _isTestMode) return;

    try {
      // For complex objects, we need toJsonData function
      if (_toJsonData == null &&
          item.data is! num &&
          item.data is! String &&
          item.data is! bool &&
          item.data is! List<dynamic> &&
          item.data is! Map<String, dynamic>) {
        Logger.warning(
          'Cannot persist complex object without toJsonData function',
        );
        return;
      }

      final json = item.toJson(_toJsonData);
      final jsonStr = jsonEncode(json);

      await _prefs!.setString('$_storageKeyPrefix$key', jsonStr);
    } catch (e) {
      Logger.error('Error saving cache item to disk: $e');
    }
  }

  /// Removes an item from disk
  Future<void> _removeFromDisk(String key) async {
    if (_prefs == null || !_persistEnabled || _isTestMode) return;

    try {
      await _prefs!.remove('$_storageKeyPrefix$key');
    } catch (e) {
      Logger.error('Error removing cache item from disk: $e');
    }
  }

  /// Starts a periodic timer to clean up expired cache entries
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      purgeExpiredEntries();
    });
  }

  /// Stops the cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Retrieves cached data for a key if it's not expired
  Future<T?> get(String key, {bool Function(T data)? isValid}) async {
    final cachedItem = _cache[key];
    if (cachedItem == null) return null;

    // Check if data is valid based on timestamp first
    final validByTimestamp = _isValidByTimestamp(cachedItem);

    // If timestamp is invalid and no custom validator is provided, return null
    if (!validByTimestamp && isValid == null) {
      _cache.remove(key);
      await _removeFromDisk(key);
      return null;
    }

    // If custom validator is provided, use it regardless of timestamp
    // This allows overriding timestamp validation
    final validByCustomCheck =
        isValid != null ? isValid(cachedItem.data) : true;

    // Item is considered valid if either timestamp is valid or custom check passes
    final isItemValid = validByTimestamp || validByCustomCheck;

    if (!isItemValid) {
      // Item is invalid by both timestamp and custom checks, remove it
      _cache.remove(key);
      await _removeFromDisk(key);
      return null;
    }

    // Run automatic cleanup for other items
    _validateCache(isValid);

    return cachedItem.data;
  }

  /// Stores data in the cache with an optional explicit expiration time
  Future<void> set(
    String key,
    T data, {
    DateTime? expiresAt,
    Duration? expiresAfter,
    bool Function(T data)? isValid,
  }) async {
    // Automatic cleanup before setting new data
    _validateCache(isValid);

    // Calculate expiration time
    final DateTime expiration;
    if (expiresAt != null) {
      expiration = expiresAt;
    } else if (expiresAfter != null) {
      expiration = getCurrentTime().add(expiresAfter);
    } else {
      // Default to 2 hours
      expiration = getCurrentTime().add(const Duration(hours: 2));
    }

    // Check if data is already valid
    final shouldCache = isValid != null ? isValid(data) : true;

    if (shouldCache) {
      final item = CachedItem<T>(data: data, expiresAt: expiration);
      _cache[key] = item;

      // Save to disk if persistence is enabled
      if (_persistEnabled && !_isTestMode) {
        await _saveToDisk(key, item);
      }
    } else {
      Logger.warning('Refused to cache invalid data for key: $key');
    }
  }

  /// Checks if cached data is still valid based on timestamp
  bool _isValidByTimestamp(CachedItem<T> item) {
    // Compare using isBefore to ensure exact timestamp matches are considered expired
    // This handles edge cases where the expiry time exactly matches the current time
    return getCurrentTime().isBefore(item.expiresAt);
  }

  /// Removes all expired entries from the cache
  void _validateCache(bool Function(T data)? isValid) {
    final expiredKeys = <String>[];

    // Find all expired entries
    for (final entry in _cache.entries) {
      final timestampValid = _isValidByTimestamp(entry.value);
      final customValid = isValid != null ? isValid(entry.value.data) : true;

      if (!timestampValid || !customValid) {
        expiredKeys.add(entry.key);
      }
    }

    // Remove expired entries
    for (final key in expiredKeys) {
      _cache.remove(key);
      _removeFromDisk(key);
    }

    // Log cache cleanup
    if (expiredKeys.isNotEmpty) {
      Logger.debug('Auto-purged ${expiredKeys.length} expired cache entries');
    }
  }

  /// Removes all expired entries from the cache - public method
  void purgeExpiredEntries({bool Function(T data)? isValid}) {
    _validateCache(isValid);
  }

  /// Gets the current size of the cache
  int get size => _cache.length;

  /// Clears the entire cache
  Future<void> clear() async {
    _cache.clear();

    // Clear persistent storage
    if (_prefs != null && _persistEnabled && !_isTestMode) {
      final allKeys = _prefs!.getKeys();
      final cacheKeys = allKeys.where((k) => k.startsWith(_storageKeyPrefix));

      for (final key in cacheKeys) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Gets a fallback item that might be expired but not too old
  /// Useful for providing stale data when fresh data is unavailable
  Future<T?> getFallback(
    String key, {
    required Duration maxAge,
    bool Function(T data)? isStillUsable,
  }) async {
    final cachedItem = _cache[key];
    if (cachedItem == null) return null;

    // Calculate the age of the data based on its timestamp
    final age = getCurrentTime().difference(cachedItem.timestamp);

    // Check if the item is not too old based on maxAge
    if (age > maxAge) {
      if (kDebugMode) {
        Logger.debug(
          'Cache too old for fallback: $key (age: ${age.inHours}h ${age.inMinutes % 60}m)',
        );
      }
      return null;
    }

    // Check custom validation if provided
    if (isStillUsable != null && !isStillUsable(cachedItem.data)) {
      if (kDebugMode) {
        Logger.debug('Cache marked as not usable by custom validator: $key');
      }
      return null;
    }

    // Item is within maxAge and passes the custom validator (if provided)
    if (kDebugMode) {
      Logger.debug(
        'Using fallback cache for key: $key (age: ${age.inHours}h ${age.inMinutes % 60}m)',
      );
    }
    return cachedItem.data;
  }

  /// Allows access to internal cache for advanced operations
  /// Should be used carefully and only for special cases
  Map<String, CachedItem<T>> get internalCache => _cache;
}
