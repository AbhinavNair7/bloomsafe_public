import 'package:bloomsafe/features/guide/data/constants/guide_content.dart';
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';

/// Service class that provides access to guide content
class GuideService {
  /// Get all guide categories
  List<GuideCategory> getAllCategories() {
    return guideCategories;
  }

  /// Get a category by its title
  GuideCategory? getCategoryByTitle(String title) {
    try {
      return guideCategories.firstWhere(
        (category) => category.title.toLowerCase() == title.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all air quality zones
  List<AirQualityZone> getAirQualityZones() {
    return airQualityZones;
  }

  /// Get all action recommendations
  List<ActionRecommendation> getActionRecommendations() {
    return actionRecommendations;
  }

  /// Get all pregnancy guide items
  List<PregnancyGuideItem> getPregnancyGuideItems() {
    return pregnancyGuideItems;
  }

  /// Get all safety guide items
  List<SafetyGuideItem> getSafetyGuideItems() {
    return safetyGuideItems;
  }

  /// Search for guide items containing the query string in title or description
  List<GuideItem> searchGuideItems(String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    final results = <GuideItem>[];

    // Search through all categories
    for (final category in guideCategories) {
      for (final item in category.items) {
        final titleMatch = item.title.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch =
            item.description?.toLowerCase().contains(lowercaseQuery) ?? false;

        if (titleMatch || descriptionMatch) {
          results.add(item);
        }
      }
    }

    return results;
  }
}
