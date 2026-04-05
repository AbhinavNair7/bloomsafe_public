import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_response_parser.dart';

void main() {
  group('AQIResponseParser', () {
    test('extractPM25Data correctly parses valid data', () {
      // Sample API response with valid PM2.5 data
      final validResponse = [
        {
          'ParameterName': 'PM2.5',
          'AQI': 35,
          'Category': {'Number': 1, 'Name': 'Good'},
          'DateObserved': '2025-03-30',
          'HourObserved': 12,
          'LocalTimeZone': 'EST',
        },
      ];

      final result = AQIResponseParser.extractPM25Data(validResponse);

      expect(result, isA<Map<String, dynamic>>());
      expect(result['ParameterName'], equals('PM2.5'));
      expect(result['AQI'], equals(35));
    });

    test('extractPM25Data throws AQIException for empty response', () {
      final emptyResponse = <dynamic>[];

      expect(
        () => AQIResponseParser.extractPM25Data(emptyResponse),
        throwsA(
          isA<AQIException>().having(
            (e) => e.message,
            'message',
            apiConnectionErrorMessage,
          ),
        ),
      );
    });

    test(
      'extractPM25Data throws AQIException when PM2.5 data is not found',
      () {
        // Sample API response without PM2.5 data
        final noDataResponse = [
          {
            'ParameterName': 'O3',
            'AQI': 42,
            'Category': {'Number': 1, 'Name': 'Good'},
          },
        ];

        expect(
          () => AQIResponseParser.extractPM25Data(noDataResponse),
          throwsA(
            isA<AQIException>().having(
              (e) => e.message,
              'message',
              apiConnectionErrorMessage,
            ),
          ),
        );
      },
    );

    test(
      'extractPM25Data throws AQIException with extreme value message for AQI above 500',
      () {
        // Sample API response with extreme AQI value
        final extremeResponse = [
          {
            'ParameterName': 'PM2.5',
            'AQI': 501,
            'Category': {'Number': 6, 'Name': 'Hazardous'},
          },
        ];

        expect(
          () => AQIResponseParser.extractPM25Data(extremeResponse),
          throwsA(
            isA<AQIException>().having(
              (e) => e.message,
              'message',
              extremeAqiValuesMessage,
            ),
          ),
        );
      },
    );

    test(
      'extractPM25Data throws AQIException with extreme value message for negative AQI values',
      () {
        // Sample API response with negative AQI value
        final negativeResponse = [
          {
            'ParameterName': 'PM2.5',
            'AQI': -5,
            'Category': {'Number': 1, 'Name': 'Good'},
          },
        ];

        expect(
          () => AQIResponseParser.extractPM25Data(negativeResponse),
          throwsA(
            isA<AQIException>().having(
              (e) => e.message,
              'message',
              extremeAqiValuesMessage,
            ),
          ),
        );
      },
    );

    test(
      'extractPM25Data handles but does not throw for borderline high AQI values',
      () {
        // Sample API response with borderline high AQI value
        final borderlineResponse = [
          {
            'ParameterName': 'PM2.5',
            'AQI': 480,
            'Category': {'Number': 6, 'Name': 'Hazardous'},
          },
        ];

        // Should not throw, but should return the data
        final result = AQIResponseParser.extractPM25Data(borderlineResponse);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['ParameterName'], equals('PM2.5'));
        expect(result['AQI'], equals(480));
      },
    );
  });
}
