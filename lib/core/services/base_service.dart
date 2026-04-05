import 'package:bloomsafe/core/config/environment.dart';

/// Base service class that all services can extend
/// Provides common functionality for environment-aware services
abstract class BaseService {

  /// Constructor
  BaseService() {
    environment = Environment();
  }
  /// The current environment
  late final Environment environment;

  /// Whether the service is initialized
  bool _isInitialized = false;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  /// This should be called before using any other methods
  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Check if the service is initialized
  /// Throws an assertion error if not initialized
  void checkInitialized(String methodName) {
    assert(_isInitialized, 'Service not initialized when calling: $methodName');
  }

  /// Returns true if the current environment is development
  bool get isDev => environment.isDev;

  /// Returns true if the current environment is production
  bool get isProd => environment.isProd;

  /// Get a value from environment variables
  String? getEnvValue(String key) => environment.getValue(key);
}
