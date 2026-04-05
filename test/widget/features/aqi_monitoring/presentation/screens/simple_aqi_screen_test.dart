import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/aqi_screen.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/aqi_result_display.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/severity_gauge.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:bloomsafe/core/error/error_processor.dart';

// Custom test provider that doesn't need mockito
class TestAQIProvider extends ChangeNotifier implements AQIProvider {
  bool _loading = false;
  AQIData? _data;
  String? _error;
  ErrorCategory? _errorCategory;
  bool _isFromCache = false;
  String? _lastZipcode;

  @override
  AQIRepository get repository => throw UnimplementedError();

  @override
  AQIData? get data => _data;

  @override
  String? get error => _error;

  @override
  ErrorCategory? get errorCategory => _errorCategory;

  @override
  bool get isLoading => _loading;

  @override
  bool get isFromCache => _isFromCache;

  @override
  String? get lastZipcode => _lastZipcode;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setData(AQIData? value) {
    _data = value;
    notifyListeners();
  }

  @override
  void setError(
    String? value, {
    ErrorCategory category = ErrorCategory.unknown,
  }) {
    _error = value;
    _errorCategory = category;
    notifyListeners();
  }

  void setIsFromCache(bool value) {
    _isFromCache = value;
    notifyListeners();
  }

  void setLastZipcode(String? value) {
    _lastZipcode = value;
    notifyListeners();
  }

  @override
  Future<void> fetchData(String zipcode) {
    throw UnimplementedError();
  }

  @override
  void clearData() {
    _data = null;
    _error = null;
    _loading = false;
    _lastZipcode = null;
    _isFromCache = false;
    notifyListeners();
  }

  @override
  Future<void> retry() async {
    if (_lastZipcode != null) {
      await fetchData(_lastZipcode!);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  testWidgets(
    'AQIScreen shows loading spinner when AQIProvider isLoading is true',
    (WidgetTester tester) async {
      // Create test provider and set it to loading state
      final testProvider = TestAQIProvider()..setLoading(true);

      // Build widget under test
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AQIProvider>.value(
            value: testProvider,
            child: const AQIScreen(),
          ),
        ),
      );

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AQIResultDisplay), findsNothing);
      expect(find.byType(SeverityGauge), findsNothing);
    },
  );

  testWidgets('AQIScreen shows error state when provider has an error', (
    WidgetTester tester,
  ) async {
    // Create test provider and set it to error state
    final testProvider = TestAQIProvider()..setError('Error message');

    // Build widget under test
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AQIProvider>.value(
          value: testProvider,
          child: const AQIScreen(),
        ),
      ),
    );

    // Verify error state
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Error message'), findsOneWidget);
    expect(find.byType(AQIResultDisplay), findsNothing);
    expect(
      find.byType(ElevatedButton),
      findsOneWidget,
    ); // For "Try Again" button
  });

  testWidgets('AQIScreen has back button in app bar', (
    WidgetTester tester,
  ) async {
    // Create test provider
    final testProvider = TestAQIProvider();

    // Build widget under test
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AQIProvider>.value(
          value: testProvider,
          child: const AQIScreen(),
        ),
      ),
    );

    // Find app bar and verify back button exists
    final appBarFinder = find.byType(BloomAppBar);
    expect(appBarFinder, findsOneWidget);

    final backButtonFinder = find.descendant(
      of: appBarFinder,
      matching: find.byIcon(Icons.arrow_back_ios),
    );
    expect(backButtonFinder, findsOneWidget);
  });

  testWidgets('AQIScreen shows data when AQIProvider has data', (
    WidgetTester tester,
  ) async {
    // Set a larger window size to avoid button being offscreen
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    // Sample AQI data
    final aqi = AQIData(
      pollutants: [
        PollutantData(
          parameterName: 'PM2.5',
          aqi: 35,
          category: AQICategory(number: 1, name: 'Good'),
        ),
      ],
      reportingArea: 'Test City',
      stateCode: 'TC',
      dateObserved: '2025-03-15',
      hourObserved: 12,
    );

    // Create test provider and set data
    final testProvider = TestAQIProvider()..setData(aqi);

    // Build widget under test
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AQIProvider>.value(
          value: testProvider,
          child: const AQIScreen(),
        ),
      ),
    );

    // Verify data state
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AQIResultDisplay), findsOneWidget);
    expect(find.byType(SeverityGauge), findsOneWidget);
    expect(find.textContaining('Test City'), findsOneWidget);

    // Check for Nurturing Zone recommendations
    expect(find.text(nurturingRec1), findsOneWidget);
    expect(find.text(nurturingRec2), findsOneWidget);
    expect(find.text(nurturingRec3), findsOneWidget);

    // Reset the surface size
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('AQIScreen "Check Another Location" button triggers navigation', (
    WidgetTester tester,
  ) async {
    // Set a larger window size to avoid button being offscreen
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    // Sample AQI data
    final aqi = AQIData(
      pollutants: [
        PollutantData(
          parameterName: 'PM2.5',
          aqi: 35,
          category: AQICategory(number: 1, name: 'Good'),
        ),
      ],
      reportingArea: 'Test City',
      stateCode: 'TC',
      dateObserved: '2025-03-15',
      hourObserved: 12,
    );

    // Create test provider and set data
    final testProvider = TestAQIProvider()..setData(aqi);

    // Build widget under test with navigation observer
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AQIProvider>.value(
          value: testProvider,
          child: const AQIScreen(),
        ),
        navigatorObservers: [TestNavigatorObserver()],
      ),
    );

    // Find and tap the "Check Another Location" button
    await tester.tap(
      find.text(checkAnotherLocationButtonText),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // Reset the surface size
    await tester.binding.setSurfaceSize(null);
  });
}

// Simple navigator observer for testing
class TestNavigatorObserver extends NavigatorObserver {

  TestNavigatorObserver({this.onPop});
  final Function()? onPop;

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop?.call();
    super.didPop(route, previousRoute);
  }
}
