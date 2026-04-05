import 'dart:async';
import 'dart:math';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart'
    as aqi_exceptions;
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Mock AQI client for development and testing
///
/// This client simulates AQI-specific API responses without making actual network requests.
/// It's useful for development, testing, and avoiding API rate limits during development.
class MockAQIClient {

  /// Create a new MockAQIClient
  MockAQIClient(this._envConfig);
  final EnvConfig _envConfig;
  final Random _random = Random();

  /// Simulates fetching air quality data for a zip code
  Future<List<Map<String, dynamic>>> getAirQualityByZipCode(
    String zipCode,
    String format,
    int distance,
  ) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    // Log the mock request
    Logger.network('📡 MOCK AQI Request for zipCode: $zipCode');

    // Simulate error scenarios
    if (zipCode == '00000') {
      throw aqi_exceptions.NoDataForZipcodeException(apiConnectionErrorMessage);
    }

    if (zipCode == '99999') {
      throw RateLimitException('Rate limit exceeded for testing');
    }

    // Test zipcode for hourly rate limit (use 88888)
    if (zipCode == '88888') {
      throw RateLimitException(
        apiHourlyRateLimitExceededMessage,
        type: RateLimitType.serverHourly,
        remainingSeconds: 30 * 60, // 30 minutes in seconds
      );
    }

    // Test zipcode for per-minute rate limit (use 77777)
    if (zipCode == '77777') {
      throw RateLimitException(
        apiRateLimitExceededMessage,
        type: RateLimitType.serverMinute,
        remainingSeconds: 5 * 60, // 5 minutes in seconds
      );
    }

    // Return mock data with realistic structure
    return _generateMockAQIData(zipCode);
  }

  /// Generates realistic-looking mock AQI data
  List<Map<String, dynamic>> _generateMockAQIData(String zipCode) {
    // Create random but realistic values
    final aqi = 10 + _random.nextInt(250); // AQI between 10 and 259
    final category = _getCategoryForAQI(aqi);

    // Return structured data similar to actual API response
    return [
      {
        'DateObserved': _getFormattedDate(),
        'HourObserved': _random.nextInt(24),
        'LocalTimeZone': 'EST',
        'ReportingArea': 'Mock City',
        'StateCode': 'MC',
        'Latitude': 40.0 + (_random.nextDouble() * 10),
        'Longitude': -75.0 + (_random.nextDouble() * 10),
        'ParameterName': 'PM2.5',
        'AQI': aqi,
        'Category': {'Number': category, 'Name': _getCategoryName(category)},
      },
    ];
  }

  /// Gets formatted date string for mock data
  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }

  /// Maps AQI value to category number
  int _getCategoryForAQI(int aqi) {
    if (aqi <= 50) return 1;
    if (aqi <= 100) return 2;
    if (aqi <= 150) return 3;
    if (aqi <= 200) return 4;
    if (aqi <= 300) return 5;
    return 6;
  }

  /// Maps category number to name
  String _getCategoryName(int category) {
    switch (category) {
      case 1:
        return 'Good';
      case 2:
        return 'Moderate';
      case 3:
        return 'Unhealthy for Sensitive Groups';
      case 4:
        return 'Unhealthy';
      case 5:
        return 'Very Unhealthy';
      case 6:
        return 'Hazardous';
      default:
        return 'Unknown';
    }
  }
}
