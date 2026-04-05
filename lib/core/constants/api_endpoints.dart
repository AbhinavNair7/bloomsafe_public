// Base API URLs - read from environment or use default
const String aqiBaseUrl = String.fromEnvironment(
  'AIRNOW_BASE_URL',
  defaultValue: 'https://www.airnowapi.org/aq/observation/zipCode/current/',
);

// Request timeouts in milliseconds
const Duration defaultConnectTimeout = Duration(seconds: 10);
const Duration defaultReceiveTimeout = Duration(seconds: 15);

// API parameters structure
const String aqiZipCodeParam = 'zipCode';
const String aqiFormatParam = 'format';
const String aqiDistanceParam = 'distance';
const String aqiApiKeyParam = 'api_key';
