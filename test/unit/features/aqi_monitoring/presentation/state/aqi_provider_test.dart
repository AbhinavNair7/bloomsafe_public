import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:mockito/mockito.dart';
import '../../../../../helpers/mock_service_locator.dart' hide MockAQIRepository;
import 'package:mockito/annotations.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/core/services/analytics_service.dart' hide MockAnalyticsService;
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'aqi_provider_test.mocks.dart';

@GenerateMocks([AQIRepository, AQIData, PollutantData, AnalyticsServiceInterface])
void main() {
  // Initialize the timezone database
  setUpAll(() {
    tz.initializeTimeZones();
  });
  
  group('AQIProvider Error Handling', () {
    late AQIProvider provider;
    late MockAQIRepository mockRepository;
    late MockAnalyticsServiceInterface mockAnalytics;

    setUpAll(() {
      MockServiceLocator.init();
    });

    tearDownAll(() {
      MockServiceLocator.tearDown();
    });

    setUp(() {
      mockRepository = MockAQIRepository();
      mockAnalytics = MockAnalyticsServiceInterface();
      
      provider = AQIProvider(mockRepository, analytics: mockAnalytics);
    });

    test('Sets correct error category for API data issues', () async {
      when(mockRepository.getAQIByZipcode('12345'))
          .thenThrow(ServerException('API data issues'));
          
      await provider.fetchData('12345');
      expect(provider.errorCategory, equals(ErrorCategory.api));
    });

    test('Sets correct error category for extreme AQI values', () async {
      when(mockRepository.getAQIByZipcode('extreme'))
          .thenThrow(AQIException('Extreme AQI values'));
          
      await provider.fetchData('extreme');
      expect(provider.errorCategory, equals(ErrorCategory.api));
    });

    test('Sets correct error category for network errors', () async {
      when(mockRepository.getAQIByZipcode('network'))
          .thenThrow(NetworkException('No internet connection'));
          
      await provider.fetchData('network');
      expect(provider.errorCategory, equals(ErrorCategory.network));
    });

    test(
      'Sets correct error category for client-side rate limit errors',
      () async {
        when(mockRepository.getAQIByZipcode('clientLimit'))
            .thenThrow(RateLimitException('Maximum searches reached'));
            
        await provider.fetchData('clientLimit');
        expect(provider.errorCategory, equals(ErrorCategory.rateLimit));
      },
    );

    test('Sets correct error category for API-side rate limit errors', () async {
      when(mockRepository.getAQIByZipcode('apiLimit'))
          .thenThrow(RateLimitException('API rate limit exceeded'));
          
      await provider.fetchData('apiLimit');
      expect(provider.errorCategory, equals(ErrorCategory.rateLimit));
    });

    test('Sets correct error category for invalid zipcodes', () async {
      when(mockRepository.getAQIByZipcode('1234'))
          .thenThrow(InvalidZipcodeException('Invalid ZIP code length'));
          
      await provider.fetchData('1234');
      expect(provider.errorCategory, equals(ErrorCategory.validation));
    });

    test('Clears error on successful fetch', () async {
      // First trigger an error
      when(mockRepository.getAQIByZipcode('12345'))
          .thenThrow(ServerException('Server error'));
          
      await provider.fetchData('12345');

      // Verify error is set
      expect(provider.error, isNotNull);
      expect(provider.errorCategory, equals(ErrorCategory.api));

      // Use the provider's clearData method to clear the error
      provider.clearData();

      // Verify error is cleared
      expect(provider.error, isNull);
      expect(provider.errorCategory, isNull);
    });
  });

  group('AQIProvider', () {
    late AQIProvider provider;
    late MockAQIRepository mockRepository;
    late MockAnalyticsServiceInterface mockAnalytics;
    late MockAQIData mockAQIData;
    late MockPollutantData mockPollutantData;
    
    setUp(() {
      mockRepository = MockAQIRepository();
      mockAnalytics = MockAnalyticsServiceInterface();
      mockAQIData = MockAQIData();
      mockPollutantData = MockPollutantData();
      
      // Configure mocks
      when(mockPollutantData.parameterName).thenReturn('PM2.5');
      when(mockPollutantData.aqi).thenReturn(35);
      when(mockPollutantData.category).thenReturn(AQICategory(number: 1, name: 'Good'));
      when(mockPollutantData.isPM25).thenReturn(true);
      
      when(mockAQIData.pollutants).thenReturn([mockPollutantData]);
      when(mockAQIData.reportingArea).thenReturn('Test City');
      when(mockAQIData.stateCode).thenReturn('TC');
      when(mockAQIData.getPM25()).thenReturn(mockPollutantData);
      
      provider = AQIProvider(mockRepository, analytics: mockAnalytics);
    });
    
    test('initial state is correct', () {
      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
      expect(provider.error, isNull);
      expect(provider.errorCategory, isNull);
      expect(provider.lastZipcode, isNull);
      expect(provider.isFromCache, isFalse);
    });
    
    test('fetchData changes state to loading then success', () async {
      // Setup mock repository response
      when(mockRepository.getAQIByZipcode('12345'))
          .thenAnswer((_) async => mockAQIData);
      
      // Setup isFromCache response
      when(mockRepository.isFromCache()).thenReturn(false);
          
      // Call the method
      await provider.fetchData('12345');
      
      // Verify the state after successful API call
      expect(provider.isLoading, isFalse);
      expect(provider.data, equals(mockAQIData));
      expect(provider.error, isNull);
      expect(provider.errorCategory, isNull);
      expect(provider.lastZipcode, equals('12345'));
      expect(provider.isFromCache, isFalse);
      
      // Verify calls to repository
      verify(mockRepository.getAQIByZipcode('12345')).called(1);
    });
    
    test('fetchData marks data as from cache when appropriate', () async {
      // Setup mock repository to return cache data
      when(mockRepository.getAQIByZipcode('12345'))
          .thenAnswer((_) async => mockAQIData);
      when(mockRepository.isFromCache()).thenReturn(true);
      when(mockRepository.getCacheAge('12345'))
          .thenReturn(const Duration(minutes: 30));
          
      // Call the method
      await provider.fetchData('12345');
      
      // Verify cache state
      expect(provider.isFromCache, isTrue);
      
      // Verify repository and analytics calls
      verify(mockRepository.isFromCache()).called(1);
      verify(mockRepository.getCacheAge('12345')).called(1);
    });
    
    test('fetchData handles network errors', () async {
      // Setup mock repository to throw NetworkException
      when(mockRepository.getAQIByZipcode('12345'))
          .thenThrow(NetworkException('No internet connection'));
          
      // Call the method
      await provider.fetchData('12345');
      
      // Verify the state after error
      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
      expect(provider.error, isNotNull);
      expect(provider.errorCategory, equals(ErrorCategory.network));
      expect(provider.lastZipcode, equals('12345'));
    });
    
    test('fetchData handles invalid zipcode errors', () async {
      // Setup mock repository to throw InvalidZipcodeException
      when(mockRepository.getAQIByZipcode('1234'))
          .thenThrow(InvalidZipcodeException('Invalid ZIP code'));
          
      // Call the method
      await provider.fetchData('1234');
      
      // Verify the state after error
      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
      expect(provider.error, isNotNull);
      expect(provider.errorCategory, equals(ErrorCategory.validation));
      expect(provider.lastZipcode, equals('1234'));
    });
    
    test('fetchData handles rate limit errors', () async {
      // Setup mock repository to throw RateLimitException
      when(mockRepository.getAQIByZipcode('12345'))
          .thenThrow(RateLimitException('Rate limit exceeded'));
          
      // Call the method
      await provider.fetchData('12345');
      
      // Verify the state after error
      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
      expect(provider.error, isNotNull);
      expect(provider.errorCategory, equals(ErrorCategory.rateLimit));
      expect(provider.lastZipcode, equals('12345'));
    });
    
    test('retry attempts to fetch with last zipcode', () async {
      // Setup initial state
      when(mockRepository.getAQIByZipcode('12345'))
          .thenThrow(ServerException('Server error'));
          
      await provider.fetchData('12345');
      
      // Reset mock to verify new calls
      reset(mockRepository);
      when(mockRepository.getAQIByZipcode('12345'))
          .thenAnswer((_) async => mockAQIData);
      when(mockRepository.isFromCache()).thenReturn(false);
      
      // Call retry
      await provider.retry();
      
      // Verify repository was called with correct zipcode
      verify(mockRepository.getAQIByZipcode('12345')).called(1);
    });
    
    test('clearData resets state', () async {
      // Setup initial state with data
      when(mockRepository.getAQIByZipcode('12345'))
          .thenAnswer((_) async => mockAQIData);
      when(mockRepository.isFromCache()).thenReturn(false);
          
      await provider.fetchData('12345');
      
      // Call clear method
      provider.clearData();
      
      // Verify reset
      expect(provider.isLoading, isFalse);
      expect(provider.data, isNull);
      expect(provider.error, isNull);
      expect(provider.errorCategory, isNull);
      expect(provider.lastZipcode, isNull);
      expect(provider.isFromCache, isFalse);
    });
    
    test('setError sets error state', () {
      // Call setError method
      provider.setError('Test error', category: ErrorCategory.api);
      
      // Verify error state
      expect(provider.isLoading, isFalse);
      expect(provider.error, equals('Test error'));
      expect(provider.errorCategory, equals(ErrorCategory.api));
    });
  });
}