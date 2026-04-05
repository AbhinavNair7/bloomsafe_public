import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';
import 'package:bloomsafe/core/presentation/widgets/content_card.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/zipcode_input_form.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/aqi_screen.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// The home page for the Track tab
class TrackHomePage extends StatelessWidget {

  /// Creates a new TrackHomePage widget
  const TrackHomePage({
    super.key,
    required this.setAQIResultScreen,
    required this.clearAQIResultScreen,
  });
  /// Function to set the AQI results screen
  final Function(Widget) setAQIResultScreen;

  /// Function to clear the AQI results screen
  final Function() clearAQIResultScreen;

  @override
  Widget build(BuildContext context) {
    // Get analytics service for screen tracking
    final analytics = di.sl<AnalyticsServiceInterface>();

    // Log screen view
    analytics.logScreenView('track_home_page');

    // Get responsive values and screen dimensions
    final double bottomPadding = ResponsiveUtils.scaleHeight(
      context,
      spacingLarge,
    );
    final double screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      // Dismiss keyboard when tapping outside input field
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: neutralLight,
        appBar: const BloomAppBar(transparentMode: true),
        // Prevent screen push-up by setting resizeToAvoidBottomInset to false
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        spacingLarge,
                        spacingLarge,
                        spacingLarge,
                        bottomPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top section with logo and app info - can be pushed off screen by keyboard
                          _buildTopSection(context),

                          // Middle section with zipcode input form - should always be visible
                          Padding(
                            padding: EdgeInsets.only(
                              top: ResponsiveUtils.scaleHeight(
                                context,
                                spacingLarge,
                              ),
                              bottom: ResponsiveUtils.scaleHeight(
                                context,
                                spacingLarge,
                              ),
                            ),
                            child: _buildMiddleSection(context),
                          ),

                          // Bottom section with educational tip - can be pushed off screen by keyboard
                          _buildEducationalTip(context),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the top section with logo and app info
  Widget _buildTopSection(BuildContext context) {
    return Column(
      children: [
        // App logo
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: Image.asset(
            'assets/images/bloomsafe_logo.png',
            width: logoSize,
            height: logoSize,
          ),
        ),

        SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingLarge)),

        // App title
        const Text(appTitle, style: headingStyle, textAlign: TextAlign.center),

        SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

        // App tagline
        const Text(
          appTagline,
          style: subheadingStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the middle section with zipcode input form
  Widget _buildMiddleSection(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.scaleWidth(context, maxFormWidth),
      ),
      child: ZipcodeInputForm(
        onSubmitted: (zipcode) => _showAQIResults(context, zipcode),
      ),
    );
  }

  /// Builds the educational tip widget
  Widget _buildEducationalTip(BuildContext context) {
    return ContentCard(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: accentColor,
            size: ResponsiveUtils.scaleWidth(context, iconSizeMedium),
          ),
          SizedBox(width: ResponsiveUtils.scaleWidth(context, spacingMedium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  educationalTipPrefix,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: ResponsiveUtils.scaleText(context, 14),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.scaleHeight(context, spacingSmall),
                ),
                Text(
                  educationalTipText,
                  style: secondaryStyle.copyWith(
                    fontSize: ResponsiveUtils.scaleText(
                      context,
                      secondaryStyle.fontSize!,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show AQI results while keeping the bottom navigation bar
  void _showAQIResults(BuildContext context, String zipcode) async {
    final provider = Provider.of<AQIProvider>(context, listen: false);

    // Clear previous errors before fetching new data
    provider.clearData();

    // Fetch data
    await provider.fetchData(zipcode);

    // Check if we have data and no errors
    if (provider.data != null && provider.error == null && context.mounted) {
      // Create an AQI results overlay with a back button that clears it
      final aqiResultsScreen = _buildAQIResultsOverlay(context);

      // Set the AQI results screen in the parent widget
      setAQIResultScreen(aqiResultsScreen);
    }
    // No need to do anything for errors - they will be displayed by the ZipcodeInputForm
    // which listens to the provider's error state
  }

  /// Build an AQI results overlay with back button navigation
  Widget _buildAQIResultsOverlay(BuildContext context) {
    // Create an AQI screen with the onBack callback to clear the screen
    return AQIScreen(
      key: const ValueKey('aqi_results_screen'),
      onBack: clearAQIResultScreen,
    );
  }
}
