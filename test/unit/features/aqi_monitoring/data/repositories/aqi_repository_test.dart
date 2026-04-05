import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import '../../../../../helpers/timezone_helper.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';

// Test exception hierarchy for testing
class AQIException implements Exception {
  AQIException(this.message);
  final String message;
  @override
  String toString() => 'AQIException: $message';
}

class NetworkException extends AQIException {
  NetworkException(String message) : super('Network error: $message');
}

class InvalidZipcodeException extends AQIException {
  InvalidZipcodeException(String message) : super('Invalid: $message');
}

class NoDataForZipcodeException extends AQIException {
  NoDataForZipcodeException(String message) : super('NoData: $message');
}

// Concrete implementation for testing abstract interface
class TestAQIRepository implements AQIRepository {
  @override
  Future<AQIData> getAQIByZipcode(String zipcode) {
    // Create test data with minimal required fields
    final pollutants = [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 35,
        category: AQICategory(number: 1, name: 'Good'),
      ),
    ];

    return Future.value(
      AQIData(
        pollutants: pollutants,
        dateObserved: '2025-03-24',
        hourObserved: 12,
      ),
    );
  }

  @override
  Future<bool> hasDataForZipCode(String zipCode) async {
    // Simple implementation for testing - always return true
    return true;
  }

  @override
  Future<AQIData?> getCachedDataForZipCode(String zipCode) async {
    // Return the same test data as getAQIByZipcode
    final pollutants = [
      PollutantData(
        parameterName: 'PM2.5',
        aqi: 35,
        category: AQICategory(number: 1, name: 'Good'),
      ),
    ];

    return AQIData(
      pollutants: pollutants,
      dateObserved: '2025-03-24',
      hourObserved: 12,
    );
  }

  @override
  Future<void> clearCache() async {
    // No-op implementation for testing
    return;
  }

  @override
  bool isFromCache() {
    // Simple implementation for testing - always return false
    return false;
  }

  @override
  Duration getCacheAge(String zipCode) {
    // Simple implementation for testing - always return 1 hour
    return const Duration(hours: 1);
  }
}

void main() {
  // Initialize timezone data before tests
  setUpAll(() {
    initializeTimeZonesForTest();
  });

  group('AQIRepository Interface Contract', () {
    late AQIRepository repository;

    setUp(() {
      repository = TestAQIRepository();
    });

    test('Should enforce getAQIByZipcode method signature', () async {
      // Verify method exists with correct return type
      final result = await repository.getAQIByZipcode('12345');
      expect(result, isA<AQIData>());
    });

    test('Should return AQIData with pollutants', () async {
      final result = await repository.getAQIByZipcode('12345');
      expect(result.pollutants, isNotEmpty);
    });
  });

  group('Exception Hierarchy Validation', () {
    test('Should have proper exception inheritance', () {
      expect(AQIException('Test'), isA<Exception>());
      expect(NetworkException('Test'), isA<AQIException>());
      expect(InvalidZipcodeException('Test'), isA<AQIException>());
      expect(NoDataForZipcodeException('Test'), isA<AQIException>());
    });

    test('Exceptions should carry meaningful messages', () {
      const message = 'Test error';
      expect(AQIException(message).toString(), contains(message));
      expect(NetworkException(message).toString(), contains('Network'));
      expect(InvalidZipcodeException(message).toString(), contains('Invalid'));
      expect(NoDataForZipcodeException(message).toString(), contains('NoData'));
    });
  });
}
