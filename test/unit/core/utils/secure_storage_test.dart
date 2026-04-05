import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  late SecureStorage secureStorage;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    secureStorage = SecureStorage.forTesting(mockStorage);

    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SecureStorage initialization', () {
    test('initializes only once', () async {
      // Call initialize twice
      await secureStorage.initialize();
      await secureStorage.initialize();

      // No assertions needed - just making sure no exceptions occur
    });
  });

  group('API key storage', () {
    test('stores and retrieves API key', () async {
      const testApiKey = 'test_api_key_12345';

      // Store the API key
      final storeResult = await secureStorage.setApiKey(testApiKey);
      expect(storeResult, isTrue);

      // Retrieve the API key
      final retrievedApiKey = await secureStorage.getApiKey();

      // Verify the key was stored and retrieved correctly
      expect(retrievedApiKey, equals(testApiKey));
    });

    test('deletes API key and falls back to development key', () async {
      const testApiKey = 'test_api_key_12345';

      // Store the API key
      await secureStorage.setApiKey(testApiKey);

      // Delete the API key
      final deleteResult = await secureStorage.deleteApiKey();
      expect(deleteResult, isTrue);

      // In test/debug mode, getApiKey will fall back to 'development_api_key'
      final retrievedApiKey = await secureStorage.getApiKey();

      // In debug/test mode, we expect the development key as fallback
      expect(
        retrievedApiKey == 'development_api_key' || retrievedApiKey == null,
        isTrue,
      );
    });
  });

  group('API key validation', () {
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
