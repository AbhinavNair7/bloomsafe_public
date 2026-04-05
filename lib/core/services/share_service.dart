import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_severity.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/aqi_classifier.dart';
import 'package:bloomsafe/features/learn/data/models/learn_article.dart';

/// Service that handles sharing content from the app
class ShareService {

  /// Returns the singleton instance
  factory ShareService() => _instance;

  /// Private constructor
  ShareService._internal();
  final ConnectivityService _connectivityService = ConnectivityService();
  final AnalyticsServiceInterface _analytics =
      di.sl<AnalyticsServiceInterface>();

  /// Singleton instance
  static final ShareService _instance = ShareService._internal();

  /// Share AQI results
  Future<void> shareAQIResults(AQIData data, {BuildContext? context}) async {
    try {
      // Check for internet connectivity
      final hasConnection =
          await _connectivityService.hasInternetConnectionWithTimeout();
      if (!hasConnection && context != null) {
        _showConnectivityError(context);
        return;
      }

      // Get PM2.5 data
      final pm25Data = data.getPM25();
      if (pm25Data == null) {
        _showError(context, 'Cannot share: No PM2.5 data available');
        return;
      }

      // Get severity for recommendations
      final severity = AQISeverityExtension.fromAQIDoubleValue(
        pm25Data.aqi.toDouble(),
      );

      // Format timestamp
      final timestamp = data.observationDate;
      final dateFormatter = DateFormat('MMMM d, yyyy');
      final timeFormatter = DateFormat('h:mm a');
      final formattedDate = dateFormatter.format(timestamp);
      final formattedTime = timeFormatter.format(timestamp);

      // Get location information
      final location =
          data.reportingArea != null && data.stateCode != null
              ? '${data.reportingArea}, ${data.stateCode}'
              : 'Your location';

      // Get recommendation and health impact
      final recommendations = generateRecommendations(pm25Data.aqi);

      final healthImpact =
          recommendations['healthImpact'] as String? ??
          'No health impact information available.';

      final recommendationsList =
          recommendations['recommendations'] as List<dynamic>;
      final formattedRecommendations =
          recommendationsList.isNotEmpty
              ? recommendationsList.map((rec) => '• $rec').join('\n')
              : '• No specific recommendations available.';

      // Format share text
      final shareText = '''
📊 BloomSafe Air Quality Report

PM2.5 Specific AQI Level: ${pm25Data.aqi} (${severity.name})
Location: $location
Observed: $formattedDate at $formattedTime

What this means for your reproductive health:
$healthImpact

Recommended actions:
$formattedRecommendations

BloomSafe is an archived reproductive-health air quality product.
''';

      await Share.share(shareText);

      // Log analytics event for sharing AQI results
      await _analytics.logContentShared('aqi_result', 'share_button');
    } catch (e) {
      Logger.error('Error sharing AQI results: $e');
      if (context != null) {
        _showError(context, 'Could not share: ${e.toString()}');
      }
    }
  }

  /// Share article content
  Future<void> shareArticle(
    LearningArticle article, {
    BuildContext? context,
  }) async {
    try {
      // Check for internet connectivity
      final hasConnection =
          await _connectivityService.hasInternetConnectionWithTimeout();
      if (!hasConnection && context != null) {
        _showConnectivityError(context);
        return;
      }

      // Format bullet points
      final bulletPoints = article.keyTakeaways
          .map((point) => '• $point')
          .join('\n');

      // Format share text
      final shareText = '''
🌸 BloomSafe Health Insight

${article.title.toUpperCase()}

$bulletPoints

BloomSafe is an archived reproductive-health air quality product.
''';

      await Share.share(shareText, subject: article.title);

      // Log analytics event for sharing learn article
      await _analytics.logContentShared('learn_article', 'share_button');
    } catch (e) {
      Logger.error('Error sharing article: $e');
      if (context != null) {
        _showError(context, 'Could not share: ${e.toString()}');
      }
    }
  }

  /// Show connectivity error message
  void _showConnectivityError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(internetErrorDuringShareMessage),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show general error message
  void _showError(BuildContext? context, String message) {
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
