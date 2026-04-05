import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';
import 'package:bloomsafe/core/constants/strings.dart';

/// List of air quality zones with their descriptions and colors
const List<AirQualityZone> airQualityZones = [
  AirQualityZone(
    title: 'Nurturing',
    description: nurturingZoneHealthImpact,
    color: nurturingZoneColor,
    indexRange: '0-50',
  ),
  AirQualityZone(
    title: 'Mindful',
    description: mindfulZoneHealthImpact,
    color: mindfulZoneColor,
    indexRange: '51-100',
  ),
  AirQualityZone(
    title: 'Cautious',
    description: cautiousZoneHealthImpact,
    color: cautiousZoneColor,
    indexRange: '101-150',
  ),
  AirQualityZone(
    title: 'Shield',
    description: shieldZoneHealthImpact,
    color: shieldZoneColor,
    indexRange: '151-200',
  ),
  AirQualityZone(
    title: 'Shelter',
    description: shelterZoneHealthImpact,
    color: shelterZoneColor,
    indexRange: '201-300',
  ),
  AirQualityZone(
    title: 'Protection',
    description: protectionZoneHealthImpact,
    color: protectionZoneColor,
    indexRange: '301+',
  ),
];

/// List of action recommendations for different air quality levels
const List<ActionRecommendation> actionRecommendations = [
  ActionRecommendation(
    title: 'Nurturing (0-50)',
    outdoorAction: nurturingRec1,
    indoorAction: nurturingRec3,
    icon: Icons.park_outlined,
  ),
  ActionRecommendation(
    title: 'Mindful (51-100)',
    outdoorAction: mindfulRec1,
    indoorAction: mindfulRec3,
    icon: Icons.nature_people_outlined,
  ),
  ActionRecommendation(
    title: 'Cautious (101-150)',
    outdoorAction: cautiousRec1,
    indoorAction: cautiousRec2,
    icon: Icons.warning_amber_outlined,
  ),
  ActionRecommendation(
    title: 'Shield (151-200)',
    outdoorAction: shieldRec1,
    indoorAction: shieldRec2,
    icon: Icons.shield_outlined,
  ),
  ActionRecommendation(
    title: 'Shelter (201-300)',
    outdoorAction: shelterRec3,
    indoorAction: shelterRec2,
    icon: Icons.home_outlined,
  ),
  ActionRecommendation(
    title: 'Protection (301+)',
    outdoorAction: protectionRec1,
    indoorAction: protectionRec5,
    icon: Icons.health_and_safety_outlined,
  ),
];

/// Pregnancy-specific guide items
const List<PregnancyGuideItem> pregnancyGuideItems = [
  PregnancyGuideItem(
    title: 'First Trimester Considerations',
    description: 'The first trimester is a critical period for development.',
    trimester: 'First',
    keyActions: [
      'Avoid high pollution areas when possible',
      'Use air purifiers at home and work',
      'Track AQI daily during the embryo development stage',
      'Consult with healthcare provider about air quality concerns',
    ],
  ),
  PregnancyGuideItem(
    title: 'Second Trimester Safety',
    description: 'The second trimester has ongoing developmental sensitivity.',
    trimester: 'Second',
    keyActions: [
      'Maintain moderate activity levels on good air quality days',
      'Stay indoors during high pollution events',
      'Consider wearing N95 masks when AQI exceeds Shield level',
      'Keep indoor air quality optimal with air purifiers',
    ],
  ),
  PregnancyGuideItem(
    title: 'Third Trimester Vigilance',
    description:
        'The third trimester requires special attention to air quality.',
    trimester: 'Third',
    keyActions: [
      'Limit outdoor exercise during moderate or worse air quality days',
      'Plan indoor activities when pollution is high',
      'Prepare your hospital travel plan to avoid high pollution areas',
      'Ensure home has a clean air space with filtered air',
    ],
  ),
];

