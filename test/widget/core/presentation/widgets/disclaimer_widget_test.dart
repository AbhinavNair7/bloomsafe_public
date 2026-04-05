import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/presentation/widgets/disclaimer_widget.dart';

void main() {
  group('DisclaimerWidget Tests', () {
    testWidgets('renders with correct text', (WidgetTester tester) async {
      // Build our widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      // Verify the disclaimer text is displayed
      expect(
        find.text(
          'For informational purposes only. Seek a healthcare professional for medical advice.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('has correct styling and decoration', (
      WidgetTester tester,
    ) async {
      // Build our widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      // Find the Padding widget
      final paddingFinder = find.byType(Padding).first;
      final padding = tester.widget<Padding>(paddingFinder);

      // Verify text is present
      final textFinder = find.byType(Text);
      final text = tester.widget<Text>(textFinder);

      // Verify text alignment is centered
      expect(text.textAlign, TextAlign.center);

      // Verify text style has the expected color (Colors.black54 as used in the widget)
      expect(text.style!.color, Colors.black54);
    });
  });
}
