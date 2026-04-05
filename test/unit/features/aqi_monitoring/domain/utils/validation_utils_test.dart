import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/validation_utils.dart';
import 'package:bloomsafe/core/constants/strings.dart';

void main() {
  group('AQIValidationUtils', () {
    group('validateZipCode', () {
      test('Valid ZIP codes return null', () {
        const validZips = ['94105', '10001', '20001', '00000', '99999'];
        for (final zip in validZips) {
          expect(AQIValidationUtils.validateZipCode(zip), isNull);
        }
      });

      test('Null or empty ZIP codes return error message', () {
        expect(
          AQIValidationUtils.validateZipCode(null),
          equals(emptyZipCodeError),
        );
        expect(
          AQIValidationUtils.validateZipCode(''),
          equals(emptyZipCodeError),
        );
      });

      test('ZIP codes with incorrect length return error message', () {
        expect(
          AQIValidationUtils.validateZipCode('1234'),
          equals(invalidZipCodeLengthError),
        );
        expect(
          AQIValidationUtils.validateZipCode('123456'),
          equals(invalidZipCodeLengthError),
        );
      });

      test('Non-numeric ZIP codes return error message', () {
        expect(
          AQIValidationUtils.validateZipCode('abcde'),
          equals(nonNumericZipCodeError),
        );
        expect(
          AQIValidationUtils.validateZipCode('a1234'),
          equals(nonNumericZipCodeError),
        );
        expect(
          AQIValidationUtils.validateZipCode('1234a'),
          equals(nonNumericZipCodeError),
        );
      });
    });

    group('isValidZipCodeForApi', () {
      test('Returns true for valid ZIP codes', () {
        const validZips = ['94105', '10001', '20001', '00000', '99999'];
        for (final zip in validZips) {
          expect(AQIValidationUtils.isValidZipCodeForApi(zip), isTrue);
        }
      });

      test('Returns false for invalid ZIP codes', () {
        const invalidZips = ['abcde', '1234', '123456', '', '12a45'];
        for (final zip in invalidZips) {
          expect(AQIValidationUtils.isValidZipCodeForApi(zip), isFalse);
        }

        // Also test null case
        expect(AQIValidationUtils.isValidZipCodeForApi(null), isFalse);
      });
    });

    group('normalizeZipCode', () {
      test('Trims whitespace from ZIP codes', () {
        expect(AQIValidationUtils.normalizeZipCode(' 12345 '), equals('12345'));
        expect(AQIValidationUtils.normalizeZipCode('12345 '), equals('12345'));
        expect(AQIValidationUtils.normalizeZipCode(' 12345'), equals('12345'));
      });
    });

    group('validateZipCodeWithResult', () {
      test('Returns valid result for valid ZIP codes', () {
        const validZips = ['94105', '10001', '20001', '00000', '99999'];
        for (final zip in validZips) {
          final result = AQIValidationUtils.validateZipCodeWithResult(zip);
          expect(result.isValid, isTrue);
          expect(result.message, isNull);
          expect(result.normalizedValue, equals(zip));
        }
      });

      test('Returns invalid result with message for invalid ZIP codes', () {
        const invalidZip = '1234';
        final result = AQIValidationUtils.validateZipCodeWithResult(invalidZip);
        expect(result.isValid, isFalse);
        expect(result.message, equals(invalidZipCodeLengthError));
        expect(result.normalizedValue, equals(invalidZip));
      });

      test('Normalizes ZIP codes with whitespace', () {
        final result = AQIValidationUtils.validateZipCodeWithResult(' 12345 ');
        expect(result.isValid, isTrue);
        expect(result.message, isNull);
        expect(result.normalizedValue, equals('12345'));
      });
    });
  });
}
