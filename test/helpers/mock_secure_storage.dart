/// A simple mock for secure storage used in tests
/// 
/// This avoids implementing the full FlutterSecureStorage interface
/// by just providing the methods we need for testing
class MockSecureStorage {
  final Map<String, String> _storage = {};
  
  Future<String?> read({required String key}) async => _storage[key];
  
  Future<void> write({required String key, required String? value}) async {
    if (value != null) {
      _storage[key] = value;
    }
  }
  
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }
  
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key);
  }
  
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_storage);
  }
  
  Future<void> deleteAll() async {
    _storage.clear();
  }
} 