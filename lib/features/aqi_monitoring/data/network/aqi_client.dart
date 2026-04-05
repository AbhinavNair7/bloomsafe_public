import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/constants/aqi_constants.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/validation_utils.dart';
import 'package:bloomsafe/core/constants/strings.dart';

/// AQI-specific client that handles API requests for air quality data
class AQIClient {

  /// Creates a new AQIClient
  AQIClient(this._apiClient, this._envConfig);
  final ApiClient _apiClient;
  final EnvConfig _envConfig;

  /// Get air quality data by zip code
  Future<List<dynamic>> getAirQualityByZipCode(
    String zipCode,
    String format,
    int distance, [
    String? apiKey,
  ]) async {
    // Validate the zipCode first
    final validationError = AQIValidationUtils.validateZipCode(zipCode);
    if (validationError != null) {
      throw InvalidZipcodeException(validationError);
    }

    // Get API key either from parameter or environment config
    final key = apiKey ?? await _envConfig.getSecureApiKey();

    if (key == null || key.isEmpty) {
      throw AQIException('API key not available');
    }

    // Build query parameters
    final queryParams = {
      aqiZipCodeParam: zipCode,
      aqiFormatParam: format,
      aqiDistanceParam: distance.toString(),
      aqiApiKeyParam: key,
    };

    // Make the API call
    final data = await _apiClient.get(aqiBaseUrl, queryParams: queryParams);

    // Handle empty response
    if (data == null || (data is List && data.isEmpty)) {
      throw NoDataForZipcodeException(apiConnectionErrorMessage);
    }

    return data as List<dynamic>;
  }

  /// Check if rate limits are exceeded and only cached data should be used
  Future<bool> shouldUseCacheOnly() async {
    return await _apiClient.shouldUseCacheOnly();
  }
}
