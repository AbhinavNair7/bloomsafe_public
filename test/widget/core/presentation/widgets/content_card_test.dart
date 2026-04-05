import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/presentation/widgets/content_card.dart';
import '../../../../helpers/responsive_test_helper.dart';
import '../../../../helpers/test_app.dart';

void main() {
  group('ContentCard Widget Tests', () {
    testWidgets('renders with child content', (WidgetTester tester) async {
      // Use the responsive helper to set up test environment
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: const ContentCard(
          child: Text('Test Content'),
        ),
      );
      
      // Verify the child content is displayed
      expect(find.text('Test Content'), findsOneWidget);
      
      // Verify card structure (container with decoration)
      expect(find.byType(Container), findsOneWidget);
    });
    
    testWidgets('applies custom border color', (WidgetTester tester) async {
      final customColor = Colors.purple;
      
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: ContentCard(
          borderColor: customColor,
          child: const Text('Custom Border Color'),
        ),
      );
      
      // Find container and check if the border color is applied
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      
      // Check border color
      expect(border.top.color, equals(customColor));
    });
    
    testWidgets('applies custom background color', (WidgetTester tester) async {
      final customBgColor = Colors.lightBlue;
      
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: ContentCard(
          backgroundColor: customBgColor,
          child: const Text('Custom Background Color'),
        ),
      );
      
      // Find container and check if the background color is applied
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      
      // Check background color
      expect(decoration.color, equals(customBgColor));
    });
    
    testWidgets('applies custom padding', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);
      
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: const ContentCard(
          padding: customPadding,
          child: Text('Custom Padding'),
        ),
      );
      
      // Look for the ContentCard by the constructor arguments
      expect(find.byType(ContentCard), findsOneWidget);
      
      // Get the widget instance
      final contentCard = tester.widget<ContentCard>(find.byType(ContentCard));
      
      // Verify the padding value
      expect(contentCard.padding, equals(customPadding));
    });
    
    testWidgets('applies custom margin', (WidgetTester tester) async {
      const customMargin = EdgeInsets.all(24.0);
      
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: const ContentCard(
          margin: customMargin,
          child: Text('Custom Margin'),
        ),
      );
      
      // Find container and check if the margin is applied
      final container = tester.widget<Container>(find.byType(Container));
      
      // Check margin
      expect(container.margin, equals(customMargin));
    });
    
    testWidgets('renders with complex child content', (WidgetTester tester) async {
      await setupResponsiveTest(
        tester,
        deviceType: DeviceType.mobile,
        widget: const ContentCard(
          child: Column(
            children: [
              Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Description text goes here'),
              Icon(Icons.info),
            ],
          ),
        ),
      );
      
      // Verify all content is displayed
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description text goes here'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });
} 