/// Safety guide items for general protection
const List<SafetyGuideItem> safetyGuideItems = [
  SafetyGuideItem(
    title: 'Creating a Clean Air Space',
    priority: 'High',
    keyPoints: [
      'Designate one room as your clean air space',
      'Use HEPA air purifiers sized appropriately for the room',
      'Seal windows and doors with weather stripping',
      'Change air filters regularly',
    ],
  ),
  SafetyGuideItem(
    title: 'Choosing Proper Masks',
    priority: 'Medium',
    keyPoints: [
      'N95 or KN95 masks provide the best protection against PM2.5',
      'Ensure proper fit with no gaps around edges',
      'Replace masks according to manufacturer recommendations',
      'Simple surgical or cloth masks offer minimal protection against PM2.5',
    ],
  ),
  SafetyGuideItem(
    title: 'Travel Considerations',
    priority: 'Medium',
    keyPoints: [
      'Check air quality forecasts before planning outdoor activities',
      'Keep car windows closed and use recirculated air in high pollution areas',
      'Consider air quality when choosing accommodation',
      'Pack portable air quality monitor for extended trips',
    ],
  ),
  SafetyGuideItem(
    title: 'Home Air Quality Improvements',
    priority: 'High',
    keyPoints: [
      'Install and maintain HVAC filters rated MERV 13 or higher',
      'Avoid activities that generate indoor pollution (smoking, burning candles)',
      'Control humidity to prevent mold growth',
      'Clean regularly to reduce dust and allergens',
    ],
  ),
];

/// All guide categories
final List<GuideCategory> guideCategories = [
  GuideCategory(
    title: 'Air Quality Zones',
    description:
        'Understanding different air quality levels and what they mean',
    items:
        airQualityZones
            .map(
              (zone) => AirQualityGuideItem(
                title: '${zone.title} (${zone.indexRange})',
                description: zone.description,
                aqiRange: zone.indexRange,
                outdoorRecommendations: _getOutdoorRecommendations(zone.title),
                indoorRecommendations: _getIndoorRecommendations(zone.title),
              ),
            )
            .toList(),
  ),
  GuideCategory(
    title: 'Recommended Actions',
    description: 'What to do at different air quality levels',
    items:
        actionRecommendations
            .map(
              (action) => AirQualityGuideItem(
                title: action.title,
                description:
                    'Recommendations for ${action.title} air quality levels',
                outdoorRecommendations: [action.outdoorAction],
                indoorRecommendations: [action.indoorAction],
              ),
            )
            .toList(),
  ),
  const GuideCategory(
    title: 'Pregnancy Considerations',
    description: 'Special guidance for expecting mothers',
    items: pregnancyGuideItems,
  ),
  const GuideCategory(
    title: 'Safety Guidelines',
    description: 'General protective measures against air pollution',
    items: safetyGuideItems,
  ),
];

/// Get outdoor recommendations based on zone title
List<String> _getOutdoorRecommendations(String zoneTitle) {
  switch (zoneTitle.toLowerCase()) {
    case 'nurturing':
      return [nurturingRec1, nurturingRec2, nurturingRec4];
    case 'mindful':
      return [mindfulRec1, mindfulRec2, mindfulRec4];
    case 'cautious':
      return [cautiousRec1, cautiousRec3, cautiousRec5];
    case 'shield':
      return [shieldRec1, shieldRec3, shieldRec4];
    case 'shelter':
      return [shelterRec1, shelterRec3, shelterRec4];
    case 'protection':
      return [protectionRec1, protectionRec2, protectionRec3];
    default:
      return [];
  }
}

/// Get indoor recommendations based on zone title
List<String> _getIndoorRecommendations(String zoneTitle) {
  switch (zoneTitle.toLowerCase()) {
    case 'nurturing':
      return [nurturingRec3];
    case 'mindful':
      return [mindfulRec3];
    case 'cautious':
      return [cautiousRec2, cautiousRec4];
    case 'shield':
      return [shieldRec2, shieldRec5];
    case 'shelter':
      return [shelterRec2, shelterRec5];
    case 'protection':
      return [protectionRec4, protectionRec5];
    default:
      return [];
  }
}
