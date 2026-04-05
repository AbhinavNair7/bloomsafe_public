import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';

/// Test data constants
class TestData {
  /// Test AQI data for good air quality
  static final goodAqiData = AQIData(
    pollutants: [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 25,
        category: AQICategory(number: 1, name: 'Good'),
      ),
    ],
    reportingArea: 'Test City',
    stateCode: 'TC',
    dateObserved: '2025-03-15',
    hourObserved: 12,
    localTimeZone: 'UTC',
    latitude: 35.123,
    longitude: -78.456,
  );

  /// Test AQI data for moderate air quality
  static final moderateAqiData = AQIData(
    pollutants: [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 75,
        category: AQICategory(number: 2, name: 'Moderate'),
      ),
    ],
    reportingArea: 'Test City',
    stateCode: 'TC',
    dateObserved: '2025-03-15',
    hourObserved: 12,
    localTimeZone: 'UTC',
    latitude: 35.123,
    longitude: -78.456,
  );

  /// Test AQI data for unhealthy air quality
  static final unhealthyAqiData = AQIData(
    pollutants: [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 151,
        category: AQICategory(number: 4, name: 'Unhealthy'),
      ),
    ],
    reportingArea: 'Test City',
    stateCode: 'TC',
    dateObserved: '2025-03-15',
    hourObserved: 12,
    localTimeZone: 'UTC',
    latitude: 35.123,
    longitude: -78.456,
  );

  /// Test AQI data for hazardous air quality
  static final hazardousAqiData = AQIData(
    pollutants: [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 350,
        category: AQICategory(number: 6, name: 'Hazardous'),
      ),
    ],
    reportingArea: 'Test City',
    stateCode: 'TC',
    dateObserved: '2025-03-15',
    hourObserved: 12,
    localTimeZone: 'UTC',
    latitude: 35.123,
    longitude: -78.456,
  );

  /// Test data for multiple pollutants
  static final multiPollutantData = AQIData(
    pollutants: [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 50,
        category: AQICategory(number: 1, name: 'Good'),
      ),
      PollutantData(
        parameterName: 'O3',
        aqi: 30,
        category: AQICategory(number: 1, name: 'Good'),
      ),
      PollutantData(
        parameterName: 'PM10',
        aqi: 25,
        category: AQICategory(number: 1, name: 'Good'),
      ),
    ],
    reportingArea: 'Test City',
    stateCode: 'TC',
    dateObserved: '2025-03-15',
    hourObserved: 12,
    localTimeZone: 'UTC',
    latitude: 35.123,
    longitude: -78.456,
  );

  /// Mock API response data
  static final Map<String, dynamic> mockApiResponse = {
    'ParameterName': 'PM2.5',
    'AQI': 50,
    'Category': {'Number': 1, 'Name': 'Good'},
    'ReportingArea': 'Test City',
    'StateCode': 'TC',
    'DateObserved': '2025-03-15',
    'HourObserved': 12,
    'LocalTimeZone': 'UTC',
    'Latitude': 35.123,
    'Longitude': -78.456,
  };

  /// Test zipcodes
  static const validZipcode = '90210';
  static const invalidZipcode = '9021';
  static const errorZipcode = '00000';
  static const noDataZipcode = '99999';
}
