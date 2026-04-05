import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:bloomsafe/core/presentation/widgets/disclaimer_widget.dart';
import 'package:bloomsafe/features/guide/presentation/state/guide_provider.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// Guide Screen that provides reference information and resources
/// This screen supports Phase 5 (Reference Guidance) of the user journey
class GuideScreen extends StatelessWidget {
  /// Creates a GuideScreen
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get analytics service and log screen view
    final analytics = di.sl<AnalyticsServiceInterface>();
    analytics.logScreenView('guide_screen');

    // Get screen size for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: neutralLight,
      appBar: const BloomAppBar(),
      body: Consumer<GuideProvider>(
        builder: (context, guideProvider, _) {
          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? spacingSmall : spacingMedium,
              vertical: spacingMedium,
            ),
            children: [
              // Introduction section
              _buildIntroSection(context),
              const SizedBox(height: spacingMedium),

              // Air quality categories - use container with blue border
              Container(
                margin: const EdgeInsets.only(bottom: spacingLarge),
                decoration: BoxDecoration(
                  color: neutralWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: secondaryColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildGuideItem(
                      context,
                      title: 'Nurturing (0-50)',
                      description: nurturingZoneHealthImpact,
                      color: nurturingZoneColor,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    _buildGuideItem(
                      context,
                      title: 'Mindful (51-100)',
                      description: mindfulZoneHealthImpact,
                      color: mindfulZoneColor,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    _buildGuideItem(
                      context,
                      title: 'Cautious (101-150)',
                      description: cautiousZoneHealthImpact,
                      color: cautiousZoneColor,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    _buildGuideItem(
                      context,
                      title: 'Shield (151-200)',
                      description: shieldZoneHealthImpact,
                      color: shieldZoneColor,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    _buildGuideItem(
                      context,
                      title: 'Shelter (201-300)',
                      description: shelterZoneHealthImpact,
                      color: shelterZoneColor,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEEEEEE),
                    ),
                    _buildGuideItem(
                      context,
                      title: 'Protection (301+)',
                      description: protectionZoneHealthImpact,
                      color: protectionZoneColor,
                    ),
                  ],
                ),
              ),

              // Consolidated recommendations section
              _buildSectionHeader(context, title: 'Recommended Actions'),

              // Recommendation sections - one for each severity level
              _buildActionItem(
                context,
                severity: 'Nurturing (0-50)',
                recommendations: [
                  nurturingRec1,
                  nurturingRec2,
                  nurturingRec3,
                  nurturingRec4,
                ],
                icon: Icons.park_outlined,
                color: nurturingZoneColor,
              ),
              _buildActionItem(
                context,
                severity: 'Mindful (51-100)',
                recommendations: [
                  mindfulRec1,
                  mindfulRec2,
                  mindfulRec3,
                  mindfulRec4,
                ],
                icon: Icons.nature_people_outlined,
                color: mindfulZoneColor,
              ),
              _buildActionItem(
                context,
                severity: 'Cautious (101-150)',
                recommendations: [
                  cautiousRec1,
                  cautiousRec2,
                  cautiousRec3,
                  cautiousRec4,
                  cautiousRec5,
                ],
                icon: Icons.warning_amber_outlined,
                color: cautiousZoneColor,
              ),
              _buildActionItem(
                context,
                severity: 'Shield (151-200)',
                recommendations: [
                  shieldRec1,
                  shieldRec2,
                  shieldRec3,
                  shieldRec4,
                  shieldRec5,
                ],
                icon: Icons.shield_outlined,
                color: shieldZoneColor,
              ),
              _buildActionItem(
                context,
                severity: 'Shelter (201-300)',
                recommendations: [
                  shelterRec1,
                  shelterRec2,
                  shelterRec3,
                  shelterRec4,
                  shelterRec5,
                ],
                icon: Icons.home_outlined,
                color: shelterZoneColor,
              ),
              _buildActionItem(
                context,
                severity: 'Protection (301+)',
                recommendations: [
                  protectionRec1,
                  protectionRec2,
                  protectionRec3,
                  protectionRec4,
                  protectionRec5,
                ],
                icon: Icons.health_and_safety_outlined,
                color: protectionZoneColor,
              ),

              // Medical disclaimer
              const Padding(
                padding: EdgeInsets.only(bottom: spacingMedium),
                child: DisclaimerWidget(),
              ),

              // Bottom padding
              const SizedBox(height: spacingLarge),
            ],
          );
        },
      ),
    );
  }

  /// Builds the introduction section
  Widget _buildIntroSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(guideCategoriesTitle, style: headingStyle),
        const SizedBox(height: spacingSmall),
        const Text(guideIntroText, style: secondaryStyle),
        const SizedBox(height: spacingMedium),
        // Purple divider line
        Container(
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ],
    );
  }

  /// Builds a section header with the given title
  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: spacingSmall),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: fontSizeH2,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              height: lineHeightMultiplier,
            ),
          ),
        ),
        // Purple divider line
        Container(
          height: 3,
          width: 80,
          margin: const EdgeInsets.only(bottom: spacingMedium),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
      ],
    );
  }

  /// Builds a guide item for each air quality category
  Widget _buildGuideItem(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // No analytics tracking here to avoid recommendation_viewed events
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: spacingMedium,
          horizontal: spacingMedium,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: secondaryStyle.copyWith(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an action item card for each severity level
  Widget _buildActionItem(
    BuildContext context, {
    required String severity,
    required List<String> recommendations,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // No analytics tracking here to avoid recommendation_viewed events
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: spacingLarge),
        decoration: BoxDecoration(
          color: neutralWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: secondaryColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity header with solid background color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: spacingMedium,
                vertical: spacingMedium,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    severity,
                    style: bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Recommendations
            Padding(
              padding: const EdgeInsets.all(spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    recommendations
                        .map(
                          (recommendation) => _buildRecommendationBullet(
                            context,
                            content: recommendation,
                            color: color,
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a bullet point for a recommendation
  Widget _buildRecommendationBullet(
    BuildContext context, {
    required String content,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              content,
              style: secondaryStyle.copyWith(
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
