import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/utils/pii_sanitizer.dart';

void main() {
  group('PiiSanitizer', () {
    test('should sanitize US zip codes preserving first 3 digits', () {
      expect(PiiSanitizer.sanitizeString('12345'), '123XX');
      expect(PiiSanitizer.sanitizeString('My zip is 12345'), 'My zip is 123XX');
    });

    test('should specially handle zipcode fields', () {
      final input = '12345';
      final result = PiiSanitizer.sanitizeString(input, fieldName: 'zipcode');
      expect(result, '123XX');
      
      // Test all supported field names
      expect(PiiSanitizer.sanitizeString('12345', fieldName: 'zip'), '123XX');
      expect(PiiSanitizer.sanitizeString('12345', fieldName: 'postal_code'), '123XX');
      expect(PiiSanitizer.sanitizeString('12345', fieldName: 'region_code'), '123XX');
    });

    test('should NOT sanitize other data types', () {
      expect(PiiSanitizer.sanitizeString('user@example.com'), 'user@example.com');
      expect(PiiSanitizer.sanitizeString('555-123-4567'), '555-123-4567');
      expect(PiiSanitizer.sanitizeString('192.168.1.1'), '192.168.1.1');
      expect(PiiSanitizer.sanitizeString('123-45-6789'), '123-45-6789');
    });

    test('should sanitize nested maps (zipcodes only)', () {
      final input = {
        'user': {
          'email': 'user@example.com',
          'phone': '555-123-4567',
          'location': {
            'zipcode': '12345',
            'ip': '192.168.1.1',
          },
        },
        'message': 'SSN: 123-45-6789 zipcode 98765',
      };

      final expected = {
        'user': {
          'email': 'user@example.com',
          'phone': '555-123-4567',
          'location': {
            'zipcode': '123XX',
            'ip': '192.168.1.1',
          },
        },
        'message': 'SSN: 123-45-6789 zipcode 987XX',
      };

      // Need to remove sanitization marker for comparison
      final result = PiiSanitizer.sanitizeMap(input);
      final sanitizedWithoutMarker = PiiSanitizer.removeSanitizationMarker(result);
      
      expect(sanitizedWithoutMarker, expected);
    });

    test('should avoid double sanitization', () {
      final input = {'zipcode': '12345', 'email': 'user@example.com'};
      
      // First sanitization
      final firstPass = PiiSanitizer.sanitizeMap(input);
      
      // Second sanitization shouldn't change anything
      final secondPass = PiiSanitizer.sanitizeMap(firstPass);
      
      // Remove markers for comparison
      final firstPassWithoutMarker = PiiSanitizer.removeSanitizationMarker(firstPass);
      final secondPassWithoutMarker = PiiSanitizer.removeSanitizationMarker(secondPass);
      
      expect(firstPassWithoutMarker, secondPassWithoutMarker);
      expect(firstPassWithoutMarker, {'zipcode': '123XX', 'email': 'user@example.com'});
    });

    test('should sanitize lists correctly (zipcodes only)', () {
      final input = [
        'user@example.com',
        {'zipcode': '12345'},
        ['555-123-4567', '12345'],
      ];
      
      final sanitized = PiiSanitizer.sanitizeList(input);
      
      expect(sanitized[0], 'user@example.com');
      
      // Check the nested map (remove marker for comparison)
      final nestedMap = sanitized[1] as Map<String, dynamic>;
      final cleanMap = PiiSanitizer.removeSanitizationMarker(nestedMap);
      expect(cleanMap, {'zipcode': '123XX'});
      
      // Check the nested list
      final nestedList = sanitized[2] as List<dynamic>;
      expect(nestedList[0], '555-123-4567');
      expect(nestedList[1], '123XX');
    });
    
    test('should sanitize analytics parameters (zipcodes only)', () {
      final input = <String, Object?>{
        'zipcode': '12345',
        'email': 'user@example.com',
        'count': 42,
        'timestamp': '2023-05-01',
        'text_with_zip': 'Area 56789 is nice',
      };
      
      final result = PiiSanitizer.sanitizeAnalyticsParams(input);
      
      expect(result['zipcode'], '123XX');
      expect(result['email'], 'user@example.com');
      expect(result['count'], 42); // Numbers shouldn't be affected
      expect(result['timestamp'], '2023-05-01'); // Not PII, shouldn't be affected
      expect(result['text_with_zip'], 'Area 567XX is nice');
      
      // Make sure no marker is present
      expect(result.containsKey(PiiSanitizer.sanitizedMarker), false);
    });
  });
} 