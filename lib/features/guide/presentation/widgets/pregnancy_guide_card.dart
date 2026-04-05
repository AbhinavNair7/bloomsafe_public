import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';

/// A card that displays pregnancy-specific guidance
class PregnancyGuideCard extends StatelessWidget {

  /// Creates a pregnancy guide card
  const PregnancyGuideCard({super.key, required this.item});
  /// The pregnancy guide item to display
  final PregnancyGuideItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: spacingMedium),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trimester banner
          if (item.trimester != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: spacingMedium,
              ),
              color: _getColorForTrimester(item.trimester!),
              child: Text(
                '${item.trimester} Trimester',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                if (item.description != null) ...[
                  const SizedBox(height: spacingSmall),
                  Text(item.description!, style: const TextStyle(fontSize: 14)),
                ],

                const SizedBox(height: spacingMedium),

                // Key actions
                const Text(
                  'Key Actions:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                ...item.keyActions.map(_buildActionItem),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an action item with a bullet point
  Widget _buildActionItem(String action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(child: Text(action, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// Gets the color for a specific trimester
  Color _getColorForTrimester(String trimester) {
    switch (trimester.toLowerCase()) {
      case 'first':
        return primaryColor;
      case 'second':
        return primaryColor.withOpacity(0.8);
      case 'third':
        return primaryColor.withOpacity(0.6);
      default:
        return primaryColor;
    }
  }
}
