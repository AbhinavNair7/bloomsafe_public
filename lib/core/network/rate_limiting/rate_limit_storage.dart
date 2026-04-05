import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Keys for shared preferences storage
const String _lockoutTimestampKey = 'rate_limiter_lockout_timestamp';
const String _lockoutTypeKey = 'rate_limiter_lockout_type';
const String _requestsThisMinuteKey = 'rate_limiter_requests_this_minute';
const String _lastMinuteResetKey = 'rate_limiter_last_minute_reset';

/// Interface for rate limit state persistence
abstract class RateLimitStorage {
  /// Saves the lockout state for a specific rate limit type
  Future<void> saveLockoutState(RateLimitType type, bool isInLockout);

  /// Loads the lockout state for a specific rate limit type
  Future<bool> loadLockoutState(RateLimitType type);

  /// Saves the request count for a specific rate limit type
  Future<void> saveRequestCount(RateLimitType type, int count);

  /// Loads the request count for a specific rate limit type
  Future<int> loadRequestCount(RateLimitType type);

  /// Saves the timestamp when the request count was last reset
  Future<void> saveLastResetTime(RateLimitType type, DateTime time);

  /// Loads the timestamp when the request count was last reset
  Future<DateTime?> loadLastResetTime(RateLimitType type);

  /// Clears all stored rate limit data
  Future<void> clearStorage();
}

/// Implementation of RateLimitStorage using SecureStorage
class SecureStorageRateLimitStorage implements RateLimitStorage {

  /// Creates a new SecureStorageRateLimitStorage
  SecureStorageRateLimitStorage() {
    _init();
  }
  static const String _lockoutPrefix = 'rate_limit_lockout_';
  static const String _countPrefix = 'rate_limit_count_';
  static const String _timestampPrefix = 'rate_limit_timestamp_';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _initialized = false;

  Future<void> _init() async {
    try {
      // Handle stale lockouts after initialization
      await _validateStoredLockouts();

      _initialized = true;
      Logger.debug('RateLimitStorage: SecureStorage initialized');
    } catch (e) {
      Logger.error('RateLimitStorage: Error initializing SecureStorage: $e');
    }
  }

  /// Check for and clear any stale lockouts (e.g., from a previous session)
  ///
  /// This safety mechanism prevents permanent lockouts if the app crashed during a lockout period.
  /// It only runs at app startup and only clears lockouts that are significantly older than their
  /// intended duration (e.g., 15+ minutes for a 10-minute lockout).
  ///
  /// This does NOT affect the normal lockout experience - users will still experience the
  /// exact lockout duration specified in the documentation during normal app usage.
  Future<void> _validateStoredLockouts() async {
    try {
      // We need to read all keys first
      final allValues = await _storage.readAll();
      final lockoutKeys = allValues.keys.where(
        (key) => key.startsWith(_lockoutPrefix),
      );

      for (final lockoutKey in lockoutKeys) {
        final isLocked = allValues[lockoutKey] == 'true';

        if (isLocked) {
          // Extract the type from the key
          final typeStr = lockoutKey.substring(_lockoutPrefix.length);
          final type = RateLimitType.values.firstWhere(
            (t) => t.toString() == typeStr,
            orElse: () => RateLimitType.clientSide,
          );

          final timestampKey = _getKey(_timestampPrefix, type);
          final timestampStr = allValues[timestampKey];

          if (timestampStr != null) {
            try {
              final lockoutTime = DateTime.parse(timestampStr);
              final now = DateTime.now();

              // Calculate elapsed time since lockout started
              final elapsedTime = now.difference(lockoutTime);

              // Determine if this is a stale lockout based on the strategy type
              final isStale = _isLockoutStale(type, elapsedTime);

              if (isStale) {
                Logger.warning(
                  'RateLimitStorage: Found stale lockout of type $type, clearing...',
                );

                // Clear the lockout state
                await _storage.write(key: lockoutKey, value: 'false');

                // Ensure the count is reset
                final countKey = _getKey(_countPrefix, type);
                await _storage.write(key: countKey, value: '0');
              }
            } catch (e) {
              // If timestamp is invalid, clear the lockout
              await _storage.write(key: lockoutKey, value: 'false');
            }
          } else {
            // No timestamp, so clear the lockout
            await _storage.write(key: lockoutKey, value: 'false');
          }
        }
      }
    } catch (e) {
      Logger.error('RateLimitStorage: Error validating lockouts: $e');
    }
  }

