import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/utils/encryption_utils.dart';

// Simple mock class that doesn't rely on full implementation
class MockSecureStorage {
  final Map<String, String> _values = {};
  
  Future<String?> read({required String key}) async => _values[key];
  
  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _values[key] = value;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late EncryptionUtils encryptionUtils;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    encryptionUtils = EncryptionUtils.test(mockStorage);
  });

  group('EncryptionUtils', () {
    test('initializes without errors', () async {
      // Should not throw an exception
      await encryptionUtils.initialize();
    });

    test('encrypts and decrypts data correctly', () async {
      await encryptionUtils.initialize();

      const testData = 'This is sensitive test data';

      // Encrypt the data
      final encrypted = await encryptionUtils.encrypt(testData);

      // Ensure encrypted data is not null
      expect(encrypted, isNotNull);

      // Ensure encrypted data is different from original
      expect(encrypted, isNot(equals(testData)));

      // Ensure encrypted data has the IV:encrypted format
      expect(encrypted!.contains(':'), isTrue);

      // Decrypt the data
      final decrypted = await encryptionUtils.decrypt(encrypted);

      // Ensure decrypted data matches original
      expect(decrypted, equals(testData));
    });

    test('handles empty data gracefully', () async {
      await encryptionUtils.initialize();

      const emptyData = '';

      // Encrypt empty data
      final encrypted = await encryptionUtils.encrypt(emptyData);

      // Empty data should be returned as is
      expect(encrypted, equals(emptyData));

      // Decrypt empty data
      final decrypted = await encryptionUtils.decrypt(emptyData);

      // Empty data should be returned as is
      expect(decrypted, equals(emptyData));
    });

    test('hash function generates consistent hash', () {
      const testData = 'password123';

      // Hash the data
      final hash1 = encryptionUtils.hash(testData);
      final hash2 = encryptionUtils.hash(testData);

      // Ensure hash is not null or empty
      expect(hash1, isNotEmpty);

      // Ensure same input produces same hash
      expect(hash1, equals(hash2));

      // Ensure hash is different from input
      expect(hash1, isNot(equals(testData)));

      // Ensure hash is expected length for SHA-256 (64 hex chars)
      expect(hash1.length, equals(64));
    });

    test('isEncrypted identifies encrypted data', () async {
      await encryptionUtils.initialize();

      const testData = 'This is test data';

      // Encrypt the data
      final encrypted = await encryptionUtils.encrypt(testData);

      // Check format detection
      expect(encryptionUtils.isEncrypted(encrypted!), isTrue);
      expect(encryptionUtils.isEncrypted(testData), isFalse);
      expect(encryptionUtils.isEncrypted(''), isFalse);
      expect(encryptionUtils.isEncrypted('invalid:format'), isFalse);
    });

    test('handling invalid encrypted data gracefully', () async {
      await encryptionUtils.initialize();

      // Invalid format
      final invalidEncrypted = 'not_valid_encrypted_data';
      final decrypted = await encryptionUtils.decrypt(invalidEncrypted);

      // Should return null for invalid data
      expect(decrypted, isNull);
    });
  });
}
