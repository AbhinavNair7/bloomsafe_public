import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/track_home_page.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/core/services/analytics_service.dart'
    show AnalyticsServiceInterface;
import '../../helpers/mock_service_locator.dart';
import 'package:get_it/get_it.dart';

/// A more direct mock repository for testing error messages
class DirectErrorMockRepository implements AQIRepository {

  DirectErrorMockRepository({
    required this.errorMessage,
    this.throwRateLimitException = true,
  });
  final String errorMessage;
  final bool throwRateLimitException;

  @override
  Future<AQIData> getAQIByZipcode(String zipcode) async {
    // Create a small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 100));

    // Always throw the rate limit exception with the specific message
    if (throwRateLimitException) {
      throw RateLimitException(errorMessage);
    } else {
      throw AQIException(errorMessage);
    }
  }

  @override
  Future<bool> hasDataForZipCode(String zipCode) async {
    return false;
  }

  @override
  Future<AQIData?> getCachedDataForZipCode(String zipCode) async {
    return null;
  }

  @override
  Future<void> clearCache() async {
    // No-op for test implementation
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

void main({bool skipSetup = false}) {
  // Use TestAnalyticsService instead of MockAnalyticsService
  late AnalyticsServiceInterface analyticsService;

  setUpAll(() {
    if (!skipSetup) {
      MockServiceLocator.init();
    }
    
    // Create a new instance directly
    analyticsService = MockAnalyticsService();
    
    // Register the service
    final GetIt sl = GetIt.instance;
    if (sl.isRegistered<AnalyticsServiceInterface>()) {
      sl.unregister<AnalyticsServiceInterface>();
    }
    sl.registerSingleton<AnalyticsServiceInterface>(analyticsService);
  });

  tearDownAll(() {
    if (!skipSetup) {
      MockServiceLocator.tearDown();
    }
  });

  group('End-to-End Rate Limit Tests', () {
    // Get a clean rate limiter instance for each test
    late RateLimiter rateLimiter;

    setUp(() {
      // Reset the rate limiter before each test
      RateLimiter.resetForTesting();
    });

    testWidgets('Client-side rate limit message displays correctly', (
      WidgetTester tester,
    ) async {
      // Create a repository that directly throws the client-side rate limit exception
      final repository = DirectErrorMockRepository(
        errorMessage: maxSearchesReachedMessage,
      );

      // Create a provider with the repository
      final provider = AQIProvider(repository, analytics: analyticsService);

      // Build a simplified widget tree with only the components we need
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: provider,
            child: TrackHomePage(
              setAQIResultScreen: (_) {},
              clearAQIResultScreen: () {},
            ),
          ),
        ),
      );

      // Find the text field and enter a zipcode
      await tester.enterText(find.byType(TextFormField), '12345');

      // Find the button and tap it
      await tester.tap(
        find.widgetWithText(ElevatedButton, checkAirQualityButtonText),
      );
      await tester.pump();

      // Wait for error to appear
      await tester.pumpAndSettle();

      // Get all text widgets in the tree for debugging
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      debugPrint(
        '🔍 All text widgets: ${textWidgets.map((w) => w.data).toList()}',
      );

      // Check provider error for debugging
      debugPrint('🔍 Provider error: ${provider.error}');

      // Check for error message
      expect(provider.error, equals(maxSearchesReachedMessage));
      final errorWidget = find.text(maxSearchesReachedMessage);
      expect(
        errorWidget,
        findsOneWidget,
        reason: 'UI should show the rate limit error message',
      );
    });

    testWidgets('API-side rate limit message displays correctly', (
      WidgetTester tester,
    ) async {
      // Create a repository that directly throws the API-side rate limit exception
      final repository = DirectErrorMockRepository(
        errorMessage: apiRateLimitExceededMessage,
      );

      // Create a provider with the repository
      final provider = AQIProvider(repository, analytics: analyticsService);

      // Build a simplified widget tree with only the components we need
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: provider,
            child: TrackHomePage(
              setAQIResultScreen: (_) {},
              clearAQIResultScreen: () {},
            ),
          ),
        ),
      );

      // Find the text field and enter a zipcode
      await tester.enterText(find.byType(TextFormField), '12345');

      // Find the button and tap it
      await tester.tap(
        find.widgetWithText(ElevatedButton, checkAirQualityButtonText),
      );
      await tester.pump();

      // Wait for error to appear
      await tester.pumpAndSettle();

      // Get all text widgets in the tree for debugging
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      debugPrint(
        '🔍 All text widgets: ${textWidgets.map((w) => w.data).toList()}',
      );

      // Check provider error for debugging
      debugPrint('🔍 Provider error: ${provider.error}');

      // Check for error message
      expect(provider.error, equals(apiRateLimitExceededMessage));
      final errorWidget = find.text(apiRateLimitExceededMessage);
      expect(
        errorWidget,
        findsOneWidget,
        reason: 'UI should show the API rate limit error message',
      );
    });

    testWidgets('Generic API error message displays correctly for comparison', (
      WidgetTester tester,
    ) async {
      // Create a repository that throws a generic API error
      final repository = DirectErrorMockRepository(
        errorMessage: apiConnectionErrorMessage,
        throwRateLimitException: false,
      );

      // Create a provider with the repository
      final provider = AQIProvider(repository, analytics: analyticsService);

      // Build a simplified widget tree with only the components we need
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: provider,
            child: TrackHomePage(
              setAQIResultScreen: (_) {},
              clearAQIResultScreen: () {},
            ),
          ),
        ),
      );

      // Find the text field and enter a zipcode
      await tester.enterText(find.byType(TextFormField), '12345');

      // Find the button and tap it
      await tester.tap(
        find.widgetWithText(ElevatedButton, checkAirQualityButtonText),
      );
      await tester.pump();

      // Wait for error to appear
      await tester.pumpAndSettle();

      // Verify provider error is correctly set
      expect(provider.error, equals(apiConnectionErrorMessage));

      // Verify the error is displayed in the UI
      expect(find.text(apiConnectionErrorMessage), findsOneWidget);
    });
  });
}
