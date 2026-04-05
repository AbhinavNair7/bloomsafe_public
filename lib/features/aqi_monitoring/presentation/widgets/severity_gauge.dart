import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/constants/severity_zones.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_severity.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/core/utils/responsive_utils.dart';

/// A circular gauge widget that displays PM2.5 air quality levels with visual indicators
class SeverityGauge extends StatelessWidget {

  /// Creates a new SeverityGauge widget
  const SeverityGauge({
    super.key,
    this.pm25Value,
    this.baseSize = 200.0,
    this.baseLineWidth = 15.0,
    this.animate = true,
    this.maxSize = 280.0,
  });
  /// The PM2.5 value to display
  final double? pm25Value;

  /// The size of the circular gauge
  final double baseSize;

  /// The width of the circular progress indicator line
  final double baseLineWidth;

  /// Whether to animate the gauge when first displayed
  final bool animate;

  /// Maximum size the gauge should reach (prevents too large sizes on tablets)
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    // Apply responsive scaling with maximum size cap
    final double rawSize = ResponsiveUtils.scaleWidth(context, baseSize);
    final double size = rawSize > maxSize ? maxSize : rawSize;

    // Scale line width proportionally if size is capped
    final double lineWidthScaleFactor = size / rawSize;
    final double lineWidth =
        ResponsiveUtils.scaleWidth(context, baseLineWidth) *
        lineWidthScaleFactor;

    // Watch AQI provider for changes if pm25Value is not directly provided
    final provider =
        pm25Value == null ? Provider.of<AQIProvider>(context) : null;

    // Get PM2.5 value from provider if not directly provided
    final double actualPm25Value = _getAqiValue(context, provider);

    // Get the severity level based on the PM2.5 value
    final severity = AQISeverityExtension.fromAQIDoubleValue(actualPm25Value);

    // Get the color for the severity level
    final Color gaugeColor = _getSeverityColor(severity);

    // Calculate position of indicator on scale (0 to 1)
    final double indicatorPosition = _calculateIndicatorPosition(
      actualPm25Value,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular gauge
        CircularPercentIndicator(
          radius: size / 2,
          lineWidth: lineWidth,
          percent: 1.0, // Always show full circle with varying colors
          center: Text(
            actualPm25Value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: ResponsiveUtils.scaleText(context, size / 4.5),
              fontWeight: FontWeight.bold,
              color: gaugeColor,
            ),
          ),
          progressColor: gaugeColor,
          backgroundColor: Colors.grey[200]!,
          animation: animate,
          animationDuration: 1000,
          circularStrokeCap: CircularStrokeCap.round,
        ),

        SizedBox(height: ResponsiveUtils.scaleHeight(context, 30)),

        // Horizontal color scale with markings
        Column(
          children: [
            // Scale with current indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient scale
                SizedBox(
                  width: size,
                  height: lineWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          nurturingZoneColor,
                          mindfulZoneColor,
                          cautiousZoneColor,
                          shieldZoneColor,
                          shelterZoneColor,
                          protectionZoneColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(lineWidth / 2),
                    ),
                  ),
                ),

                // Current level indicator
                Positioned(
                  left:
                      size * indicatorPosition.clamp(0.0, 1.0) -
                      ResponsiveUtils.scaleWidth(context, 4) *
                          lineWidthScaleFactor,
                  top:
                      -ResponsiveUtils.scaleHeight(context, 4) *
                      lineWidthScaleFactor,
                  child: Container(
                    width:
                        ResponsiveUtils.scaleWidth(context, 8) *
                        lineWidthScaleFactor,
                    height:
                        lineWidth +
                        (ResponsiveUtils.scaleHeight(context, 8) *
                            lineWidthScaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: gaugeColor,
                        width:
                            ResponsiveUtils.scaleWidth(context, 2) *
                            lineWidthScaleFactor,
                      ),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.scaleWidth(context, 4) *
                            lineWidthScaleFactor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Scale markings
            Padding(
              padding: EdgeInsets.only(
                top:
                    ResponsiveUtils.scaleHeight(context, 4) *
                    lineWidthScaleFactor,
              ),
              child: SizedBox(
                width: size,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScaleMarking(context, '0', size),
                    _buildScaleMarking(context, '50', size),
                    _buildScaleMarking(context, '100', size),
                    _buildScaleMarking(context, '150', size),
                    _buildScaleMarking(context, '200', size),
                    _buildScaleMarking(context, '300+', size),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Get the AQI value from provider or direct input
  double _getAqiValue(BuildContext context, AQIProvider? watchedProvider) {
    // Use directly provided value if available
    if (pm25Value != null) {
      return pm25Value!;
    }

    // Use watched provider if available (passed from build method)
    final provider =
        watchedProvider ?? Provider.of<AQIProvider>(context, listen: false);
    final data = provider.data;

    if (data != null) {
      final pm25 = data.getPM25();
      if (pm25 != null) {
        return pm25.aqi.toDouble();
      }
    }

    // Return default if no data available
    return 0.0;
  }

  /// Builds a scale marking text
  Widget _buildScaleMarking(BuildContext context, String text, double size) {
    return Text(
      text,
      style: TextStyle(
        fontSize: ResponsiveUtils.scaleText(context, size / 20),
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Calculate the position of the indicator on the scale (0-1)
  double _calculateIndicatorPosition(double value) {
    // Use constants from severity_zones
    final nurturingMax =
        (severityZones['nurturing']!['maxValue'] as int).toDouble();
    final mindfulMax =
        (severityZones['mindful']!['maxValue'] as int).toDouble();
    final cautiousMax =
        (severityZones['cautious']!['maxValue'] as int).toDouble();
    final shieldMax = (severityZones['shield']!['maxValue'] as int).toDouble();
    final shelterMax =
        (severityZones['shelter']!['maxValue'] as int).toDouble();

    if (value <= nurturingMax) {
      return value / nurturingMax * 0.2; // 0-20% of scale
    } else if (value <= mindfulMax) {
      return 0.2 +
          (value - nurturingMax) /
              (mindfulMax - nurturingMax) *
              0.2; // 20-40% of scale
    } else if (value <= cautiousMax) {
      return 0.4 +
          (value - mindfulMax) /
              (cautiousMax - mindfulMax) *
              0.2; // 40-60% of scale
    } else if (value <= shieldMax) {
      return 0.6 +
          (value - cautiousMax) /
              (shieldMax - cautiousMax) *
              0.2; // 60-80% of scale
    } else if (value <= shelterMax) {
      return 0.8 +
          (value - shieldMax) /
              (shelterMax - shieldMax) *
              0.2; // 80-100% of scale
    } else {
      return 1.0; // Max value
    }
  }

  /// Get the color associated with a severity level
  Color _getSeverityColor(AQISeverity severity) {
    switch (severity) {
      case AQISeverity.nurturing:
        return nurturingZoneColor;
      case AQISeverity.mindful:
        return mindfulZoneColor;
      case AQISeverity.cautious:
        return cautiousZoneColor;
      case AQISeverity.shield:
        return shieldZoneColor;
      case AQISeverity.shelter:
        return shelterZoneColor;
      case AQISeverity.protection:
        return protectionZoneColor;
    }
  }
}
