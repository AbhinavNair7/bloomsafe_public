import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';

/// Factory class for creating test data models
class TestFactories {
  /// Creates a test AQI Category with specified parameters or defaults
  static AQICategory createAQICategory({int number = 1, String name = 'Good'}) {
    return AQICategory(number: number, name: name);
  }

  /// Creates a test PollutantData with specified parameters or defaults
  static PollutantData createPollutantData({
    String parameterName = 'PM2.5',
    int aqi = 25,
    AQICategory? category,
  }) {
    return PollutantData(
      parameterName: parameterName,
      aqi: aqi,
      category:
          category ??
          createAQICategory(
            number: _getNumberForAQI(aqi),
            name: _getNameForAQI(aqi),
          ),
    );
  }

  /// Creates a test AQIData with specified parameters or defaults
  static AQIData createAQIData({
    List<PollutantData>? pollutants,
    String reportingArea = 'Test City',
    String stateCode = 'CA',
    String dateObserved = '2023-01-15',
    int hourObserved = 12,
    String localTimeZone = 'PST',
    double latitude = 37.7749,
    double longitude = -122.4194,
  }) {
    // Create default pollutants if none provided
    final effectivePollutants =
        pollutants ??
        [
          createPollutantData(aqi: 25),
          createPollutantData(parameterName: 'O3', aqi: 30),
        ];

    return AQIData(
      pollutants: effectivePollutants,
      reportingArea: reportingArea,
      stateCode: stateCode,
      dateObserved: dateObserved,
      hourObserved: hourObserved,
      localTimeZone: localTimeZone,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Creates a test TZDateTime for a specified location and time
  static tz.TZDateTime createTZDateTime({
    String location = 'America/Los_Angeles',
    int year = 2023,
    int month = 1,
    int day = 15,
    int hour = 12,
    int minute = 0,
    int second = 0,
  }) {
    return tz.TZDateTime(
      tz.getLocation(location),
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
  }

  /// Creates raw AQI API response data for testing
  static List<Map<String, dynamic>> createRawAQIResponse({
    int pm25Value = 25,
    int ozoneValue = 30,
    String dateObserved = '2023-01-15',
    int hourObserved = 12,
    String localTimeZone = 'PST',
    String reportingArea = 'Test City',
    String stateCode = 'CA',
    double latitude = 37.7749,
    double longitude = -122.4194,
  }) {
    return [
      {
        'DateObserved': dateObserved,
        'HourObserved': hourObserved,
        'LocalTimeZone': localTimeZone,
        'ReportingArea': reportingArea,
        'StateCode': stateCode,
        'Latitude': latitude,
        'Longitude': longitude,
        'ParameterName': 'PM2.5',
        'AQI': pm25Value,
        'Category': {
          'Number': _getNumberForAQI(pm25Value),
          'Name': _getNameForAQI(pm25Value),
        },
      },
      {
        'DateObserved': dateObserved,
        'HourObserved': hourObserved,
        'LocalTimeZone': localTimeZone,
        'ReportingArea': reportingArea,
        'StateCode': stateCode,
        'Latitude': latitude,
        'Longitude': longitude,
        'ParameterName': 'O3',
        'AQI': ozoneValue,
        'Category': {
          'Number': _getNumberForAQI(ozoneValue),
          'Name': _getNameForAQI(ozoneValue),
        },
      },
    ];
  }

  /// Creates a Map representing API error response for testing
  static Map<String, dynamic> createErrorResponse({
    int statusCode = 400,
    String message = 'Bad Request',
  }) {
    return {'statusCode': statusCode, 'message': message};
  }

  /// Helper method to get AQI category number based on AQI value
  static int _getNumberForAQI(int aqi) {
    if (aqi <= 50) return 1;
    if (aqi <= 100) return 2;
    if (aqi <= 150) return 3;
    if (aqi <= 200) return 4;
    if (aqi <= 300) return 5;
    return 6;
  }

  /// Helper method to get AQI category name based on AQI value
  static String _getNameForAQI(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
