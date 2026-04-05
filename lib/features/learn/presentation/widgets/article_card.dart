import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/features/learn/data/models/learn_article.dart';
import 'package:bloomsafe/features/learn/presentation/state/learn_provider.dart';

/// A card widget that displays an article with a share button and read more option
class ArticleCard extends StatelessWidget {

  /// Creates a new ArticleCard widget
  const ArticleCard({super.key, required this.article});
  /// The article to display
  final LearningArticle article;

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          article.title,
          style: const TextStyle(
            fontSize: fontSizeH3,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: spacingMedium),

        // Read time and share button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Read time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${article.readTime} min read',
                  style: secondaryStyle.copyWith(color: Colors.grey),
                ),
              ],
            ),
            _buildShareButton(context),
          ],
        ),

        const SizedBox(height: spacingMedium),

        // Key takeaways
        Text(
          'Key Takeaways:',
          style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: spacingSmall),

        // Bullet points
        ...article.keyTakeaways.map(
          (point) => _buildTakeawayPoint(point, isSmallScreen),
        ),

        if (article.externalUrl != null) ...[
          const SizedBox(height: spacingMedium),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                final learnProvider = Provider.of<LearnProvider>(
                  context,
                  listen: false,
                );
                learnProvider.launchArticleUrl(
                  article.externalUrl,
                  article.title,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read Full Article',
                      style: secondaryStyle.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14, color: primaryColor),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Add divider after each article except the last one
        const SizedBox(height: spacingMedium),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: spacingMedium),
      ],
    );
  }

  /// Builds a bullet point for key takeaways
  Widget _buildTakeawayPoint(String point, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(153),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              point,
              style: secondaryStyle.copyWith(
                color: Colors.black87,
                height: 1.4,
                fontSize:
                    isSmallScreen ? fontSizeSecondary - 1 : fontSizeSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the share button
  Widget _buildShareButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final learnProvider = Provider.of<LearnProvider>(
                context,
                listen: false,
              );
              learnProvider.shareArticle(context, article);
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.share, size: 16, color: primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}
