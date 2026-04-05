import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'test_environment.dart';

/// ApiRateLimiter helps manage API calls during testing
/// to prevent exceeding rate limits
class ApiRateLimiter {
  
  /// Factory constructor to return the singleton instance
  factory ApiRateLimiter() => _instance;
  
  /// Private constructor for singleton pattern
  ApiRateLimiter._internal();
  /// Singleton instance
  static final ApiRateLimiter _instance = ApiRateLimiter._internal();

  /// Count of API calls made in the current hour
  int _apiCallsThisHour = 0;
  
  /// Time of last counter reset
  DateTime _lastResetTime = DateTime.now();
  
  /// Maximum calls allowed per test run (conservative limit)
  int _maxCallsPerTestRun = 10;
  
  /// Maximum calls per test run getter
  int get maxCallsPerTestRun => _maxCallsPerTestRun;
  
  /// Sets the maximum calls allowed per test run
  void setMaxCallsPerTestRun(int max) => _maxCallsPerTestRun = max;
  
  /// Gets the count of API calls made in the current hour
  int get apiCallsThisHour => _apiCallsThisHour;

  /// Resets the API call counter
  void reset() {
    _apiCallsThisHour = 0;
    _lastResetTime = DateTime.now();
  }

  /// Records an API call and checks if it exceeds the limit
  /// Returns true if the call is allowed, false if it exceeds the limit
  bool recordApiCall() {
    final now = DateTime.now();
    if (now.difference(_lastResetTime).inHours >= 1) {
      reset();
    }
    _apiCallsThisHour++;
    return _apiCallsThisHour <= _maxCallsPerTestRun;
  }

  /// Prepares the test environment for API testing
  /// Returns true if successful, false otherwise
  Future<bool> prepareRealApiTest({bool forceRealApi = false}) async {
    try {
      // Get app config using the test environment helper
      final testEnv = TestEnvironment();
      final appConfig = await testEnv.ensureInitialized();
      
      // Force real API if requested
      if (forceRealApi) {
        return appConfig.useRealApiMode();
      }
      
      // Default to mock API mode for safety
      appConfig.useMockApiMode();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to prepare API test environment: $e');
      return false;
    }
  }

  /// Simulates reaching the rate limit for testing rate limit handling
  void simulateRateLimitReached() {
    _apiCallsThisHour = _maxCallsPerTestRun + 1;
  }

  /// Adds a random delay to simulate real API conditions
  Future<void> randomDelay() async {
    await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(400)));
  }
}

/// Extension on AppConfig to provide test-specific functionality
extension AppConfigTestExtension on AppConfig {
  /// Forces use of the real API but with a test-specific API key
  /// Returns false if the API key is invalid or missing
  bool useRealApiForTests() {
    return useRealApiMode();
  }

  /// Forces use of the mock API for tests
  void useMockApiForTests() {
    useMockApiMode();
  }
}
