import 'package:flutter/material.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';
import 'package:bloomsafe/features/guide/data/services/guide_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Provider class for managing guide state
class GuideProvider with ChangeNotifier {

  /// Constructs a guide provider
  GuideProvider({required GuideService guideService})
    : _guideService = guideService {
    // Initialize with first category
    final categories = _guideService.getAllCategories();
    if (categories.isNotEmpty) {
      _selectedCategoryTitle = categories.first.title;
    }
  }
  final GuideService _guideService;
  final AnalyticsServiceInterface _analytics =
      di.sl<AnalyticsServiceInterface>();

  /// Currently selected category title
  String? _selectedCategoryTitle;

  /// Search query
  String _searchQuery = '';

  /// Whether to show search results
  bool _showSearchResults = false;

  /// Currently viewed guide item (used for analytics tracking only)
  GuideItem? _currentlyViewedItem;

  /// Get all available categories
  List<GuideCategory> get categories => _guideService.getAllCategories();

  /// Get the currently selected category title
  String? get selectedCategoryTitle => _selectedCategoryTitle;

  /// Get the currently selected category
  GuideCategory? get selectedCategory {
    if (_selectedCategoryTitle == null) return null;
    return _guideService.getCategoryByTitle(_selectedCategoryTitle!);
  }

  /// Get the current search query
  String get searchQuery => _searchQuery;

  /// Whether to show search results
  bool get showSearchResults => _showSearchResults;

  /// Set the selected category title
  set selectedCategoryTitle(String? title) {
    if (_selectedCategoryTitle != title) {
      _selectedCategoryTitle = title;
      notifyListeners();
    }
  }

  /// Update the search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _showSearchResults = query.isNotEmpty;
    notifyListeners();
  }

  /// Clear the search query
  void clearSearch() {
    _searchQuery = '';
    _showSearchResults = false;
    notifyListeners();
  }

  /// Track guide item being viewed
  void viewGuideItem(GuideItem item) {
    _currentlyViewedItem = item;

    // Track the view in analytics
    _analytics.logGuideContentViewed(item.title, item.title);

    notifyListeners();
  }

  /// Track recommendation viewed
  void viewRecommendation(String severityLevel, String recommendationType) {
    _analytics.logRecommendationViewed(severityLevel, recommendationType);
  }

  /// Get search results
  List<GuideItem> get searchResults {
    if (_searchQuery.isEmpty) return [];
    return _guideService.searchGuideItems(_searchQuery);
  }

  /// Get items for the selected category
  List<GuideItem> getItemsForSelectedCategory() {
    final category = selectedCategory;
    if (category == null) return [];
    return category.items;
  }

  /// Get air quality zones
  List<AirQualityZone> get airQualityZones =>
      _guideService.getAirQualityZones();

  /// Get action recommendations
  List<ActionRecommendation> get actionRecommendations =>
      _guideService.getActionRecommendations();

  /// Get pregnancy guide items
  List<PregnancyGuideItem> get pregnancyGuideItems =>
      _guideService.getPregnancyGuideItems();

  /// Get safety guide items
  List<SafetyGuideItem> get safetyGuideItems =>
      _guideService.getSafetyGuideItems();

  /// Share a guide item with external apps
  Future<void> shareGuideItem(BuildContext context, GuideItem item) async {
    try {
      final box = context.findRenderObject() as RenderBox?;

      // Prepare share text
      String shareText = '${item.title}\n\n';

      if (item.description != null && item.description!.isNotEmpty) {
        shareText += '${item.description}\n\n';
      }

      // Add type-specific content
      if (item is PregnancyGuideItem && item.keyActions.isNotEmpty) {
        shareText += 'Key Actions:\n';
        for (final action in item.keyActions) {
          shareText += '• $action\n';
        }
        shareText += '\n';
      } else if (item is AirQualityGuideItem) {
        if (item.outdoorRecommendations.isNotEmpty) {
          shareText += 'Outdoor Recommendations:\n';
          for (final rec in item.outdoorRecommendations) {
            shareText += '• $rec\n';
          }
          shareText += '\n';
        }

        if (item.indoorRecommendations.isNotEmpty) {
          shareText += 'Indoor Recommendations:\n';
          for (final rec in item.indoorRecommendations) {
            shareText += '• $rec\n';
          }
          shareText += '\n';
        }
      } else if (item is SafetyGuideItem && item.keyPoints.isNotEmpty) {
        shareText += 'Safety Points:\n';
        for (final point in item.keyPoints) {
          shareText += '• $point\n';
        }
        shareText += '\n';
      }

      shareText += 'Shared from BloomSafe - Air Quality Guide';

      await Share.share(
        shareText,
        subject: item.title,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );

      // Log analytics event
      await _analytics.logContentShared('guide_item', 'share_button');

      Logger.debug('Analytics - Logged content_shared event for guide item');
    } catch (e) {
      Logger.error('Error sharing guide item: $e');
    }
  }
}
