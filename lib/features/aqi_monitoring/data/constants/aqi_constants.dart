import 'package:bloomsafe/core/constants/strings.dart';

// Base API endpoint - read from environment or use default
const String aqiBaseUrl = String.fromEnvironment(
  'AIRNOW_BASE_URL',
  defaultValue: 'https://www.airnowapi.org/aq/observation/zipCode/current/',
);

// API parameters structure
const String aqiZipCodeParam = 'zipCode';
const String aqiFormatParam = 'format';
const String aqiDistanceParam = 'distance';
const String aqiApiKeyParam =
    'api_key'; // Correct parameter name for AirNow API

// Environment variable keys
const String envAirnowApiKey = 'AIRNOW_API_KEY';
const String envMaxRequestsPerMinute = 'MAX_REQUESTS_PER_MINUTE';

// API response cache time
const Duration aqiCacheDuration = Duration(
  hours: 2,
); // Cache duration based on API-provided timestamp

// AQI-specific error types
enum AQIErrorType {
  extremeValues, // Extreme AQI values
}

// AQI Error Response Mapping
const Map<AQIErrorType, String> aqiErrorMessages = {
  AQIErrorType.extremeValues: extremeAqiValuesMessage,
};