  /// Determine if a lockout is stale based on the strategy type
  ///
  /// This adds a safety buffer to lockout durations to handle edge cases:
  /// - For a 10-minute client-side lockout, we consider it stale after 15 minutes
  ///
  /// This safety buffer only applies when checking lockouts at app startup and
  /// prevents permanent lockouts if the app crashed during an active lockout.
  bool _isLockoutStale(RateLimitType type, Duration elapsed) {
    // Use a consistent 15-minute buffer for the client-side strategy
    const maxDuration = Duration(minutes: 15);

    // Is this lockout significantly older than the expected duration?
    return elapsed > maxDuration;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  String _getKey(String prefix, RateLimitType type) {
    return '$prefix${type.toString()}';
  }

  @override
  Future<void> saveLockoutState(RateLimitType type, bool isInLockout) async {
    await _ensureInitialized();
    await _storage.write(
      key: _getKey(_lockoutPrefix, type),
      value: isInLockout.toString(),
    );
  }

  @override
  Future<bool> loadLockoutState(RateLimitType type) async {
    await _ensureInitialized();
    final value = await _storage.read(key: _getKey(_lockoutPrefix, type));
    return value == 'true';
  }

  @override
  Future<void> saveRequestCount(RateLimitType type, int count) async {
    await _ensureInitialized();
    await _storage.write(
      key: _getKey(_countPrefix, type),
      value: count.toString(),
    );
  }

  @override
  Future<int> loadRequestCount(RateLimitType type) async {
    await _ensureInitialized();
    final value = await _storage.read(key: _getKey(_countPrefix, type));
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  @override
  Future<void> saveLastResetTime(RateLimitType type, DateTime time) async {
    await _ensureInitialized();
    await _storage.write(
      key: _getKey(_timestampPrefix, type),
      value: time.toIso8601String(),
    );
  }

  @override
  Future<DateTime?> loadLastResetTime(RateLimitType type) async {
    await _ensureInitialized();
    final timeString = await _storage.read(
      key: _getKey(_timestampPrefix, type),
    );
    if (timeString == null) return null;

    try {
      return DateTime.parse(timeString);
    } catch (e) {
      Logger.error('RateLimitStorage: Error parsing timestamp: $e');
      return null;
    }
  }

  @override
  Future<void> clearStorage() async {
    await _ensureInitialized();

    // Get all values
    final allValues = await _storage.readAll();

    // Filter for rate limit keys
    final rateLimitKeys = allValues.keys.where(
      (key) =>
          key.startsWith(_lockoutPrefix) ||
          key.startsWith(_countPrefix) ||
          key.startsWith(_timestampPrefix),
    );

    // Remove all rate limit keys
    for (final key in rateLimitKeys) {
      await _storage.delete(key: key);
    }

    Logger.debug('RateLimitStorage: Cleared all rate limit storage');
  }
}

/// In-memory implementation of RateLimitStorage (useful for testing)
class InMemoryRateLimitStorage implements RateLimitStorage {
  final Map<String, bool> _lockoutStates = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, DateTime> _resetTimes = {};

  String _getKey(String prefix, RateLimitType type) {
    return '$prefix${type.toString()}';
  }

  @override
  Future<void> saveLockoutState(RateLimitType type, bool isInLockout) async {
    _lockoutStates[type.toString()] = isInLockout;
  }

  @override
  Future<bool> loadLockoutState(RateLimitType type) async {
    return _lockoutStates[type.toString()] ?? false;
  }

  @override
  Future<void> saveRequestCount(RateLimitType type, int count) async {
    _requestCounts[type.toString()] = count;
  }

  @override
  Future<int> loadRequestCount(RateLimitType type) async {
    return _requestCounts[type.toString()] ?? 0;
  }

  @override
  Future<void> saveLastResetTime(RateLimitType type, DateTime time) async {
    _resetTimes[type.toString()] = time;
  }

  @override
  Future<DateTime?> loadLastResetTime(RateLimitType type) async {
    return _resetTimes[type.toString()];
  }

  @override
  Future<void> clearStorage() async {
    _lockoutStates.clear();
    _requestCounts.clear();
    _resetTimes.clear();
  }
}
