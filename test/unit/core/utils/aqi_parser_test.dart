import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/utils/aqi_parser.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/aqi_classifier.dart'
    as classifier;
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../helpers/time_utils.dart';

void main() {
  // Initialize timezone data before tests
  setUpAll(() {
    TimeTestUtils.initializeTimeZones();
  });

  final parser = AQIParser();
  final testDate = DateTime.now().toUtc().toIso8601String();

  // Sample API response structure
  final validResponse = [
    {
      'ParameterName': 'PM2.5',
      'AQI': 35,
      'Category': {'Number': 1, 'Name': 'Good'},
      'DateObserved': testDate,
      'HourObserved': 12,
      'ReportingArea': 'San Francisco',
      'StateCode': 'CA',
      'Latitude': 37.7749,
      'Longitude': -122.4194,
      'LocalTimeZone': 'America/Los_Angeles',
    },
  ];

  group('Technical Validation', () {
    test('Parses valid API response structure', () {
      final result = parser.parseResponse(validResponse);
      expect(result, isA<AQIData>());
      expect(result.reportingArea, 'San Francisco');
    });

    test('Extracts PM2.5 from first pollutant entry', () {
      final multiPollutantResponse = [
        ...validResponse,
        {
          'ParameterName': 'O3',
          'AQI': 45,
          'Category': {'Number': 1, 'Name': 'Good'},
          'DateObserved': testDate,
          'HourObserved': 12,
          'ReportingArea': 'San Francisco',
          'StateCode': 'CA',
        },
      ];

      final pm25 = parser.extractPM25(multiPollutantResponse);
      expect(pm25?['ParameterName'], 'PM2.5');
    });

    test('Handles empty API response array', () {
      expect(() => parser.parseResponse([]), throwsA(isA<ParserException>()));
    });

    test('Validates data freshness within 1 hour', () {
      // Create AQI data with fixed observation time in UTC
      final testData = AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: 35,
            category: AQICategory(number: 1, name: 'Good'),
          ),
        ],
        dateObserved: '2025-03-24',
        hourObserved: 12,
        localTimeZone: 'UTC',
      );

      // Verify observation time is correctly set to 12:00 UTC
      expect(testData.observationTime.hour, 12);
      expect(testData.observationTime.timeZoneOffset.inHours, 0); // UTC

      // Create mock for data freshness that simulates current time as 12:30 UTC
      // This should return true for freshness since it's only 30 minutes old
      final isDataFresh = _isDataFreshMock(
        testData,
        mockNow: () => tz.TZDateTime.utc(2025, 3, 24, 12, 30),
      );
      expect(isDataFresh, isTrue);

      // Create mock for data freshness that simulates current time as 13:30 UTC
      // This should return false for freshness since it's 1.5 hours old
      final isDataStale = _isDataFreshMock(
        testData,
        mockNow: () => tz.TZDateTime.utc(2025, 3, 24, 13, 30),
      );
      expect(isDataStale, isFalse);
    });

    test('Handles API response missing PM2.5 data', () {
      final ozoneOnly = [
        {
          'ParameterName': 'O3',
          'AQI': 45,
          'Category': {'Number': 1, 'Name': 'Good'},
          'DateObserved': testDate,
          'HourObserved': 12,
          'ReportingArea': 'San Francisco',
          'StateCode': 'CA',
          'Latitude': 37.7749,
          'Longitude': -122.4194,
          'LocalTimeZone': 'America/Los_Angeles',
        },
      ];

      // Now that we validate for PM2.5 presence, this should throw an exception
      expect(
        () => parser.parseResponse(ozoneOnly),
        throwsA(isA<ParserException>()),
      );

      // The extractPM25 method should still return null
      final pm25Data = parser.extractPM25(ozoneOnly);
      expect(pm25Data, isNull);
    });
  });

  group('AQI Classification', () {
    test('Classifies AQI values into correct severity zones', () {
      // Test each zone
      expect(classifier.classifyAQISeverity(25), equals('nurturing')); // 0-50
      expect(classifier.classifyAQISeverity(75), equals('mindful')); // 51-100
      expect(
        classifier.classifyAQISeverity(125),
        equals('cautious'),
      ); // 101-150
      expect(classifier.classifyAQISeverity(175), equals('shield')); // 151-200
      expect(classifier.classifyAQISeverity(250), equals('shelter')); // 201-300
      expect(classifier.classifyAQISeverity(350), equals('protection')); // 301+
    });

    test('Handles edge cases in AQI classification', () {
      // Edge values
      expect(classifier.classifyAQISeverity(0), equals('nurturing'));
      expect(classifier.classifyAQISeverity(50), equals('nurturing'));
      expect(classifier.classifyAQISeverity(51), equals('mindful'));
      expect(classifier.classifyAQISeverity(100), equals('mindful'));

      // Out of range values
      expect(
        classifier.classifyAQISeverity(-10),
        equals('nurturing'),
      ); // Should handle negative values
      expect(
        classifier.classifyAQISeverity(600),
        equals('protection'),
      ); // Beyond max range
    });
  });

  group('Recommendations', () {
    test('Generates recommendations based on AQI value', () {
      final lowRecs = classifier.generateRecommendations(25);
      expect(lowRecs['zoneName'], isNotEmpty);
      expect(lowRecs['healthImpact'], isNotEmpty);
      expect(lowRecs['recommendations'], isA<List>());
      expect((lowRecs['recommendations'] as List).length, greaterThan(0));

      final highRecs = classifier.generateRecommendations(250);
      expect(highRecs['zoneName'], isNotEmpty);
      expect(highRecs['healthImpact'], isNotEmpty);
      expect(highRecs['recommendations'], isA<List>());
      expect((highRecs['recommendations'] as List).length, greaterThan(0));
    });
  });

  group('AQI Category Mapping', () {
    test('Maps AQI values to correct EPA categories', () {
      expect(classifier.getAQICategory(25), equals('Good'));
      expect(classifier.getAQICategory(75), equals('Moderate'));
      expect(
        classifier.getAQICategory(125),
        equals('Unhealthy for Sensitive Groups'),
      );
      expect(classifier.getAQICategory(175), equals('Unhealthy'));
      expect(classifier.getAQICategory(250), equals('Very Unhealthy'));
      expect(classifier.getAQICategory(350), equals('Hazardous'));
    });

    test('Retrieves colors for AQI values', () {
      // Just verify that colors are returned as non-empty strings
      // (actual values depend on the severity zones configuration)
      expect(classifier.getAQIColor(25), isNotEmpty);
      expect(classifier.getAQIColor(75), isNotEmpty);
      expect(classifier.getAQIColor(350), isNotEmpty);
    });
  });
}

bool _isDataFreshMock(AQIData data, {tz.TZDateTime Function()? mockNow}) {
  // Get current time in the same timezone as the observation
  final now =
      mockNow != null
          ? mockNow()
          : tz.TZDateTime.now(data.observationTime.location);

  // Data is fresh if it's less than maxDataAgeHours old (1 hour)
  return now.difference(data.observationTime).inHours <
      AQIParser.maxDataAgeHours;
}
