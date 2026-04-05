import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/aqi_result_display.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/severity_gauge.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  // Initialize timezone data
  setUpAll(() {
    tz.initializeTimeZones();
  });

  group('AQI Result Display Widget Tests', () {
    // Create test AQI data for different severity levels
    AQIData createTestAQIData(int aqi, String reportingArea, String stateCode) {
      return AQIData(
        pollutants: [
          PollutantData(
            parameterName: 'PM2.5',
            aqi: aqi,
            category: AQICategory(
              number:
                  aqi <= 50
                      ? 1
                      : aqi <= 100
                      ? 2
                      : aqi <= 150
                      ? 3
                      : aqi <= 200
                      ? 4
                      : aqi <= 300
                      ? 5
                      : 6,
              name:
                  aqi <= 50
                      ? 'Good'
                      : aqi <= 100
                      ? 'Moderate'
                      : aqi <= 150
                      ? 'Unhealthy for Sensitive Groups'
                      : aqi <= 200
                      ? 'Unhealthy'
                      : aqi <= 300
                      ? 'Very Unhealthy'
                      : 'Hazardous',
            ),
          ),
        ],
        reportingArea: reportingArea,
        stateCode: stateCode,
        dateObserved: '2025-03-15',
        hourObserved: 12,
        localTimeZone: 'EST', // Added timezone to prevent parsing issues
      );
    }

    testWidgets('renders with Nurturing Zone data', (
      WidgetTester tester,
    ) async {
      // Mock data for Nurturing Zone (0-50)
      final mockData = createTestAQIData(25, 'Boston', 'MA');

      // Create a simple mock AQIProvider
      final mockProvider = MockAQIProvider();
      when(mockProvider.data).thenReturn(mockData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AQIProvider>.value(
              value: mockProvider,
              child: AQIResultDisplay(
                data: mockData,
                onCheckAnotherLocation: () {},
                onShareResults: () {},
              ),
            ),
          ),
        ),
      );

      // Set a larger surface size to ensure buttons are visible
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();

      // Verify location and severity info is displayed
      expect(find.textContaining('Boston, MA'), findsOneWidget);
      expect(find.byType(SeverityGauge), findsOneWidget);

      // Verify "What this means" section with correct Nurturing Zone health impact
      expect(find.text(whatThisMeansTitle), findsOneWidget);
      expect(find.text(nurturingZoneHealthImpact), findsOneWidget);

      // Verify recommendations are appropriate for Nurturing Zone
      expect(find.text(recommendedActionsTitle), findsOneWidget);
      expect(find.text(nurturingRec1), findsOneWidget);
      expect(find.text(nurturingRec2), findsOneWidget);
      expect(find.text(nurturingRec3), findsOneWidget);

      // Verify action buttons
      expect(find.text(checkAnotherLocationButtonText), findsOneWidget);
      expect(find.text(shareResultsButtonText), findsOneWidget);

      // Reset the surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders with Mindful Zone data', (WidgetTester tester) async {
      // Mock data for Mindful Zone (51-100)
      final mockData = createTestAQIData(75, 'Seattle', 'WA');

      // Create a simple mock AQIProvider
      final mockProvider = MockAQIProvider();
      when(mockProvider.data).thenReturn(mockData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AQIProvider>.value(
              value: mockProvider,
              child: AQIResultDisplay(
                data: mockData,
                onCheckAnotherLocation: () {},
                onShareResults: () {},
              ),
            ),
          ),
        ),
      );

      // Set a larger surface size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();

      // Verify location info
      expect(find.textContaining('Seattle, WA'), findsOneWidget);

      // Verify correct health impact for Mindful Zone
      expect(find.text(mindfulZoneHealthImpact), findsOneWidget);

      // Verify recommendations for Mindful Zone
      expect(find.text(mindfulRec1), findsOneWidget);
      expect(find.text(mindfulRec2), findsOneWidget);
      expect(find.text(mindfulRec3), findsOneWidget);

      // Reset the surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('renders with Protection Zone data', (
      WidgetTester tester,
    ) async {
      // Mock data for Protection Zone (301+)
      final mockData = createTestAQIData(350, 'Los Angeles', 'CA');

      // Create a simple mock AQIProvider
      final mockProvider = MockAQIProvider();
      when(mockProvider.data).thenReturn(mockData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AQIProvider>.value(
              value: mockProvider,
              child: AQIResultDisplay(
                data: mockData,
                onCheckAnotherLocation: () {},
                onShareResults: () {},
              ),
            ),
          ),
        ),
      );

      // Set a larger surface size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();

      // Verify location info
      expect(find.textContaining('Los Angeles, CA'), findsOneWidget);

      // Verify correct health impact for Protection Zone
      expect(find.text(protectionZoneHealthImpact), findsOneWidget);

      // Verify recommendations for Protection Zone
      expect(find.text(protectionRec1), findsOneWidget);
      expect(find.text(protectionRec2), findsOneWidget);
      expect(find.text(protectionRec3), findsOneWidget);

      // Reset the surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('handles empty or null data', (WidgetTester tester) async {
      // Create a mock provider with null data
      final mockProvider = MockAQIProvider();
      when(mockProvider.data).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AQIProvider>.value(
              value: mockProvider,
              child: const AQIResultDisplay(
                data: null,
                onCheckAnotherLocation: null,
                onShareResults: null,
              ),
            ),
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('gets data from provider when not directly provided', (
      WidgetTester tester,
    ) async {
      // Mock data for provider
      final mockData = createTestAQIData(125, 'Chicago', 'IL');

      // Create a mock provider with data
      final mockProvider = MockAQIProvider();
      when(mockProvider.data).thenReturn(mockData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AQIProvider>.value(
              value: mockProvider,
              child: const AQIResultDisplay(
                data: null, // No direct data, should get from provider
                onCheckAnotherLocation: null,
                onShareResults: null,
              ),
            ),
          ),
        ),
      );

      // Set a larger surface size
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpAndSettle();

      // Verify Chicago data is displayed
      expect(find.textContaining('Chicago, IL'), findsOneWidget);

      // Verify correct health impact for Cautious Zone (101-150)
      expect(find.text(cautiousZoneHealthImpact), findsOneWidget);

      // Reset the surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}

// Simple test repository class
class TestAQIRepository implements AQIRepository {
  @override
  Future<AQIData> getAQIByZipcode(String zipcode) async {
    throw UnimplementedError();
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
    // No-op implementation for testing
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

class MockAQIProvider extends Mock implements AQIProvider {
  @override
  AQIData? get data => super.noSuchMethod(
    Invocation.getter(#data),
    returnValue: AQIData(
      pollutants: [],
      reportingArea: '',
      stateCode: '',
      dateObserved: '',
      hourObserved: 0,
    ),
  );

  @override
  void clearData() =>
      super.noSuchMethod(Invocation.method(#clearData, []), returnValue: null);
}
