import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PollutantData', () {
    test('creation works with valid parameters', () {
      final pollutant = PollutantData(
        parameterName: 'PM2.5',
        aqi: 50,
        category: AQICategory(number: 1, name: 'Good'),
      );

      expect(pollutant.parameterName, 'PM2.5');
      expect(pollutant.aqi, 50);
      expect(pollutant.category.number, 1);
      expect(pollutant.category.name, 'Good');
    });

    test('rejects invalid parameter names in constructor', () {
      expect(
        () => PollutantData(
          parameterName: 'INVALID',
          aqi: 50,
          category: AQICategory(number: 1, name: 'Good'),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson and toJson work correctly', () {
      final pollutant = PollutantData(
        parameterName: 'PM2.5',
        aqi: 50,
        category: AQICategory(number: 1, name: 'Good'),
      );

      final json = pollutant.toJson();
      final fromJson = PollutantData.fromJson(json);

      expect(fromJson.parameterName, 'PM2.5');
      expect(fromJson.aqi, 50);
      expect(fromJson.category.number, 1);
      expect(fromJson.category.name, 'Good');
    });

    test('fromJson rejects invalid parameter names', () {
      final json = {
        'parameterName': 'INVALID',
        'aqi': 50,
        'category': {'Number': 1, 'Name': 'Good'},
      };

      expect(
        () => PollutantData.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('isPM25 returns true for PM2.5 parameter', () {
      final pollutant = PollutantData(
        parameterName: 'PM2.5',
        aqi: 50,
        category: AQICategory(number: 1, name: 'Good'),
      );

      expect(pollutant.isPM25, true);
      expect(pollutant.isO3, false);
      expect(pollutant.isPM10, false);
    });

    test('isO3 returns true for O3 parameter', () {
      final pollutant = PollutantData(
        parameterName: 'O3',
        aqi: 30,
        category: AQICategory(number: 1, name: 'Good'),
      );

      expect(pollutant.isPM25, false);
      expect(pollutant.isO3, true);
      expect(pollutant.isPM10, false);
    });

    test('isPM10 returns true for PM10 parameter', () {
      final pollutant = PollutantData(
        parameterName: 'PM10',
        aqi: 25,
        category: AQICategory(number: 1, name: 'Good'),
      );

      expect(pollutant.isPM25, false);
      expect(pollutant.isO3, false);
      expect(pollutant.isPM10, true);
    });

    test('toString formats correctly', () {
      final pollutant = PollutantData(
        parameterName: 'PM2.5',
        aqi: 50,
        category: AQICategory(number: 1, name: 'Good'),
      );

      expect(pollutant.toString(), 'PM2.5: AQI 50 (Good)');
    });

    test('validParameterNames contains all supported pollutant types', () {
      expect(PollutantData.validParameterNames.contains('PM2.5'), true);
      expect(PollutantData.validParameterNames.contains('O3'), true);
      expect(PollutantData.validParameterNames.contains('PM10'), true);
      expect(PollutantData.validParameterNames.length, 3);
    });
  });
}
