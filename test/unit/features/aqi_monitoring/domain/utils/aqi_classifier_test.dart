import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/aqi_classifier.dart';

void main() {
  group('AQI Classifier', () {
    group('classifyAQISeverity', () {
      test('classifies AQI value 25 as nurturing', () {
        // Act
        final result = classifyAQISeverity(25);

        // Assert
        expect(result, equals('nurturing'));
      });

      test('classifies AQI value 75 as mindful', () {
        // Act
        final result = classifyAQISeverity(75);

        // Assert
        expect(result, equals('mindful'));
      });

      test('classifies AQI value 125 as cautious', () {
        // Act
        final result = classifyAQISeverity(125);

        // Assert
        expect(result, equals('cautious'));
      });

      test('classifies AQI value 175 as shield', () {
        // Act
        final result = classifyAQISeverity(175);

        // Assert
        expect(result, equals('shield'));
      });

      test('classifies AQI value 250 as shelter', () {
        // Act
        final result = classifyAQISeverity(250);

        // Assert
        expect(result, equals('shelter'));
      });

      test('classifies AQI value 350 as protection', () {
        // Act
        final result = classifyAQISeverity(350);

        // Assert
        expect(result, equals('protection'));
      });

      test('handles negative values by treating them as zero', () {
        // Act
        final result = classifyAQISeverity(-10);

        // Assert
        expect(result, equals('nurturing'));
      });
    });

    group('generateRecommendations', () {
      test(
        'returns recommendations map with zoneName, healthImpact, and recommendations keys',
        () {
          // Act
          final result = generateRecommendations(25);

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('zoneName'), isTrue);
          expect(result.containsKey('healthImpact'), isTrue);
          expect(result.containsKey('recommendations'), isTrue);
        },
      );

      test('returns recommendations for different AQI values', () {
        // Arrange
        final lowAQI = generateRecommendations(25);
        final moderateAQI = generateRecommendations(75);
        final highAQI = generateRecommendations(175);

        // Assert
        expect(lowAQI['zoneName'], isNot(equals(moderateAQI['zoneName'])));
        expect(
          moderateAQI['healthImpact'],
          isNot(equals(highAQI['healthImpact'])),
        );
        expect(lowAQI['recommendations'], isA<List>());
        expect(highAQI['recommendations'], isA<List>());
      });
    });

    group('getAQICategory', () {
      test('returns Good for AQI values 0-50', () {
        // Act
        final result = getAQICategory(25);

        // Assert
        expect(result, equals('Good'));
      });

      test('returns Moderate for AQI values 51-100', () {
        // Act
        final result = getAQICategory(75);

        // Assert
        expect(result, equals('Moderate'));
      });

      test('returns Unhealthy for Sensitive Groups for AQI values 101-150', () {
        // Act
        final result = getAQICategory(125);

        // Assert
        expect(result, equals('Unhealthy for Sensitive Groups'));
      });

      test('returns Unhealthy for AQI values 151-200', () {
        // Act
        final result = getAQICategory(175);

        // Assert
        expect(result, equals('Unhealthy'));
      });

      test('returns Very Unhealthy for AQI values 201-300', () {
        // Act
        final result = getAQICategory(250);

        // Assert
        expect(result, equals('Very Unhealthy'));
      });

      test('returns Hazardous for AQI values above 300', () {
        // Act
        final result = getAQICategory(350);

        // Assert
        expect(result, equals('Hazardous'));
      });
    });

    group('getAQIColor', () {
      test('returns green color for nurturing zone', () {
        // Act
        final result = getAQIColor(25);

        // Assert
        expect(result, equals('#4CAF50')); // Green
      });

      test('returns yellow color for mindful zone', () {
        // Act
        final result = getAQIColor(75);

        // Assert
        expect(result, equals('#FFC107')); // Yellow
      });

      test('returns orange color for cautious zone', () {
        // Act
        final result = getAQIColor(125);

        // Assert
        expect(result, equals('#FF9800')); // Orange
      });

      test('returns red color for shield zone', () {
        // Act
        final result = getAQIColor(175);

        // Assert
        expect(result, equals('#E53935')); // Red
      });

      test('returns purple color for shelter zone', () {
        // Act
        final result = getAQIColor(250);

        // Assert
        expect(result, equals('#9C27B0')); // Purple
      });

      test('returns dark purple color for protection zone', () {
        // Act
        final result = getAQIColor(350);

        // Assert
        expect(result, equals('#673AB7')); // Dark Purple
      });
    });
  });
}
