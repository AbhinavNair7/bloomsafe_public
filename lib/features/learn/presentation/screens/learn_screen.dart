import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/core/constants/typography.dart';
import 'package:bloomsafe/core/presentation/widgets/bloom_app_bar.dart';
import 'package:bloomsafe/core/presentation/widgets/disclaimer_widget.dart';
import 'package:bloomsafe/features/learn/presentation/state/learn_provider.dart';
import 'package:bloomsafe/features/learn/presentation/widgets/article_card.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// Screen for displaying educational content on air quality and health
class LearnScreen extends StatelessWidget {
  /// Creates a new learn screen
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get analytics service for screen tracking
    final analytics = di.sl<AnalyticsServiceInterface>();

    // Log screen view
    analytics.logScreenView('learn_screen');

    final learnProvider = Provider.of<LearnProvider>(context);
    // Get screen size for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: neutralLight, // Use the theme's neutralLight color
      appBar: const BloomAppBar(),
      body:
          learnProvider.isLoading
              ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
              : RefreshIndicator(
                color: primaryColor,
                onRefresh: () => learnProvider.loadArticles(),
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? spacingSmall : spacingMedium,
                  ),
                  children: [
                    // Introduction section
                    Padding(
                      padding: const EdgeInsets.only(
                        top: spacingLarge,
                        bottom: spacingMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Learn About Your Fertility Journey',
                            style: headingStyle,
                          ),
                          const SizedBox(height: spacingSmall),
                          const Text(
                            'Discover how PM2.5 levels impact fertility and pregnancy outcomes, with evidence-based strategies to protect your reproductive health.',
                            style: secondaryStyle,
                          ),
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
                      ),
                    ),

                    // Categories and articles
                    ...learnProvider.categories.map((category) {
                      final articles = learnProvider.getArticlesByCategory(
                        category,
                      );

                      if (articles.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: spacingLarge),
                        decoration: BoxDecoration(
                          color: neutralWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: secondaryColor, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: spacingMedium),
                            // Category header
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    isSmallScreen
                                        ? spacingSmall
                                        : spacingMedium,
                              ),
                              child: Text(
                                category,
                                style: subheadingStyle.copyWith(
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: spacingSmall),
                            // Light grey divider
                            Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1,
                            ),
                            const SizedBox(height: spacingMedium),
                            // Articles in this category
                            ...articles.map(
                              (article) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      isSmallScreen
                                          ? spacingSmall
                                          : spacingMedium,
                                ),
                                child: ArticleCard(article: article),
                              ),
                            ),
                            const SizedBox(height: spacingMedium),
                          ],
                        ),
                      );
                    }),

                    // Medical disclaimer
                    const Padding(
                      padding: EdgeInsets.only(bottom: spacingMedium),
                      child: DisclaimerWidget(),
                    ),

                    // Bottom padding
                    const SizedBox(height: spacingLarge),
                  ],
                ),
              ),
    );
  }
}
