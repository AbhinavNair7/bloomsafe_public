import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/zipcode_input_form.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'zipcode_input_form_test.mocks.dart';

// Run this command to regenerate the mock:
// flutter pub run build_runner build --delete-conflicting-outputs

@GenerateMocks([AQIProvider, ConnectivityService])
void main() {
  group('ZipcodeInputForm Widget Tests', () {
    late MockAQIProvider mockProvider;
    late MockConnectivityService mockConnectivityService;

    setUp(() {
      mockProvider = MockAQIProvider();
      mockConnectivityService = MockConnectivityService();
      
      // Set up default mocked behaviors
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockConnectivityService.hasInternetConnectionWithTimeout())
          .thenAnswer((_) async => true);
      
      // Create a stub to replace the ConnectivityService in the widget
      // This is done with a patch in the testWidgets function
    });

    // Helper function to build the widget for testing
    Widget buildTestWidget({
      Function(String)? onSubmitted,
      bool provideConnectivityService = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AQIProvider>.value(
            value: mockProvider,
            child: provideConnectivityService
                ? _ConnectivityServicePatch(
                    service: mockConnectivityService,
                    child: ZipcodeInputForm(
                      onSubmitted: onSubmitted,
                    ),
                  )
                : ZipcodeInputForm(
                    onSubmitted: onSubmitted,
                  ),
          ),
        ),
      );
    }

    testWidgets('renders correctly', (WidgetTester tester) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      // Force a frame to ensure the screen dimensions are applied
      await tester.pumpWidget(Container());
      
      await tester.pumpWidget(buildTestWidget());

      // Verify the input field and button exist
      expect(find.text(zipCodeInputLabel), findsOneWidget);
      expect(find.text(checkAirQualityButtonText), findsOneWidget);

      // Ensure initial state has no errors displayed
      expect(find.text(emptyZipCodeError), findsNothing);
      expect(find.text(invalidZipCodeLengthError), findsNothing);
      expect(find.text(nonNumericZipCodeError), findsNothing);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('accepts valid zipcode input', (WidgetTester tester) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      bool callbackCalled = false;
      String? submittedZipcode;

      await tester.pumpWidget(buildTestWidget(
        onSubmitted: (zipcode) {
          callbackCalled = true;
          submittedZipcode = zipcode;
        },
      ),);

      // Enter a valid zipcode
      await tester.enterText(find.byType(TextFormField), '90210');

      // Tap the submit button
      await tester.tap(find.text(checkAirQualityButtonText));
      await tester.pump();

      // Verify callback was called with correct zipcode
      expect(callbackCalled, true);
      expect(submittedZipcode, '90210');

      // Ensure no errors are displayed
      expect(find.text(emptyZipCodeError), findsNothing);
      expect(find.text(invalidZipCodeLengthError), findsNothing);
      expect(find.text(nonNumericZipCodeError), findsNothing);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('shows error for empty zipcode on submit', (
      WidgetTester tester,
    ) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      await tester.pumpWidget(buildTestWidget());

      // Tap the submit button without entering any text
      await tester.tap(find.text(checkAirQualityButtonText));
      await tester.pump();

      // Verify error message is displayed
      expect(find.text(emptyZipCodeError), findsOneWidget);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('shows error for invalid zipcode length', (
      WidgetTester tester,
    ) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      await tester.pumpWidget(buildTestWidget());

      // Enter an invalid zipcode (too short)
      await tester.enterText(find.byType(TextFormField), '123');

      // Tap the submit button
      await tester.tap(find.text(checkAirQualityButtonText));
      await tester.pump();

      // Verify error message about length is displayed
      expect(find.text(invalidZipCodeLengthError), findsOneWidget);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('shows error for non-numeric zipcode', (
      WidgetTester tester,
    ) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      await tester.pumpWidget(buildTestWidget());

      // Try to enter non-numeric characters (this should be filtered out by the formatter)
      await tester.enterText(find.byType(TextFormField), 'ABC12');

      // Check that the text field has filtered out non-numeric characters
      expect(
        find.byWidgetPredicate(
          (widget) => widget is EditableText && widget.controller.text == '12',
        ),
        findsOneWidget,
      );
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('prevents submission during loading state', (
      WidgetTester tester,
    ) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      // Mock loading state
      when(mockProvider.isLoading).thenReturn(true);

      bool callbackCalled = false;

      await tester.pumpWidget(buildTestWidget(
        onSubmitted: (_) {
          callbackCalled = true;
        },
      ),);

      // Enter a valid zipcode
      await tester.enterText(find.byType(TextFormField), '90210');

      // Tap the submit button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verify callback was not called
      expect(callbackCalled, false);

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('uses provider to fetch data when no callback provided', (
      WidgetTester tester,
    ) async {
      // Set a fixed screen size for predictable responsive behavior
      tester.binding.window.physicalSizeTestValue = const Size(390, 844) * 3;
      tester.binding.window.devicePixelRatioTestValue = 3.0;
      
      when(mockProvider.fetchData(any)).thenAnswer((_) => Future.value());

      await tester.pumpWidget(buildTestWidget());

      // Enter a valid zipcode
      await tester.enterText(find.byType(TextFormField), '90210');

      // Tap the submit button
      await tester.tap(find.text(checkAirQualityButtonText));
      await tester.pump();

      // Verify provider's fetchData was called with correct zipcode
      verify(mockProvider.fetchData('90210')).called(1);
      
      // Reset the window state
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  });
}

/// Widget that injects a mock ConnectivityService into the widget tree
class _ConnectivityServicePatch extends InheritedWidget {

  const _ConnectivityServicePatch({
    required this.service,
    required super.child,
  });
  final MockConnectivityService service;

  static MockConnectivityService of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_ConnectivityServicePatch>();
    return result!.service;
  }

  @override
  bool updateShouldNotify(_ConnectivityServicePatch oldWidget) {
    return service != oldWidget.service;
  }
}
