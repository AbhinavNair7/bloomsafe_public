import 'package:flutter/material.dart';

/// Represents a guide category with its associated items
class GuideCategory {

  /// Creates a guide category
  const GuideCategory({
    required this.title,
    this.description,
    required this.items,
  });
  /// The title of the category
  final String title;

  /// The description of the category, if any
  final String? description;

  /// The items in this category
  final List<GuideItem> items;
}

/// Represents a quality zone with its color and description
class AirQualityZone {

  /// Creates an air quality zone
  const AirQualityZone({
    required this.title,
    required this.description,
    required this.color,
    required this.indexRange,
  });
  /// The title of the zone
  final String title;

  /// A brief description of what this zone means
  final String description;

  /// The color associated with this zone
  final Color color;

  /// The index range for this zone (e.g., "0-50")
  final String indexRange;
}

/// Represents an action recommendation for a specific air quality range
class ActionRecommendation {

  /// Creates an action recommendation
  const ActionRecommendation({
    required this.title,
    required this.outdoorAction,
    required this.indoorAction,
    required this.icon,
  });
  /// The title or severity level of this recommendation
  final String title;

  /// The recommended action for outdoors
  final String outdoorAction;

  /// The recommended action for indoors
  final String indoorAction;

  /// The icon to display with this recommendation
  final IconData icon;
}

/// Base class for all guide items
abstract class GuideItem {

  /// Creates a guide item
  const GuideItem({
    required this.title,
    this.description,
    this.tags = const [],
  });
  /// Title of the guide item
  final String title;

  /// Optional description
  final String? description;

  /// Tags for categorization
  final List<String> tags;
}

/// A guide item for pregnancy-specific information
class PregnancyGuideItem extends GuideItem {

  /// Creates a pregnancy guide item
  const PregnancyGuideItem({
    required super.title,
    super.description,
    super.tags,
    this.trimester,
    this.keyActions = const [],
  });

  /// Creates a guide item from JSON
  factory PregnancyGuideItem.fromJson(Map<String, dynamic> json) {
    return PregnancyGuideItem(
      title: json['title'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      trimester: json['trimester'],
      keyActions: List<String>.from(json['keyActions'] ?? []),
    );
  }
  /// The trimester this guide is most relevant for
  final String? trimester;

  /// List of key actions to take based on this guidance
  final List<String> keyActions;

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'trimester': trimester,
      'keyActions': keyActions,
    };
  }
}

/// A guide item for general air quality information
class AirQualityGuideItem extends GuideItem {

  /// Creates an air quality guide item
  const AirQualityGuideItem({
    required super.title,
    super.description,
    super.tags,
    this.aqiRange,
    this.outdoorRecommendations = const [],
    this.indoorRecommendations = const [],
  });

  /// Creates a guide item from JSON
  factory AirQualityGuideItem.fromJson(Map<String, dynamic> json) {
    return AirQualityGuideItem(
      title: json['title'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      aqiRange: json['aqiRange'],
      outdoorRecommendations: List<String>.from(
        json['outdoorRecommendations'] ?? [],
      ),
      indoorRecommendations: List<String>.from(
        json['indoorRecommendations'] ?? [],
      ),
    );
  }
  /// The air quality index range this guide applies to
  final String? aqiRange;

  /// Outdoor recommendations
  final List<String> outdoorRecommendations;

  /// Indoor recommendations
  final List<String> indoorRecommendations;

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'aqiRange': aqiRange,
      'outdoorRecommendations': outdoorRecommendations,
      'indoorRecommendations': indoorRecommendations,
    };
  }
}

/// Guide item for general safety information
class SafetyGuideItem extends GuideItem {

  /// Creates a safety guide item
  const SafetyGuideItem({
    required super.title,
    super.description,
    this.priority,
    required this.keyPoints,
  });
  /// Priority level for this safety item (high, medium, low)
  final String? priority;

  /// Key points about this safety item
  final List<String> keyPoints;
}
