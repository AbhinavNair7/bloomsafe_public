import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A helper class to assist with responsive widget testing
/// by providing standardized screen sizes and utilities.
class ResponsiveTestHelper {
  /// Device dimensions for common screen sizes (physical pixel dimensions)
  static const Map<DeviceType, Size> deviceDimensions = {
    DeviceType.mobile: Size(390, 844),  // iPhone 13 dimensions
    DeviceType.smallMobile: Size(320, 568),  // iPhone SE dimensions
    DeviceType.tablet: Size(768, 1024),  // iPad dimensions
    DeviceType.desktop: Size(1366, 768),  // Standard laptop dimensions
  };

  /// Device pixel ratios for different device types
  static const Map<DeviceType, double> devicePixelRatios = {
    DeviceType.mobile: 3.0,
    DeviceType.smallMobile: 2.0,
    DeviceType.tablet: 2.0,
    DeviceType.desktop: 1.0,
  };

  /// Sets the screen size for the test
  /// 
  /// [tester] - The WidgetTester instance
  /// [deviceType] - The device type to simulate
  static Future<void> setScreenSize(
    WidgetTester tester,
    DeviceType deviceType,
  ) async {
    final Size size = deviceDimensions[deviceType]!;
    final double pixelRatio = devicePixelRatios[deviceType]!;
    
    tester.binding.window.physicalSizeTestValue = size * pixelRatio;
    tester.binding.window.devicePixelRatioTestValue = pixelRatio;
    
    // Force a frame to ensure the screen dimensions are applied
    await tester.pumpWidget(Container());
  }

  /// Resets the screen size after testing
  static void resetScreenSize(WidgetTester tester) {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  }

  /// Wraps a widget with the TestApp scaffold
  /// 
  /// [child] - The widget to test
  /// [providers] - Optional providers to include
  /// [theme] - Optional theme to use
  static Widget wrapWithScaffold(
    Widget child, {
    List<dynamic>? providers,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: child,
        ),
      ),
    );
  }
}

/// Enum representing different device types for testing
enum DeviceType {
  mobile,
  smallMobile,
  tablet,
  desktop,
}

/// Extension to provide tearDown functionality for WidgetTester
extension ResponsiveTesterExtension on WidgetTester {
  /// Sets up responsive testing environment
  Future<void> setUpResponsiveTest(DeviceType deviceType) async {
    ResponsiveTestHelper.setScreenSize(this, deviceType);
  }
  
  /// Cleans up responsive testing environment
  void tearDownResponsiveTest() {
    ResponsiveTestHelper.resetScreenSize(this);
  }
} 