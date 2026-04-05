import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';

/// Repository interface for retrieving AQI data
abstract class AQIRepository {
  /// Fetches the AQI data for the given zipcode
  ///
  /// Returns an [AQIData] object containing AQI information for various pollutants
  /// with a focus on PM2.5 values.
  ///
  /// Throws:
  /// - [InvalidZipcodeException] if the zipcode is not valid
  /// - [NetworkException] if there is a network error
  /// - [NoDataForZipcodeException] if no data is available for the zipcode
  /// - [AQIException] for other errors related to AQI data retrieval
  Future<AQIData> getAQIByZipcode(String zipcode);

  /// Checks if data for a zip code is available in cache
  Future<bool> hasDataForZipCode(String zipCode);

  /// Gets cached data without making API requests
  Future<AQIData?> getCachedDataForZipCode(String zipCode);

  /// Clears all cached data
  Future<void> clearCache();

  /// Returns whether the last retrieved data was from cache
  bool isFromCache();

  /// Returns the age of the cached data for the given zipcode
  Duration getCacheAge(String zipCode);
}
