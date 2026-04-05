import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/aqi_screen.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/aqi_result_display.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'aqi_screen_test.mocks.dart';

@GenerateMocks([AQIProvider, AQIRepository])
void main() {
  group('AQIScreen Widget Tests', () {
    late MockAQIProvider mockProvider;

    setUp(() {
      mockProvider = MockAQIProvider();
    });

    testWidgets('shows loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      // Set up mock provider
      when(mockProvider.isLoading).thenReturn(true);
      when(mockProvider.data).thenReturn(null);
      when(mockProvider.error).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: const AQIScreen(),
          ),
        ),
      );

      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(loadingText), findsOneWidget);

      // Verify other states are not shown
      expect(find.byType(AQIResultDisplay), findsNothing);
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('shows error view when error is present', (
      WidgetTester tester,
    ) async {
      // Set up mock provider with error
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.data).thenReturn(null);
      when(mockProvider.error).thenReturn('Test error message');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: const AQIScreen(),
          ),
        ),
      );

      // Verify error view is displayed
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify other states are not shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AQIResultDisplay), findsNothing);
    });

    testWidgets('shows empty state view when no data and no error', (
      WidgetTester tester,
    ) async {
      // Set up mock provider with no data
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.data).thenReturn(null);
      when(mockProvider.error).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: const AQIScreen(),
          ),
        ),
      );

      // Verify empty state view is displayed
      expect(find.text(apiConnectionErrorMessage), findsOneWidget);
      expect(find.text(goBackText), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      // Verify other states are not shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows AQIResultDisplay when data is available', (
      WidgetTester tester,
    ) async {
      // Create a mock AQIData object
      final mockData = MockAQIData();

      // Set up mock provider with data
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.data).thenReturn(mockData);
      when(mockProvider.error).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: const AQIScreen(),
          ),
        ),
      );

      // Verify AQIResultDisplay is shown
      expect(find.byType(AQIResultDisplay), findsOneWidget);

      // Verify other states are not shown
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Try Again'), findsNothing);
      expect(find.text('No air quality data found.'), findsNothing);
    });

    testWidgets('navigates back when back button is pressed', (
      WidgetTester tester,
    ) async {
      // Track navigation
      bool didPop = false;

      // Set up mock provider
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.data).thenReturn(null);
      when(mockProvider.error).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: const AQIScreen(),
          ),
          navigatorObservers: [
            _MockNavigatorObserver(
              onPop: () {
                didPop = true;
              },
            ),
          ],
        ),
      );

      // Verify BloomAppBar is present
      expect(find.byType(BloomAppBar), findsOneWidget);

      // Find the back button in BloomAppBar by finding the icon inside the BloomAppBar
      await tester.pumpAndSettle();

      // Tap the back button
      await tester.tap(
        find.descendant(
          of: find.byType(BloomAppBar),
          matching: find.byIcon(Icons.arrow_back_ios),
        ),
      );
      await tester.pumpAndSettle();

      // Verify navigation happened
      expect(didPop, true);
    });
  });
}

// Simple mock for AQIData
class MockAQIData implements AQIData {
  @override
  PollutantData? getPM25() {
    return PollutantData(
      parameterName: 'PM2.5',
      aqi: 35,
      category: AQICategory(number: 1, name: 'Good'),
    );
  }

  @override
  List<PollutantData> get pollutants => [
    PollutantData(
      parameterName: 'PM2.5',
      aqi: 35,
      category: AQICategory(number: 1, name: 'Good'),
    ),
  ];

  @override
  String? get reportingArea => 'Test City';

  @override
  String? get stateCode => 'TC';

  @override
  String get dateObserved => '2025-03-24';

  @override
  int get hourObserved => 12;

  @override
  DateTime get observationDate => DateTime(2025, 3, 24, 12);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Navigator observer to track navigation events
class _MockNavigatorObserver extends NavigatorObserver {

  _MockNavigatorObserver({this.onPop});
  final Function? onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop?.call();
  }
}
