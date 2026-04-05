import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// TestEnvironment provides utilities for test environment configuration
class TestEnvironment {
  
  /// Factory constructor to return the singleton instance
  factory TestEnvironment() => _instance;
  
  /// Private constructor for singleton pattern
  TestEnvironment._internal();
  /// Singleton instance 
  static final TestEnvironment _instance = TestEnvironment._internal();
  
  /// Whether the environment has been initialized
  bool _initialized = false;
  
  /// The loaded app configuration
  AppConfig? _appConfig;
  
  /// Get the initialized app configuration
  AppConfig get appConfig {
    if (!_initialized) {
      throw Exception('TestEnvironment not initialized. Call ensureInitialized() first.');
    }
    return _appConfig!;
  }
  
  /// Ensures the test environment is initialized
  /// Returns the AppConfig instance
  Future<AppConfig> ensureInitialized() async {
    if (_initialized) {
      return _appConfig!;
    }
    
    try {
      // First, ensure the environment configuration is loaded
      await _loadTestEnvironment();
      
      // Then initialize the app configuration
      _appConfig = AppConfig();
      await _appConfig!.initialize();
      
      _initialized = true;
      return _appConfig!;
    } catch (e) {
      Logger.error('Failed to initialize test environment: $e');
      // Provide fallback values for tests
      _setupTestDefaults();
      _appConfig = AppConfig();
      _initialized = true;
      return _appConfig!;
    }
  }
  
  /// Loads the test environment from .env.dev only
  Future<void> _loadTestEnvironment() async {
    try {
      // Try to load .env.dev for test environment
      await dotenv.load(fileName: '.env.dev');
      Logger.debug('Test environment loaded from .env.dev');
    } catch (e) {
      Logger.warning('Failed to load .env.dev: $e. Using test defaults.');
      // Set up fallback values instead of trying removed .env file
      _setupTestDefaults();
    }
  }
  
  /// Sets up default values for the test environment
  void _setupTestDefaults() {
    // Default to mock API for tests
    dotenv.env[EnvConfig.envMockApi] = 'true';
    
    // Use test API key for isolated testing
    dotenv.env[EnvConfig.envAirnowApiKey] = 'test_api_key_12345';
    
    // Disable rate limiting for tests
    dotenv.env[EnvConfig.envDisableRateLimit] = 'true';
    
    // Set default limits
    dotenv.env['MAX_REQUESTS_PER_HOUR'] = '500';
    dotenv.env['MAX_REQUESTS_PER_MINUTE'] = '5';
    
    // Disable Firebase Analytics for tests
    dotenv.env[EnvConfig.envFirebaseAnalyticsEnabled] = 'false';
  }
  
  /// Reset the test environment for a new test
  void reset() {
    _initialized = false;
    _appConfig = null;
  }
  
  /// Use mock API mode (safe default for tests)
  Future<void> useMockApiMode() async {
    final config = await ensureInitialized();
    config.useMockApiMode();
  }
  
  /// Use real API mode (only when needed)
  Future<bool> useRealApiMode() async {
    final config = await ensureInitialized();
    return config.useRealApiMode();
  }
} 