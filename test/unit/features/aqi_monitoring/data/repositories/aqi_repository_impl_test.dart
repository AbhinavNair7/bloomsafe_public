import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/validation_utils.dart';

void main() {
  group('ZIP Code Validation', () {
    test('validateZipCode returns errors for invalid ZIP codes', () {
      // Test null/empty
      expect(AQIValidationUtils.validateZipCode(null), isNotNull);
      expect(AQIValidationUtils.validateZipCode(''), isNotNull);

      // Test wrong length
      expect(AQIValidationUtils.validateZipCode('1234'), isNotNull);
      expect(AQIValidationUtils.validateZipCode('123456'), isNotNull);

      // Test non-numeric
      expect(AQIValidationUtils.validateZipCode('abcde'), isNotNull);
      expect(AQIValidationUtils.validateZipCode('12a45'), isNotNull);
    });

    test('validateZipCode returns null for valid ZIP codes', () {
      expect(AQIValidationUtils.validateZipCode('12345'), isNull);
      expect(AQIValidationUtils.validateZipCode('90210'), isNull);
      expect(AQIValidationUtils.validateZipCode('00000'), isNull);
    });

    test('isValidZipCodeForApi matches validateZipCode behavior', () {
      // Invalid cases should return false
      expect(AQIValidationUtils.isValidZipCodeForApi(null), isFalse);
      expect(AQIValidationUtils.isValidZipCodeForApi(''), isFalse);
      expect(AQIValidationUtils.isValidZipCodeForApi('1234'), isFalse);
      expect(AQIValidationUtils.isValidZipCodeForApi('123456'), isFalse);
      expect(AQIValidationUtils.isValidZipCodeForApi('abcde'), isFalse);

      // Valid cases should return true
      expect(AQIValidationUtils.isValidZipCodeForApi('12345'), isTrue);
      expect(AQIValidationUtils.isValidZipCodeForApi('90210'), isTrue);
      expect(AQIValidationUtils.isValidZipCodeForApi('00000'), isTrue);
    });

    test('normalizeZipCode trims whitespace', () {
      expect(AQIValidationUtils.normalizeZipCode(' 12345 '), equals('12345'));
      expect(AQIValidationUtils.normalizeZipCode('  12345'), equals('12345'));
      expect(AQIValidationUtils.normalizeZipCode('12345  '), equals('12345'));
    });
  });
}
