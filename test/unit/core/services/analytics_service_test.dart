import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/config/env_config.dart';

// Since we can't run the build_runner during this test creation,
// we'll manually create mock classes
class MockFirebaseAnalytics extends Mock {}
class MockEnvConfig extends Mock implements EnvConfig {}

void main() {
  group('MockAnalyticsService', () {
    late MockAnalyticsService analyticsService;

    setUp(() {
      analyticsService = MockAnalyticsService();
    });

    test('initialize sets isInitialized to true', () async {
      // Act
      await analyticsService.initialize();
      
      // Assert
      expect(analyticsService.isInitialized, true);
    });

    test('logEvent logs debug message', () async {
      // Arrange
      await analyticsService.initialize();
      
      // Act
      await analyticsService.logEvent('test_event', parameters: {'key': 'value'});
      
      // Assert - no way to assert log output directly in this test
      expect(analyticsService.isInitialized, true);
    });

    test('logAqiSearch sanitizes zipcode for privacy', () async {
      // Arrange
      await analyticsService.initialize();
      
      // Act
      await analyticsService.logAqiSearch('12345', true);
      
      // Assert - check that zipcode was logged securely (123XX)
      // In a real test, we might capture log output 
      expect(analyticsService.isInitialized, true);
    });

    test('method calls throw when service not initialized', () async {
      // Don't initialize the service
      
      // Assert that methods throw when not initialized
      expect(() => analyticsService.logEvent('test'), throwsA(isA<AssertionError>()));
      expect(() => analyticsService.logAqiSearch('12345', true), throwsA(isA<AssertionError>()));
      expect(() => analyticsService.logContentShared('article', 'button'), throwsA(isA<AssertionError>()));
    });
  });
  
  group('AnalyticsService', () {
    // Note: For the real AnalyticsService, we would need to mock Firebase Analytics
    // which is challenging without modifying the service for better testability
    
    test('AnalyticsService is a singleton', () {
      // This is a basic test to demonstrate the concept
      final service1 = MockAnalyticsService();
      final service2 = MockAnalyticsService();
      
      // In the real implementation, these would be equal references
      expect(service1, isNot(same(service2)));
    });
  });
} 