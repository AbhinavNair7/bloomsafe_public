# BloomSafe Caching System

This document details the caching mechanism implemented in BloomSafe to optimize performance and reduce API calls.

## Overview

BloomSafe implements a timezone-aware persistent caching system for AQI data. The caching system:

1. Reduces API call frequency
2. Improves app responsiveness 
3. Helps comply with API rate limits
4. Provides data persistence between app sessions
5. Strictly enforces data freshness (2-hour limit)

## Core Components

### 1. Cache Manager Interface

The `CacheManager` interface defines the contract for caching operations:

```dart
/// Cache manager interface for AQI data
abstract class CacheManager {
  /// Retrieves the latest cached data for a zipcode
  Future<AQIData?> getLatest(String zipcode);
  
  /// Caches the AQI data for a zipcode
  Future<void> cacheData(String zipcode, AQIData data);
}
```

This interface allows for potential alternative implementations.

### 2. Persistent Cache Implementation

The `CacheService` class implements persistent storage with SharedPreferences:

```dart
/// In-memory cache implementation with persistent storage backup
class CacheService<T> {
  /// In-memory cache storage
  final Map<String, CachedItem<T>> _cache = {};
  
  /// SharedPreferences for persistent storage
  SharedPreferences? _prefs;
  
  // Implementation details...
  
  /// Saves to disk when item is added to cache
  Future<void> _saveToDisk(String key, CachedItem<T> item) async {
    // Convert to JSON and store in SharedPreferences
  }
  
  /// Loads cache from disk on initialization
  Future<void> _loadFromDisk() async {
    // Load valid entries from SharedPreferences
  }
}
```

This approach ensures cache survives app restarts while maintaining validation.

### 3. Cached Data Container

The `CachedItem` private class wraps the cached data with metadata and adds JSON serialization:

```dart
class CachedItem<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiresAt;
  
  // Constructor
  
  /// JSON serialization support for persistence
  factory CachedItem.fromJson(Map<String, dynamic> json, T Function(Object?)? fromJsonData) {
    // Create from JSON for SharedPreferences storage
  }
  
  /// Convert to JSON for persistence
  Map<String, dynamic> toJson(Object? Function(T)? toJsonData) {
    // Convert to JSON for storage
  }
}
```

### 4. AQI Data Model

The `AQIData` model includes built-in timezone-aware expiration tracking:

```dart
@JsonSerializable(explicitToJson: true)
class AQIData {
  // Data properties
  
  /// Timezone-aware observation date and time
  @JsonKey(ignore: true)
  late final tz.TZDateTime observationTime;

  /// Timestamp when this data should be considered expired (2 hours after observation)
  @JsonKey(ignore: true)
  late final tz.TZDateTime validUntil;
  
  // Constructor and methods
}
```

### 5. Timezone Support

The `TimeValidator` utility provides timezone validation:

```dart
class TimeValidator {
  /// Creates a timezone-aware DateTime from observation details
  static tz.TZDateTime createObservationDateTime(/* params */) {
    // Implementation creates timezone-aware date-time
  }
  
  /// Calculates expiry time (2 hours after observation)
  static tz.TZDateTime calculateExpiryTime(tz.TZDateTime observationTime) {
    return observationTime.add(const Duration(hours: 2));
  }
  
  /// Check if data is valid based on current time in data's timezone
  static bool isValid(tz.TZDateTime observationTime, tz.TZDateTime validUntil) {
    final now = tz.TZDateTime.now(observationTime.location);
    return now.isBefore(validUntil);
  }
}
```

## How It Works

### 1. Caching Process

When fresh AQI data is retrieved from the API, it follows this path:

```
API Response → AQIData model creation → validUntil calculated → cacheData() called → 
data stored in memory and SharedPreferences
```

The cache validation ensures only valid data is cached:

```dart
@override
Future<void> storeForZipCode(String zipCode, AQIData data) async {
  // Calculate expiration based on observation time and TTL
  final validUntil = TimeValidator.calculateExpiryTime(data.observationTime);

  // Store with explicit expiration time in memory and SharedPreferences
  await set(zipCode, data, expiresAt: validUntil.toLocal());
}
```

### 2. Cache Retrieval

When AQI data is requested, the repository first checks the cache:

```dart
// Check cache first
final cachedData = await _cacheService.getForZipCode(zipcode);
if (cachedData != null) {
  debugPrint('📦 Using cached data for zipcode: $zipcode');
  return cachedData;
}
```

The cache service validates data freshness before returning it:

```dart
/// Validates if AQI data is still valid based on its observation time
bool _isAQIDataValid(AQIData data) {
  // Get current time in the same timezone as the observation
  final now = tz.TZDateTime.now(data.observationTime.location);

  // Check if current time is before the data's expiration time
  final expiryTime = TimeValidator.calculateExpiryTime(data.observationTime);
  
  return now.isBefore(expiryTime);
}
```

### 3. Persistence Handling

The system automatically handles persistence:

