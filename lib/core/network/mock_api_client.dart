import 'dart:async';
import 'dart:math';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/constants/aqi_constants.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Mock API client for development and testing
///
/// This client simulates API responses without making actual network requests.
/// It's useful for development, testing, and avoiding API rate limits during development.
class MockApiClient {

  /// Create a new MockApiClient with EnvConfig
  MockApiClient(EnvConfig envConfig);

  /// Create a new MockApiClient with AppConfig
  MockApiClient.withAppConfig({required AppConfig appConfig});

  /// Alternate constructor with AppConfig for test compatibility
  MockApiClient.fromAppConfig({required AppConfig appConfig});

  final Random _random = Random();

  /// Gets air quality data by zip code
  /// Returns mock AQI data in the same format as the real API
  Future<List<dynamic>> getAirQualityByZipCode(
    String zipCode,
    String format,
    int distance, [
    String? apiKey,
  ]) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 200 + _random.nextInt(300)));

    // Log the mock request
    Logger.network(
      '📡 MOCK GET AQI: zipCode=$zipCode, format=$format, distance=$distance',
    );

    // Special case for testing: empty data scenario
    if (zipCode == '00000') {
      return [];
    }

    // Special case for testing: error scenario
    if (zipCode == '99999') {
      throw GenericApiException('Simulated error for testing');
    }

    // Generate mock data
    return _getMockAirQualityData(zipCode);
  }

  /// Generates mock air quality data with realistic values
  List<Map<String, dynamic>> _getMockAirQualityData(String zipCode) {
    // Generate different mock values based on the zipcode to simulate
    // different conditions in different areas
    final zipSum = zipCode.codeUnits.fold(0, (sum, code) => sum + code);
    final aqiBase = 20 + (zipSum % 150); // Between 20-170

    return [
      {
        'DateObserved': _getCurrentDate(),
        'HourObserved': _getCurrentHour(),
        'LocalTimeZone': 'EST',
        'ReportingArea': 'Test City',
        'StateCode': 'TC',
        'Latitude': 40.7128,
        'Longitude': -74.0060,
        'ParameterName': 'PM2.5',
        'AQI': aqiBase,
        'Category': _getCategoryForAqi(aqiBase),
      },
      {
        'DateObserved': _getCurrentDate(),
        'HourObserved': _getCurrentHour(),
        'LocalTimeZone': 'EST',
        'ReportingArea': 'Test City',
        'StateCode': 'TC',
        'Latitude': 40.7128,
        'Longitude': -74.0060,
        'ParameterName': 'O3',
        'AQI': aqiBase - 10 + _random.nextInt(20),
        'Category': _getCategoryForAqi(aqiBase - 10 + _random.nextInt(20)),
      },
    ];
  }

  /// Gets the current date in the format MM/DD/YY
  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}';
  }

  /// Gets the current hour (0-23)
  int _getCurrentHour() {
    return DateTime.now().hour;
  }

  /// Maps AQI value to the appropriate category
  Map<String, dynamic> _getCategoryForAqi(int aqi) {
    if (aqi <= 50) {
      return {'Number': 1, 'Name': 'Good'};
    } else if (aqi <= 100) {
      return {'Number': 2, 'Name': 'Moderate'};
    } else if (aqi <= 150) {
      return {'Number': 3, 'Name': 'Unhealthy for Sensitive Groups'};
    } else if (aqi <= 200) {
      return {'Number': 4, 'Name': 'Unhealthy'};
    } else if (aqi <= 300) {
      return {'Number': 5, 'Name': 'Very Unhealthy'};
    } else {
      return {'Number': 6, 'Name': 'Hazardous'};
    }
  }

  /// Simulates a GET request with optional query parameters
  Future<dynamic> get(
    String endpoint, {
    Map<String, String?>? queryParams,
    bool enforceRateLimit = true,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    // Log the mock request
    Logger.network('📡 MOCK GET: $endpoint');
    if (queryParams != null) {
      Logger.network('📡 MOCK Query Params: $queryParams');
    }

    // Simulate different error scenarios (for testing)
    if (endpoint.contains('error')) {
      throw GenericApiException('Simulated error for testing');
    }

    if (endpoint.contains('timeout')) {
      throw TimeoutException('Simulated timeout for testing');
    }

    if (endpoint.contains('server-error')) {
      throw ServerException('Simulated server error for testing');
    }

    // Handle AQI requests
    if (endpoint == aqiBaseUrl && queryParams != null) {
      final zipCode = queryParams[aqiZipCodeParam] ?? '12345';
      final format = queryParams[aqiFormatParam] ?? 'json';
      final distance =
          int.tryParse(queryParams[aqiDistanceParam] ?? '25') ?? 25;

      return getAirQualityByZipCode(zipCode, format, distance);
    }

    // Return empty data for unknown endpoints
    return [];
  }

  /// Simulates a POST request with optional body
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool enforceRateLimit = true,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    // Log the mock request
    Logger.network('📡 MOCK POST: $endpoint');
    if (body != null) {
      Logger.network('📡 MOCK Body: $body');
    }

    // Simulate different error scenarios (for testing)
    if (endpoint.contains('error')) {
      throw GenericApiException('Simulated error for testing');
    }

    if (endpoint.contains('timeout')) {
      throw TimeoutException('Simulated timeout for testing');
    }

    if (endpoint.contains('server-error')) {
      throw ServerException('Simulated server error for testing');
    }

    // Return mock data based on the endpoint
    // For now, just return an empty map if no specific mock logic is implemented
    return {};
  }
}
