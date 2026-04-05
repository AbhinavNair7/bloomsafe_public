import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/strings.dart';

// AQI PM2.5 Zone Definitions
const Map<String, Map<String, dynamic>> severityZones = {
  'nurturing': {
    'name': nurturingZoneName,
    'range': nurturingZoneRange,
    'color': nurturingZoneColor,
    'minValue': 0,
    'maxValue': 50,
    'healthImpact': nurturingZoneHealthImpact,
    'recommendations': [
      nurturingRec1,
      nurturingRec2,
      nurturingRec3,
      nurturingRec4,
    ],
  },
  'mindful': {
    'name': mindfulZoneName,
    'range': mindfulZoneRange,
    'color': mindfulZoneColor,
    'minValue': 51,
    'maxValue': 100,
    'healthImpact': mindfulZoneHealthImpact,
    'recommendations': [mindfulRec1, mindfulRec2, mindfulRec3, mindfulRec4],
  },
  'cautious': {
    'name': cautiousZoneName,
    'range': cautiousZoneRange,
    'color': cautiousZoneColor,
    'minValue': 101,
    'maxValue': 150,
    'healthImpact': cautiousZoneHealthImpact,
    'recommendations': [
      cautiousRec1,
      cautiousRec2,
      cautiousRec3,
      cautiousRec4,
      cautiousRec5,
    ],
  },
  'shield': {
    'name': shieldZoneName,
    'range': shieldZoneRange,
    'color': shieldZoneColor,
    'minValue': 151,
    'maxValue': 200,
    'healthImpact': shieldZoneHealthImpact,
    'recommendations': [
      shieldRec1,
      shieldRec2,
      shieldRec3,
      shieldRec4,
      shieldRec5,
    ],
  },
  'shelter': {
    'name': shelterZoneName,
    'range': shelterZoneRange,
    'color': shelterZoneColor,
    'minValue': 201,
    'maxValue': 300,
    'healthImpact': shelterZoneHealthImpact,
    'recommendations': [
      shelterRec1,
      shelterRec2,
      shelterRec3,
      shelterRec4,
      shelterRec5,
    ],
  },
  'protection': {
    'name': protectionZoneName,
    'range': protectionZoneRange,
    'color': protectionZoneColor,
    'minValue': 301,
    'maxValue': 500, // Assuming an upper limit
    'healthImpact': protectionZoneHealthImpact,
    'recommendations': [
      protectionRec1,
      protectionRec2,
      protectionRec3,
      protectionRec4,
      protectionRec5,
    ],
  },
};
