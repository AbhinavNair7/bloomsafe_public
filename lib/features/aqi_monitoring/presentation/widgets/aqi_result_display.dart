import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/ui_constants.dart';
import 'package:bloomsafe/core/presentation/widgets/disclaimer_widget.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_severity.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/widgets/severity_gauge.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/aqi_classifier.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';

// UI Constants for this widget
const double baseGaugeSize = 200.0;
const double baseBulletPointSize = 8.0;
const double baseIconSizeSmall = 18.0;
const String noAirQualityDataMessage = 'No air quality data available';
const String defaultLocationText = 'Your location';

/// A widget that displays AQI results including severity gauge and recommendations
class AQIResultDisplay extends StatelessWidget {

  /// Creates a new AQIResultDisplay widget
  const AQIResultDisplay({
    super.key,
    this.data,
    this.onCheckAnotherLocation,
    this.onShareResults,
  });
  /// The AQI data to display, if not provided it will be taken from the provider
  final AQIData? data;

  /// Whether to check another location when the button is pressed
  final VoidCallback? onCheckAnotherLocation;

  /// Whether to share results when the button is pressed
  final VoidCallback? onShareResults;

  @override
  Widget build(BuildContext context) {
    // Get AQI data from provider if not directly provided
    final aqi = data ?? Provider.of<AQIProvider>(context).data;

    // Return loading widget if no data available
    if (aqi == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get PM2.5 data
    final pm25Data = aqi.getPM25();
    if (pm25Data == null) {
      // Instead of showing a direct message, set the error in the provider
      // and let the AQIScreen handle it properly
      final provider = Provider.of<AQIProvider>(context, listen: false);
      provider.setError(apiConnectionErrorMessage);

      // Return an empty container since the provider update will trigger
      // a rebuild of the parent AQIScreen, which will show the error
      return Container();
    }

    // Get location information and format location with zipcode
    final location =
        aqi.reportingArea != null && aqi.stateCode != null
            ? '${aqi.reportingArea}, ${aqi.stateCode}'
            : defaultLocationText;
    final timestamp = aqi.observationDate;
    final formattedTime =
        '${timestamp.month}/${timestamp.day}/${timestamp.year}, ${timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.hour >= 12 ? 'PM' : 'AM'}';

    // Get severity for recommendations
    final severity = AQISeverityExtension.fromAQIDoubleValue(
      pm25Data.aqi.toDouble(),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location info - improved with icon
          Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.scaleHeight(context, spacingMedium),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: ResponsiveUtils.scaleWidth(context, 22),
                  color: Colors.green,
                ),
                SizedBox(width: ResponsiveUtils.scaleWidth(context, 8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        style: bodyStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.scaleText(
                            context,
                            bodyStyle.fontSize!,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Latest reading from: $formattedTime',
                        style: secondaryStyle.copyWith(
                          fontSize: ResponsiveUtils.scaleText(
                            context,
                            secondaryStyle.fontSize!,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Severity gauge
          const Align(
            alignment: Alignment.center,
            child: SeverityGauge(
              pm25Value: null, // Will be read from provider
              baseSize: baseGaugeSize,
            ),
          ),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingSmall)),

          // PM2.5 Specific Air Quality Index
          Align(
            alignment: Alignment.center,
            child: Text(
              pm25IndexTitle,
              style: secondaryStyle.copyWith(
                fontSize: ResponsiveUtils.scaleText(
                  context,
                  secondaryStyle.fontSize!,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

          // "You are in Zone" button - transparent background
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.scaleWidth(context, spacingLarge),
                vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.scaleWidth(context, 50),
                ),
                border: Border.all(
                  color: severity.color,
                  width: ResponsiveUtils.scaleWidth(context, 1.5),
                ),
              ),
              child: Text(
                '$youAreInZoneText ${severity.name}',
                style: bodyStyle.copyWith(
                  color: severity.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.scaleText(
                    context,
                    bodyStyle.fontSize!,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingSmall)),

          // Hourly update notice
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.scaleHeight(context, spacingSmall),
              horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
            ),
            child: Text(
              'Readings update hourly and show the previous hour\'s air quality.',
              style: secondaryStyle.copyWith(
                fontSize: ResponsiveUtils.scaleText(context, fontSizeSecondary - 1),
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(
            height: ResponsiveUtils.scaleHeight(context, spacingLarge * 1.5),
          ),

          // Combined info card with both health impact and recommendations
          _buildCombinedInfoCard(context, severity),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

          // Medical disclaimer
          const DisclaimerWidget(),

          SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  /// Builds a combined information card with health impact and recommendations
  Widget _buildCombinedInfoCard(BuildContext context, AQISeverity severity) {
    final recommendations = _getRecommendations(severity);
    final healthImpact = _getHealthImpact(severity);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.scaleWidth(context, 16),
        ),
        border: Border.all(
          color: severity.color,
          width: ResponsiveUtils.scaleWidth(context, 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity
            blurRadius: ResponsiveUtils.scaleWidth(context, 8),
            spreadRadius: 0,
            offset: Offset(0, ResponsiveUtils.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What this means section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
              vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What this means for your reproductive health:',
                  style: bodyStyle.copyWith(
                    color: severity.color,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.scaleText(
                      context,
                      bodyStyle.fontSize!,
                    ),
                  ),
                ),
                Container(
                  height: ResponsiveUtils.scaleHeight(context, 3),
                  width: ResponsiveUtils.scaleWidth(context, 60),
                  margin: EdgeInsets.only(
                    top: ResponsiveUtils.scaleHeight(context, spacingSmall),
                    bottom: ResponsiveUtils.scaleHeight(context, spacingMedium),
                  ),
                  decoration: BoxDecoration(
                    color: severity.color,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.scaleWidth(context, 1.5),
                    ),
                  ),
                ),
                Text(
                  healthImpact,
                  style: secondaryStyle.copyWith(
                    color: Colors.black87,
                    height: 1.4,
                    fontSize: ResponsiveUtils.scaleText(
                      context,
                      secondaryStyle.fontSize!,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider between sections
          Divider(
            height: 1,
            thickness: ResponsiveUtils.scaleHeight(context, 1),
            color: const Color(0xFFEEEEEE),
          ),

          // Recommendations section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.scaleWidth(context, spacingMedium),
              vertical: ResponsiveUtils.scaleHeight(context, spacingMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended actions:',
                  style: bodyStyle.copyWith(
                    color: severity.color,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.scaleText(
                      context,
                      bodyStyle.fontSize!,
                    ),
                  ),
                ),
                Container(
                  height: ResponsiveUtils.scaleHeight(context, 3),
                  width: ResponsiveUtils.scaleWidth(context, 60),
                  margin: EdgeInsets.only(
                    top: ResponsiveUtils.scaleHeight(context, spacingSmall),
                    bottom: ResponsiveUtils.scaleHeight(context, spacingMedium),
                  ),
                  decoration: BoxDecoration(
                    color: severity.color,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.scaleWidth(context, 1.5),
                    ),
                  ),
                ),
                ...recommendations.map(
                  (rec) => _buildBulletPoint(context, rec, severity.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single bullet point with text
  Widget _buildBulletPoint(BuildContext context, String text, Color color) {
    final bulletPointSize = ResponsiveUtils.scaleWidth(
      context,
      baseBulletPointSize,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.scaleHeight(context, spacingSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: bulletPointSize,
            height: bulletPointSize,
            margin: EdgeInsets.only(
              top: ResponsiveUtils.scaleHeight(context, 6),
              right: ResponsiveUtils.scaleWidth(context, 12),
            ),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: secondaryStyle.copyWith(
                color: Colors.black87,
                height: 1.4,
                fontSize: ResponsiveUtils.scaleText(
                  context,
                  secondaryStyle.fontSize!,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons section
  Widget _buildActionButtons(BuildContext context) {
    final iconSize = ResponsiveUtils.scaleWidth(context, baseIconSizeSmall);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Check another location button
        if (onCheckAnotherLocation != null)
          OutlinedButton.icon(
            onPressed: onCheckAnotherLocation,
            icon: Icon(Icons.arrow_back_ios, size: iconSize),
            label: Text(
              checkAnotherLocationButtonText,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaleText(context, 14),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: primaryColor,
                width: ResponsiveUtils.scaleWidth(context, 1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.scaleWidth(context, buttonBorderRadius),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.scaleHeight(context, paddingStandard),
              ),
            ),
          ),

        SizedBox(height: ResponsiveUtils.scaleHeight(context, spacingMedium)),

        // Share results button
        if (onShareResults != null)
          ElevatedButton.icon(
            onPressed: onShareResults,
            icon: Icon(Icons.share, size: iconSize),
            label: Text(
              shareResultsButtonText,
              style: TextStyle(
                fontSize: ResponsiveUtils.scaleText(context, 14),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.scaleWidth(context, buttonBorderRadius),
                ),
              ),
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.scaleHeight(context, paddingStandard),
              ),
            ),
          ),
      ],
    );
  }

  /// Gets health impact text based on severity level
  String _getHealthImpact(AQISeverity severity) {
    final recommendations = generateRecommendations(
      getAQIMidpointForSeverity(severity),
    );
    return recommendations['healthImpact'] as String? ??
        'No health impact information available.';
  }

  /// Gets recommendations based on severity level
  List<String> _getRecommendations(AQISeverity severity) {
    final recommendations = generateRecommendations(
      getAQIMidpointForSeverity(severity),
    );
    return List<String>.from(recommendations['recommendations'] ?? []);
  }

  /// Provides a representative AQI value for each severity level
  int getAQIMidpointForSeverity(AQISeverity severity) {
    switch (severity) {
      case AQISeverity.nurturing:
        return 25; // midpoint of 0-50
      case AQISeverity.mindful:
        return 75; // midpoint of 51-100
      case AQISeverity.cautious:
        return 125; // midpoint of 101-150
      case AQISeverity.shield:
        return 175; // midpoint of 151-200
      case AQISeverity.shelter:
        return 250; // midpoint of 201-300
      case AQISeverity.protection:
        return 350; // representative value > 300
    }
  }
}
