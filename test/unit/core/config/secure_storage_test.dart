import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../helpers/test_setup.dart';

// Simple mock implementation of FlutterSecureStorage for testing
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    required String key,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    required String key,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    required String? value,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<void> delete({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    required String key,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return Map<String, String>.from(_storage);
  }

  @override
  Future<void> deleteAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(setupTestEnvironment);

  group('SecureStorage', () {
    late SecureStorage secureStorage;
    late MockSecureStorage mockStorage;

    setUp(() {
      // Create a mock storage for testing
      mockStorage = MockSecureStorage();

      // Create a secure storage with the mock
      secureStorage = SecureStorage.forTesting(mockStorage);
    });

    test('stores and retrieves API key', () async {
      // Arrange
      const testApiKey = 'test_api_key_123';

      // Act - store the API key
      final storeResult = await secureStorage.setApiKey(testApiKey);

      // Assert - storage was successful
      expect(storeResult, isTrue);

      // Retrieve the API key and check it matches
      final retrievedKey = await secureStorage.getApiKey();
      expect(retrievedKey, equals(testApiKey));
    });

    test('deletes API key', () async {
      const testApiKey = 'test_api_key_12345';

      // Store the API key
      await secureStorage.setApiKey(testApiKey);

      // Delete the API key
      final deleteResult = await secureStorage.deleteApiKey();
      expect(deleteResult, isTrue);

      // Check that key was deleted
      final retrievedApiKey = await secureStorage.getApiKey();

      // After deletion, retrievedApiKey should be null
      expect(retrievedApiKey, isNull);
    });

    test('validates API key format correctly', () {
      // Test valid API key format (UUID format)
      expect(
        secureStorage.isValidApiKeyFormat(
          '8d6079e5-7eef-4c16-b92a-4fc00c3f6b9d',
        ),
        isTrue,
      );

      // Test invalid API key formats
      expect(secureStorage.isValidApiKeyFormat(''), isFalse);
      expect(secureStorage.isValidApiKeyFormat('short'), isFalse);
      expect(
        secureStorage.isValidApiKeyFormat('valid_api_key_12345'),
        isFalse,
      ); // Not a UUID
    });
  });
}
