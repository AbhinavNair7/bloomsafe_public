import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/severity_gauge.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/responsive_test_helper.dart';

void main() {
  testWidgets('SeverityGauge displays correct PM2.5 value and zone', (
    WidgetTester tester,
  ) async {
    // Set up responsive test with mobile device dimensions
    await setupResponsiveTest(
      tester,
      deviceType: DeviceType.mobile,
      widget: const SeverityGauge(
        pm25Value: 15,
        animate: false, // Disable animation for testing
      ),
    );

    // Verify the PM2.5 value is displayed
    expect(find.text('15.0'), findsOneWidget);

    // Find the CircularPercentIndicator to verify its color
    final circularIndicator = tester.widget<CircularPercentIndicator>(
      find.byType(CircularPercentIndicator),
    );

    // Check that the progress color matches the Nurturing zone color
    expect(circularIndicator.progressColor, equals(nurturingZoneColor));

    // Locate the horizontal gradient scale container
    final containerFinder = find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final decoration = widget.decoration as BoxDecoration;
        return decoration.gradient is LinearGradient;
      }
      return false;
    });

    // Ensure that such a container exists
    expect(containerFinder, findsOneWidget);

    // Extract decoration from Container and verify gradient colors
    final container = tester.widget<Container>(containerFinder);
    final decoration = container.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    // Verify gradient colors match expected values
    expect(
      gradient.colors,
      equals([
        nurturingZoneColor,
        mindfulZoneColor,
        cautiousZoneColor,
        shieldZoneColor,
        shelterZoneColor,
        protectionZoneColor,
      ]),
    );
  });
  
  testWidgets('SeverityGauge displays correctly on small screens', (
    WidgetTester tester,
  ) async {
    // Test on a small mobile device
    await setupResponsiveTest(
      tester,
      deviceType: DeviceType.smallMobile,
      widget: const SeverityGauge(
        pm25Value: 35,
        animate: false, // Disable animation for testing
      ),
    );

    // Verify the PM2.5 value is displayed
    expect(find.text('35.0'), findsOneWidget);

    // Find the CircularPercentIndicator to verify its color
    final circularIndicator = tester.widget<CircularPercentIndicator>(
      find.byType(CircularPercentIndicator),
    );

    // Get the actual color from the widget and compare with the expected color
    final Color actualColor = circularIndicator.progressColor;
    final Color expectedColor = nurturingZoneColor; // 35 is in nurturing zone
    
    expect(actualColor, equals(expectedColor));
  });
}