1. New cache entries are saved to SharedPreferences
2. On app startup, valid cache entries are loaded from SharedPreferences
3. Cache validity is checked during loading - expired entries are not restored
4. All the same timezone-aware validation applies to persistent cache

### 4. Rate Limit Handling

When API rate limits are reached:

1. System checks for valid (unexpired) cache first
2. If valid cache exists, it's used normally
3. If no valid cache exists, a RateLimitException is thrown
4. The app never shows expired data (older than 2 hours)

### 5. Auto-Purging Mechanism

The cache automatically purges expired entries during operations:

```dart
/// Removes all expired entries from the cache
void _validateCache(bool Function(T data)? isValid) {
  // Find and remove expired entries
  // Also removes them from SharedPreferences
}
```

## Cache Expiration Policy

BloomSafe implements a strict 2-hour expiration policy for AQI data:

1. Each `AQIData` instance calculates its own `validUntil` timestamp (2 hours after observation)
2. The cache validates entries against the `validUntil` timestamp
3. Expired entries are never shown to users, even during rate-limiting
4. Expired entries are automatically removed during cache operations
5. Periodic cleanup runs every 15 minutes to remove expired entries

## Persistence Mechanism

The cache system uses SharedPreferences for persistent storage, ensuring cache survives app restarts:

### 1. Persistent Storage Implementation

**Components Involved**:
- `CacheService` class that manages both memory and disk cache
- `SharedPreferences` for persistent storage
- JSON serialization support in cache models

**Implementation Details**:
```dart
/// Saves cache entry to SharedPreferences
Future<void> _saveToDisk(String key, CachedItem<T> item) async {
  if (_prefs == null) return;
  
  // Convert to JSON string
  final jsonString = jsonEncode(item.toJson((data) {
    // Convert data to JSON based on type
    if (data is JsonSerializable) {
      return (data as dynamic).toJson();
    }
    return data;
  }));
  
  // Store in SharedPreferences
  await _prefs!.setString('cache_$key', jsonString);
}

/// Loads valid cache entries from SharedPreferences on initialization
Future<void> _loadFromDisk() async {
  _prefs = await SharedPreferences.getInstance();
  
  // Get all cache keys
  final keys = _prefs!.getKeys().where((k) => k.startsWith('cache_'));
  
  for (final fullKey in keys) {
    final key = fullKey.substring(6); // Remove 'cache_' prefix
    final jsonString = _prefs!.getString(fullKey);
    
    if (jsonString != null) {
      try {
        // Parse JSON and create CachedItem
        final json = jsonDecode(jsonString);
        final item = CachedItem<T>.fromJson(json, (json) {
          // Convert JSON to data type based on T
          return _fromJsonFactory(json);
        });
        
        // Only restore if not expired
        if (DateTime.now().isBefore(item.expiresAt)) {
          _cache[key] = item;
        } else {
          // Remove expired entry
          await _prefs!.remove(fullKey);
        }
      } catch (e) {
        // Remove invalid entry
        await _prefs!.remove(fullKey);
      }
    }
  }
}
```

### 2. Memory Fallback Mechanism

The system gracefully handles cases where persistent storage is unavailable:

- If SharedPreferences initialization fails, system falls back to memory-only cache
- All operations still work but persistence is not guaranteed
- System attempts to re-initialize SharedPreferences periodically

### 3. Cache Storage Lifecycle

1. **Initialization**:
   - App loads cache from SharedPreferences on startup
   - Expired entries are filtered out during load
   - Invalid entries are removed during load

2. **Cache Update**:
   - New entries are stored both in memory and SharedPreferences
   - Automatic validation occurs before storing

3. **Cache Retrieval**:
   - Memory cache is checked first for performance
   - All entries are validated before being returned

4. **Cache Cleanup**:
   - Expired entries are removed from both memory and SharedPreferences
   - Periodic cleanup ensures storage efficiency

## Timezone Handling

The caching system accounts for different timezones in AQI data:

1. API responses include a local timezone abbreviation (e.g., "EST")
2. Observation times are stored as timezone-aware `TZDateTime` objects
3. Validation compares the current time in the observation's timezone to the `validUntil` timestamp

This approach ensures that cache validity is assessed correctly regardless of the user's timezone.

## Advantages of the Current Approach

1. **Data Persistence**: Cache survives app restarts via SharedPreferences
2. **Strict Freshness**: Only data less than 2 hours old is ever shown
3. **Auto-Expiration**: Timezone-aware expiration ensures data freshness
4. **Self-Cleaning**: Automatic purging prevents memory leaks
5. **Timezone Correctness**: Proper handling of different observation timezones

## Future Enhancements

Potential future enhancements to the caching system could include:

1. **Cache Size Limits**: Implementing maximum entry count or memory usage
2. **Prioritized Caching**: Preferentially caching frequently accessed ZIP codes
3. **Predictive Prefetching**: Preloading data for likely future requests
4. **Cache Statistics**: Tracking hit/miss rates for optimization 