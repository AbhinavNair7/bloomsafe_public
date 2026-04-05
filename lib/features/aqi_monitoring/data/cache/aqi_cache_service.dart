import 'package:bloomsafe/core/services/cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:timezone/timezone.dart' as tz;

/// AQI-specific cache service that handles cache validation with timezone-aware logic
class AQICacheService extends CacheService<AQIData> {
  /// Creates a new AQICacheService
  AQICacheService({super.enableAutomaticCleanup})
    : super(
        persistEnabled: true,
        storageKeyPrefix: 'aqi_cache_',
        // Convert AQIData to JSON for storage
        toJsonData: (AQIData data) => data.toJson(),
        // Create AQIData from JSON object
        fromJsonData:
            (Object? json) => AQIData.fromJson(json as Map<String, dynamic>),
      );

  /// Gets cached AQI data for a specific zip code
  Future<AQIData?> getForZipCode(String zipCode) async {
    return await get(zipCode, isValid: _isAQIDataValid);
  }

  /// Stores AQI data for a specific zip code with appropriate expiration time
  Future<void> storeForZipCode(String zipCode, AQIData data) async {
    // Calculate expiration based on observation time and TTL
    final validUntil = TimeValidator.calculateExpiryTime(data.observationTime);

    // Store with explicit expiration time
    await set(zipCode, data, expiresAt: validUntil.toLocal());
  }

  /// Validates if AQI data is still valid based on its observation time
  bool _isAQIDataValid(AQIData data) {
    // Get current time in the same timezone as the observation
    final now = tz.TZDateTime.now(data.observationTime.location);

    // Check if current time is before the data's expiration time
    final expiryTime = TimeValidator.calculateExpiryTime(data.observationTime);

    final isValid = now.isBefore(expiryTime);

    if (!isValid) {
      Logger.debug(
        'AQI data for ${data.reportingArea ?? "unknown location"} expired (observed at ${data.observationTime})',
      );
    }

    return isValid;
  }
}
