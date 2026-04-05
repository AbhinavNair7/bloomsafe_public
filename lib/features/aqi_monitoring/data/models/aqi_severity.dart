import 'package:flutter/material.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/constants/severity_zones.dart';
import 'package:bloomsafe/core/constants/colors.dart';

/// Enum representing different severity levels for air quality index (PM2.5)
enum AQISeverity {
  /// 0-50: Ideal air quality for conception and pregnancy
  nurturing,

  /// 51-100: Generally acceptable, but some sensitive individuals may need to take precautions
  mindful,

  /// 101-150: May cause issues for sensitive groups, including pregnant women
  cautious,

  /// 151-200: Health risks increase, outdoor activities should be limited
  shield,

  /// 201-300: Serious health concerns, avoid outdoor exposure when possible
  shelter,

  /// 301+: Hazardous conditions, stay indoors with air purification
  protection,
}

/// Extension to add helpful methods to the AQISeverity enum
extension AQISeverityExtension on AQISeverity {
  /// Get the severity level based on the AQI value
  static AQISeverity fromAQIValue(int value) {
    if (value <= severityZones['nurturing']!['maxValue']) {
      return AQISeverity.nurturing;
    } else if (value <= severityZones['mindful']!['maxValue']) {
      return AQISeverity.mindful;
    } else if (value <= severityZones['cautious']!['maxValue']) {
      return AQISeverity.cautious;
    } else if (value <= severityZones['shield']!['maxValue']) {
      return AQISeverity.shield;
    } else if (value <= severityZones['shelter']!['maxValue']) {
      return AQISeverity.shelter;
    } else {
      return AQISeverity.protection;
    }
  }

  /// Get the severity level based on the AQI double value
  static AQISeverity fromAQIDoubleValue(double value) {
    return fromAQIValue(value.round());
  }

  /// Get the name string for the severity level
  String get name {
    switch (this) {
      case AQISeverity.nurturing:
        return severityZones['nurturing']!['name'];
      case AQISeverity.mindful:
        return severityZones['mindful']!['name'];
      case AQISeverity.cautious:
        return severityZones['cautious']!['name'];
      case AQISeverity.shield:
        return severityZones['shield']!['name'];
      case AQISeverity.shelter:
        return severityZones['shelter']!['name'];
      case AQISeverity.protection:
        return severityZones['protection']!['name'];
    }
  }

  /// Get the color associated with this severity level
  Color get color {
    switch (this) {
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
