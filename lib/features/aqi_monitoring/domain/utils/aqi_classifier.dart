import 'package:bloomsafe/features/aqi_monitoring/data/constants/severity_zones.dart';

/// Utility library for classifying AQI values and generating recommendations
/// based on pregnancy-specific severity zones.

/// Classifies an AQI value according to defined severity zones
///
/// Parameters:
/// - [aqiValue]: The AQI value to classify
///
/// Returns:
/// - A string key of the severity zone: 'nurturing', 'mindful', 'cautious',
///   'shield', 'shelter', or 'protection'
String classifyAQISeverity(int aqiValue) {
  // Handle negative values by treating them as zero
  final value = aqiValue < 0 ? 0 : aqiValue;

  if (value <= 50) return 'nurturing';
  if (value <= 100) return 'mindful';
  if (value <= 150) return 'cautious';
  if (value <= 200) return 'shield';
  if (value <= 300) return 'shelter';
  return 'protection';
}

/// Generates recommendations based on AQI severity
///
/// For each severity level, this provides:
/// - The name of the zone ("Nurturing", "Mindful", etc.)
/// - Health impact information specific to reproductive health
/// - A list of recommended actions tailored for pregnant women or those trying to conceive
///
/// Parameters:
/// - [aqiValue]: The AQI value to generate recommendations for
///
/// Returns:
/// - A map containing 'zoneName', 'healthImpact', and 'recommendations' (List<String>)
Map<String, dynamic> generateRecommendations(int aqiValue) {
  final zone = classifyAQISeverity(aqiValue);
  final zoneData = severityZones[zone]!;

  return {
    'zoneName': zoneData['name'],
    'healthImpact': zoneData['healthImpact'],
    'recommendations': zoneData['recommendations'],
  };
}

/// Maps an AQI value to the EPA category name
///
/// Parameters:
/// - [aqiValue]: The AQI value to map
///
/// Returns:
/// - The EPA category name as a string: 'Good', 'Moderate', etc.
String getAQICategory(int aqiValue) {
  // Handle negative values by treating them as zero
  final value = aqiValue < 0 ? 0 : aqiValue;

  if (value <= 50) return 'Good';
  if (value <= 100) return 'Moderate';
  if (value <= 150) return 'Unhealthy for Sensitive Groups';
  if (value <= 200) return 'Unhealthy';
  if (value <= 300) return 'Very Unhealthy';
  return 'Hazardous';
}

/// Returns the hex color code associated with the AQI category
///
/// Parameters:
/// - [aqiValue]: The AQI value to get the color for
///
/// Returns:
/// - A hex color code string (e.g., '#4CAF50')
String getAQIColor(int aqiValue) {
  final zone = classifyAQISeverity(aqiValue);
  if (zone == 'nurturing') return '#4CAF50'; // Green
  if (zone == 'mindful') return '#FFC107'; // Yellow
  if (zone == 'cautious') return '#FF9800'; // Orange
  if (zone == 'shield') return '#E53935'; // Red
  if (zone == 'shelter') return '#9C27B0'; // Purple
  return '#673AB7'; // Dark Purple (protection)
}
