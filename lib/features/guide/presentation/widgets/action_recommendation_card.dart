import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';

/// A card that displays action recommendations for air quality levels
class ActionRecommendationCard extends StatelessWidget {

  /// Creates a new ActionRecommendationCard widget
  const ActionRecommendationCard({super.key, required this.recommendation});
  /// The action recommendation to display
  final ActionRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: spacingMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              children: [
                Icon(recommendation.icon, color: primaryColor, size: 24),
                const SizedBox(width: spacingSmall),
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Outdoor recommendations
            _buildActionSection(
              title: 'Outdoors',
              content: recommendation.outdoorAction,
              iconData: Icons.park_outlined,
            ),

            const SizedBox(height: spacingMedium),

            // Indoor recommendations
            _buildActionSection(
              title: 'Indoors',
              content: recommendation.indoorAction,
              iconData: Icons.home_outlined,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a section for a specific action recommendation
  Widget _buildActionSection({
    required String title,
    required String content,
    required IconData iconData,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section icon
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(26), // 0.1 opacity
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: primaryColor, size: 16),
        ),
        const SizedBox(width: spacingSmall),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
