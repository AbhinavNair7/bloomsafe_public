/// Model class representing an educational article in the Learn feature
class LearningArticle {

  /// Creates a new learning article
  const LearningArticle({
    required this.title,
    required this.readTime,
    required this.keyTakeaways,
    required this.category,
    this.externalUrl,
    this.description,
  });

  /// Create a LearningArticle from a map structure
  factory LearningArticle.fromMap(Map<String, dynamic> map, String category) {
    return LearningArticle(
      title: map['title'] as String,
      readTime: map['readTime'] as int,
      keyTakeaways: List<String>.from(map['keyTakeaways'] as List),
      externalUrl: map['externalUrl'] as String?,
      description: map['description'] as String?,
      category: category,
    );
  }
  /// Article title
  final String title;

  /// Reading time in minutes
  final int readTime;

  /// List of key takeaway points
  final List<String> keyTakeaways;

  /// External URL for further reading
  final String? externalUrl;

  /// Article description or summary
  final String? description;

  /// Article category identifier
  final String category;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LearningArticle &&
        other.title == title &&
        other.category == category;
  }

  @override
  int get hashCode => title.hashCode ^ category.hashCode;
}
