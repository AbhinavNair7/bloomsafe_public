import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/services/base_service.dart';

/// Service to handle Discord webhook communication for feedback
class DiscordService extends BaseService {

  /// Returns the singleton instance
  factory DiscordService() => _instance;

  /// Private constructor
  DiscordService._internal();
  final ConnectivityService _connectivityService = ConnectivityService();
  late final AnalyticsServiceInterface _analytics;
  String? _webhookUrl;

  /// Singleton instance
  static final DiscordService _instance = DiscordService._internal();

  @override
  Future<void> initialize() async {
    await super.initialize();

    _analytics = di.sl<AnalyticsServiceInterface>();

    // Get webhook URL from environment configuration
    final envConfig = di.sl<EnvConfig>();
    _webhookUrl = envConfig.discordWebhookUrl;

    if (_webhookUrl != null && _webhookUrl!.isNotEmpty) {
      Logger.info(
        'DiscordService initialized for ${environment.flavorName} environment',
      );
    } else {
      Logger.warning('DiscordService initialized without webhook URL');
    }
  }

  /// Initialize the service with a specific webhook URL
  /// This is useful for testing or for changing the webhook URL at runtime
  Future<void> initializeWithUrl(String webhookUrl) async {
    await super.initialize();
    _webhookUrl = webhookUrl;
    Logger.info('DiscordService initialized with custom webhook URL');
  }

  /// Check if webhook URL is set
  bool isWebhookConfigured() {
    return _webhookUrl != null && _webhookUrl!.isNotEmpty;
  }

  /// Send feedback to Discord webhook
  Future<bool> sendFeedback({
    required String feedbackType,
    required String feedbackContent,
    String? email,
  }) async {
    try {
      checkInitialized('sendFeedback');

      // Check for internet connectivity first
      final hasConnection =
          await _connectivityService.hasInternetConnectionWithTimeout();
      if (!hasConnection) {
        Logger.warning('Cannot send feedback: No internet connection');
        return false;
      }

      // Check if webhook URL is configured
      if (!isWebhookConfigured()) {
        Logger.warning(
          'Cannot send feedback: Discord webhook URL not configured',
        );
        return false;
      }

      // Create request payload with environment info
      final payload = {
        'embeds': [
          {
            'title': 'BloomSafe Feedback',
            'description': feedbackContent,
            'color': 3447003, // Blue color
            'fields': [
              {'name': 'Type', 'value': feedbackType, 'inline': true},
              {
                'name': 'Environment',
                'value': environment.flavorName,
                'inline': true,
              },
              if (email != null && email.isNotEmpty)
                {'name': 'Contact', 'value': email, 'inline': true},
              {
                'name': 'Timestamp',
                'value': DateTime.now().toIso8601String(),
                'inline': false,
              },
            ],
          },
        ],
      };

      // Send HTTP request to Discord webhook
      final response = await http.post(
        Uri.parse(_webhookUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Log analytics event
        await _analytics.logFeedbackSubmitted(feedbackType);
        Logger.info('Feedback sent to Discord webhook');
        return true;
      } else {
        Logger.error('Error sending feedback: HTTP ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.error('Exception when sending feedback: $e');
      return false;
    }
  }
}
