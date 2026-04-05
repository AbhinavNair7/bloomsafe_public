import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'responsive_test_helper.dart';

/// A test wrapper widget that provides common dependencies and configuration
/// for widget testing.
///
/// This helps standardize widget tests by providing:
/// - Consistent MaterialApp wrapper
/// - Provider setup
/// - Theme configuration
/// - Screen size configuration for responsive testing
class TestApp extends StatelessWidget {

  /// Create a TestApp with the given test widget
  const TestApp({
    super.key,
    required this.child,
    this.providers,
    this.theme,
    this.locale,
    this.deviceType,
  });
  /// The widget being tested
  final Widget child;

  /// Additional providers to include in test
  final List<SingleChildWidget>? providers;

  /// Optional theme to override default
  final ThemeData? theme;

  /// Optional locale for testing localization
  final Locale? locale;

  /// Optional device type for responsive testing
  final DeviceType? deviceType;

  @override
  Widget build(BuildContext context) {
    // If no providers, just return a simple MaterialApp
    if (providers == null || providers!.isEmpty) {
      return _buildMaterialApp();
    }

    // Otherwise wrap with providers
    return MultiProvider(providers: providers!, child: _buildMaterialApp());
  }

  /// Builds the MaterialApp with consistent configuration
  MaterialApp _buildMaterialApp() {
    return MaterialApp(
      title: 'BloomSafe Tests',
      debugShowCheckedModeBanner: false,
      theme:
          theme ??
          ThemeData(
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
      locale: locale,
      supportedLocales: const [Locale('en', 'US')],
      home: Material(child: child),
    );
  }
}

/// Helper function to wrap a widget with TestApp for testing
Widget testableWidget({
  required Widget child,
  List<SingleChildWidget>? providers,
  ThemeData? theme,
  Locale? locale,
  DeviceType? deviceType,
}) {
  return TestApp(
    providers: providers,
    theme: theme,
    locale: locale,
    deviceType: deviceType,
    child: child,
  );
}

/// Helper function to set up responsive widget test
Future<void> setupResponsiveTest(
  WidgetTester tester, {
  required Widget widget,
  DeviceType deviceType = DeviceType.mobile,
  List<SingleChildWidget>? providers,
  ThemeData? theme,
}) async {
  // Set up screen size
  await ResponsiveTestHelper.setScreenSize(tester, deviceType);
  
  // Pump widget with proper wrapping
  await tester.pumpWidget(
    testableWidget(
      child: widget,
      providers: providers,
      theme: theme,
      deviceType: deviceType,
    ),
  );
  
  // Register tearDown to reset screen size
  addTearDown(() {
    ResponsiveTestHelper.resetScreenSize(tester);
  });
}
