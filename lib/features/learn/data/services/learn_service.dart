import 'package:bloomsafe/features/learn/data/constants/learn_content.dart';
import 'package:bloomsafe/features/learn/data/models/learn_article.dart';

/// Service class that provides access to learning content
class LearnService {
  /// Get all article categories
  List<String> getCategories() {
    return articleCategories;
  }

  /// Get all articles for a specific category
  List<LearningArticle> getArticlesByCategory(String category) {
    // Get the category key from the category name (e.g. 'Air Quality Basics' -> 'airQualityBasics')
    final categoryKey = _getCategoryKey(category);

    // Get the articles for the category
    final categoryArticles = learningArticles[categoryKey] ?? [];

    // Convert to LearningArticle models
    return categoryArticles
        .map((article) => LearningArticle.fromMap(article, category))
        .toList();
  }

  /// Get all articles across all categories
  List<LearningArticle> getAllArticles() {
    final allArticles = <LearningArticle>[];

    learningArticles.forEach((categoryKey, articles) {
      // Find the category name from the key
      final categoryName = articleCategories.firstWhere(
        (name) => _getCategoryKey(name) == categoryKey,
        orElse: () => categoryKey,
      );

      // Add all articles from this category
      allArticles.addAll(
        articles.map(
          (article) => LearningArticle.fromMap(article, categoryName),
        ),
      );
    });

    return allArticles;
  }

  /// Search for articles containing the query string in title or description
  List<LearningArticle> searchArticles(String query) {
    if (query.isEmpty) {
      return getAllArticles();
    }

    final lowercaseQuery = query.toLowerCase();
    final allArticles = getAllArticles();

    return allArticles.where((article) {
      final titleMatch = article.title.toLowerCase().contains(lowercaseQuery);
      final descriptionMatch =
          article.description?.toLowerCase().contains(lowercaseQuery) ?? false;

      return titleMatch || descriptionMatch;
    }).toList();
  }

  /// Convert a category name to its corresponding key in the data
  String _getCategoryKey(String categoryName) {
    // Simple conversion: "PM2.5 & Fertility" -> "airQualityBasics"
    if (categoryName == 'PM2.5 & Fertility') {
      return 'airQualityBasics';
    } else if (categoryName == 'Air Quality & Pregnancy') {
      return 'fertilityImpact';
    } else if (categoryName == 'Protecting Your Reproductive Health') {
      return 'pregnancyConsiderations';
    }

    // Fallback to lower case with no spaces
    return categoryName.toLowerCase().replaceAll(' ', '');
  }
}
