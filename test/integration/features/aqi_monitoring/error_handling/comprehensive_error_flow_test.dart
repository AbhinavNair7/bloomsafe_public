import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart'
    show RateLimitException;
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/track_home_page.dart';
import 'package:bloomsafe/core/services/analytics_service.dart'
    show AnalyticsServiceInterface;
import '../../../../helpers/mock_service_locator.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// This test verifies how error messages flow through the application layers
/// from repository exceptions to the UI display.
/// It focuses on the AQI monitoring feature's error handling capabilities,
/// especially for rate limit errors.
///
/// A special mock repository that throws specific error types for testing
class ComprehensiveErrorMockRepository implements AQIRepository {

  ComprehensiveErrorMockRepository({
    required this.errorMessage,
    this.throwRateLimitException = true,
  });
  final String errorMessage;
  final bool throwRateLimitException;

  @override
  Future<AQIData> getAQIByZipcode(String zipcode) async {
    // Create a small delay to simulate network request
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint(
      '🔴 Mock repo throwing error with specific message: "$errorMessage"',
    );

    // Throw the appropriate exception type
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

void main() {
  late MockAnalyticsService mockAnalyticsService;

  setUpAll(() {
    MockServiceLocator.init();
    mockAnalyticsService =
        di.sl<AnalyticsServiceInterface>() as MockAnalyticsService;
  });

  tearDownAll(() {
    MockServiceLocator.tearDown();
  });

  group('Comprehensive Error Flow Test', () {
    testWidgets(
      'Client-side rate limit message flows correctly from repository to UI',
      (WidgetTester tester) async {
        // Create a repository that directly throws the client-side rate limit exception
        final repository = ComprehensiveErrorMockRepository(
          errorMessage: maxSearchesReachedMessage,
        );

        // Create a provider with the repository
        final provider = AQIProvider(
          repository,
          analytics: mockAnalyticsService,
        );

        // Log initial provider state
        debugPrint('🔍 Initial provider error: ${provider.error}');

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

        // Check provider error for debugging
        debugPrint('🔍 Current provider error: ${provider.error}');
        debugPrint(
          '🔍 Does it match expected? ${provider.error == maxSearchesReachedMessage}',
        );

        // Get all text widgets for debugging
        final allText =
            tester
                .widgetList<Text>(find.byType(Text))
                .map((t) => t.data)
                .toList();
        debugPrint('🔍 All text in UI: $allText');

        // Check provider has correct error
        expect(
          provider.error,
          equals(maxSearchesReachedMessage),
          reason: 'Provider should have the correct error message',
        );

        // Verify some error is displayed in the UI
        final errorText = find.text(maxSearchesReachedMessage);
        expect(
          errorText,
          findsOneWidget,
          reason: 'UI should display a rate limit error message',
        );
      },
    );

    testWidgets(
      'API-side rate limit message flows correctly from repository to UI',
      (WidgetTester tester) async {
        // Create a repository that directly throws the API-side rate limit exception
        final repository = ComprehensiveErrorMockRepository(
          errorMessage: apiRateLimitExceededMessage,
        );

        // Create a provider with the repository
        final provider = AQIProvider(
          repository,
          analytics: mockAnalyticsService,
        );

        // Log initial provider state
        debugPrint('🔍 Initial provider error: ${provider.error}');

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

        // Check provider error for debugging
        debugPrint('🔍 Current provider error: ${provider.error}');
        debugPrint(
          '🔍 Does it match expected? ${provider.error == apiRateLimitExceededMessage}',
        );

        // Get all text widgets for debugging
        final allText =
            tester
                .widgetList<Text>(find.byType(Text))
                .map((t) => t.data)
                .toList();
        debugPrint('🔍 All text in UI: $allText');

        // Check provider has correct error
        expect(
          provider.error,
          equals(apiRateLimitExceededMessage),
          reason: 'Provider should have the correct error message',
        );

        // Verify some error is displayed in the UI
        final errorText = find.text(apiRateLimitExceededMessage);
        expect(
          errorText,
          findsOneWidget,
          reason: 'UI should display an API rate limit error message',
        );
      },
    );
  });
}
