import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AQICategory', () {
    test('creation works with valid category number', () {
      final category = AQICategory(number: 1, name: 'Good');
      expect(category.number, 1);
      expect(category.name, 'Good');
    });

    test('rejects invalid category numbers in constructor', () {
      expect(
        () => AQICategory(number: 0, name: 'Invalid'),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => AQICategory(number: 7, name: 'Invalid'),
        throwsA(isA<RangeError>()),
      );
    });

    test('fromJson works with valid data', () {
      final json = {'Number': 2, 'Name': 'Moderate'};
      final category = AQICategory.fromJson(json);

      expect(category.number, 2);
      expect(category.name, 'Moderate');
    });

    test('fromJson rejects invalid category numbers', () {
      final jsonTooLow = {'Number': 0, 'Name': 'Invalid'};
      final jsonTooHigh = {'Number': 7, 'Name': 'Invalid'};

      expect(
        () => AQICategory.fromJson(jsonTooLow),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => AQICategory.fromJson(jsonTooHigh),
        throwsA(isA<RangeError>()),
      );
    });

    test('toJson works correctly', () {
      final category = AQICategory(
        number: 3,
        name: 'Unhealthy for Sensitive Groups',
      );
      final json = category.toJson();

      expect(json['Number'], 3);
      expect(json['Name'], 'Unhealthy for Sensitive Groups');
    });

    test('color returns correct color for each category', () {
      expect(AQICategory(number: 1, name: 'Good').color, nurturingZoneColor);
      expect(AQICategory(number: 2, name: 'Moderate').color, mindfulZoneColor);
      expect(
        AQICategory(number: 3, name: 'Unhealthy for Sensitive Groups').color,
        cautiousZoneColor,
      );
      expect(AQICategory(number: 4, name: 'Unhealthy').color, shieldZoneColor);
      expect(
        AQICategory(number: 5, name: 'Very Unhealthy').color,
        shelterZoneColor,
      );
      expect(
        AQICategory(number: 6, name: 'Hazardous').color,
        protectionZoneColor,
      );
    });

    test('toString formats correctly', () {
      final category = AQICategory(number: 1, name: 'Good');
      expect(category.toString(), 'AQICategory 1: Good');
    });

    test('constants define valid range', () {
      expect(AQICategory.minCategoryNumber, 1);
      expect(AQICategory.maxCategoryNumber, 6);
    });
  });
}
