import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/core/services/share_service.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/aqi_result_display.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';

/// The screen for displaying AQI results
class AQIScreen extends StatelessWidget {

  /// Creates a new AQIScreen widget
  const AQIScreen({super.key, this.onBack});
  /// Callback when back navigation is triggered
  final VoidCallback? onBack;

  /// The connectivity service
  static final ConnectivityService _connectivityService = ConnectivityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neutralLight,
      appBar: BloomAppBar(
        showBackButton: true,
        onBackPressed: onBack ?? () => Navigator.of(context).pop(),
      ),
      body: Consumer<AQIProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingView(context);
          } else if (provider.error != null) {
            return _buildErrorView(context, provider.error!);
          } else if (provider.data == null) {
            return _buildEmptyStateView(context);
          } else {
            return Padding(
              padding: EdgeInsets.all(
                ResponsiveUtils.scaleWidth(context, spacingMedium),
              ),
              child: AQIResultDisplay(
                data: provider.data,
                onCheckAnotherLocation:
                    onBack ?? () => Navigator.of(context).pop(),
                onShareResults: () => _shareResults(context),
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the loading view with animation
  Widget _buildLoadingView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primaryColor),
          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingLarge)),
          Text(
            loadingText,
            style: bodyStyle.copyWith(
              fontSize: ResponsiveUtils.scaleText(context, bodyStyle.fontSize!),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the error view with retry button
  Widget _buildErrorView(BuildContext context, String errorMessage) {
    final iconSize = ResponsiveUtils.scaleWidth(context, iconSizeLarge);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.scaleWidth(context, spacingLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: iconSize),
            SizedBox(
              height: ResponsiveUtils.scaleHeight(context, spacingMedium),
            ),
            Text(
              errorMessage,
              style: bodyStyle.copyWith(
                fontSize: ResponsiveUtils.scaleText(
                  context,
                  bodyStyle.fontSize!,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ResponsiveUtils.scaleHeight(context, spacingLarge),
            ),
            ElevatedButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.scaleWidth(context, buttonBorderRadius),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaleWidth(context, spacingLarge),
                  vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
                ),
              ),
              child: Text(
                tryAgainText,
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaleText(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the empty state view
  Widget _buildEmptyStateView(BuildContext context) {
    final iconSize = ResponsiveUtils.scaleWidth(context, iconSizeLarge);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.scaleWidth(context, spacingLarge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: secondaryColor, size: iconSize),
            SizedBox(
              height: ResponsiveUtils.scaleHeight(context, spacingMedium),
            ),
            Text(
              apiConnectionErrorMessage,
              style: bodyStyle.copyWith(
                fontSize: ResponsiveUtils.scaleText(
                  context,
                  bodyStyle.fontSize!,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: ResponsiveUtils.scaleHeight(context, spacingLarge),
            ),
            ElevatedButton(
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.scaleWidth(context, buttonBorderRadius),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.scaleWidth(context, spacingLarge),
                  vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
                ),
              ),
              child: Text(
                goBackText,
                style: TextStyle(
                  fontSize: ResponsiveUtils.scaleText(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles sharing results
  void _shareResults(BuildContext context) async {
    try {
      final provider = Provider.of<AQIProvider>(context, listen: false);

      // Check if we have data to share
      if (provider.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data available to share'),
            duration: snackBarDuration,
          ),
        );
        return;
      }

      // Use share service to share results
      await ShareService().shareAQIResults(provider.data!, context: context);
    } catch (e) {
      // If there's any error during sharing, show the appropriate error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(internetErrorDuringShareMessage),
          duration: snackBarDuration,
        ),
      );
    }
  }
}
