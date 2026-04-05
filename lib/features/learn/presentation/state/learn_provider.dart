import 'package:flutter/material.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/features/learn/data/models/learn_article.dart';
import 'package:bloomsafe/features/learn/data/services/learn_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Provider class that manages state for the learn feature
class LearnProvider with ChangeNotifier {

  /// Constructs a new learn provider
  LearnProvider({required LearnService learnService})
    : _learnService = learnService {
    // Initialize with all categories
    if (_learnService.getCategories().isNotEmpty) {
      _selectedCategory = _learnService.getCategories().first;
    }
    // Load articles initially
    loadArticles();
  }
  final LearnService _learnService;
  final AnalyticsServiceInterface _analytics =
      di.sl<AnalyticsServiceInterface>();

  /// Currently selected category
  String? _selectedCategory;

  /// Search query
  String _searchQuery = '';

  /// Last viewed article
  LearningArticle? _lastViewedArticle;

  /// Loading state flag
  bool _isLoading = false;

  /// Whether articles are currently loading
  bool get isLoading => _isLoading;

  /// Get available categories
  List<String> get categories => _learnService.getCategories();

  /// Get the currently selected category
  String? get selectedCategory => _selectedCategory;

  /// Get the current search query
  String get searchQuery => _searchQuery;

  /// Set the selected category
  set selectedCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  /// Set the search query
  set searchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Get the last viewed article
  LearningArticle? get lastViewedArticle => _lastViewedArticle;

  /// Set the last viewed article
  set lastViewedArticle(LearningArticle? article) {
    _lastViewedArticle = article;

    // Track article view in analytics
    if (article != null) {
      _analytics.logLearnArticleViewed(article.title, article.category);
    }

    notifyListeners();
  }

  /// Load articles from the learn service
  Future<void> loadArticles() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // No actual loading needed since articles are hardcoded,
    // but this method provides the structure for future API integration

    _isLoading = false;
    notifyListeners();

    return Future.value();
  }

  /// Get articles for the selected category
  List<LearningArticle> getArticles() {
    if (_searchQuery.isNotEmpty) {
      return _learnService.searchArticles(_searchQuery);
    }

    if (_selectedCategory != null) {
      return _learnService.getArticlesByCategory(_selectedCategory!);
    }

    return _learnService.getAllArticles();
  }

  /// Get articles by category directly without changing state
  List<LearningArticle> getArticlesByCategory(String category) {
    return _learnService.getArticlesByCategory(category);
  }

  /// Launches the URL for an article's external link
  Future<void> launchArticleUrl(String? url, String articleId) async {
    if (url == null || url.isEmpty) return;

    try {
      await _analytics.logLearnArticleViewed(articleId, 'external_link');
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      Logger.error('Error launching URL: $e');
    }
  }

  /// Share an article with external apps
  Future<void> shareArticle(
    BuildContext context,
    LearningArticle article,
  ) async {
    try {
      final box = context.findRenderObject() as RenderBox?;

      // Prepare share text with article title, description, and optional URL
      String shareText = '${article.title}\n\n';

      if (article.description != null && article.description!.isNotEmpty) {
        shareText += '${article.description}\n\n';
      }

      if (article.externalUrl != null && article.externalUrl!.isNotEmpty) {
        shareText += 'Learn more: ${article.externalUrl}\n\n';
      }

      shareText += 'Shared from BloomSafe';

      await Share.share(
        shareText,
        subject: article.title,
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );

      // Log analytics event
      await _analytics.logContentShared('learn_article', 'share_button');
    } catch (e) {
      Logger.error('Error sharing article: $e');
    }
  }
}
