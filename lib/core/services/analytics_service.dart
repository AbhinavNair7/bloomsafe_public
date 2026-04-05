import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/services/base_service.dart';
import 'package:bloomsafe/core/utils/pii_sanitizer.dart';

/// Interface for analytics service
///
/// This provides a consistent API for analytics regardless of the implementation
abstract class AnalyticsServiceInterface {
  /// Initialize the analytics service
  Future<void> initialize();

  /// Log a custom event with optional parameters
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters});

  /// Set a user property which will be included with future events
  Future<void> setUserProperty(String name, String? value);

  /// Log a screen view event
  Future<void> logScreenView(String screenName, {String? screenClass});

  /// Enable or disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled);

  /// Send a test event to verify analytics is working
  Future<void> sendTestEvent();

  // BloomSafe-specific events

  /// Log an AQI search event
  Future<void> logAqiSearch(String zipcode, bool success);

  /// Log that an AQI result was viewed
  Future<void> logAqiResultViewed(
    String severityLevel,
    double pm25Value, {
    String? reportingArea,
    String? stateCode,
  });

  /// Log a guide content viewed event
  Future<void> logGuideContentViewed(String contentId, String contentName);

  /// Log a learn article viewed event
  Future<void> logLearnArticleViewed(String articleId, String articleCategory);

  /// Log a recommendation viewed event
  Future<void> logRecommendationViewed(
    String severityLevel,
    String recommendationType,
  );

  /// Log a content shared event
  Future<void> logContentShared(String contentType, String shareMethod);

  /// Log a feedback submitted event
  Future<void> logFeedbackSubmitted(String feedbackType);

  /// Log that user settings were changed
  Future<void> logSettingsChanged(String settingName, String newValue);

  /// Log an error event for monitoring
  Future<void> logError(String errorType, String message);

  // BloomSafe-specific user properties

  /// Set user's reproductive health interest
  Future<void> setReproductiveHealthInterest(String interest);

  /// Set user's typical AQI region (generalized region, not specific zipcode)
  Future<void> setAqiRegion(String region);

  /// Set how often the user checks AQI
  Future<void> setAppUsageFrequency(String frequency);

  /// Set count of educational sections completed
  Future<void> setEducationSectionsCompleted(int count);
}

/// Mock implementation of AnalyticsService for testing/development
class MockAnalyticsService extends BaseService
    implements AnalyticsServiceInterface {
  @override
  Future<void> initialize() async {
    await super.initialize();
    Logger.info('MockAnalyticsService initialized');
  }

  @override
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    checkInitialized('logEvent');
    // Log locally but don't send to any service
    Logger.debug('Mock Analytics - Event: $eventName, Params: $parameters');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    checkInitialized('setUserProperty');
    Logger.debug('Mock Analytics - User Property: $name, Value: $value');
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    checkInitialized('logScreenView');
    Logger.debug('Mock Analytics - Screen View: $screenName');
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    checkInitialized('setAnalyticsCollectionEnabled');
    Logger.debug(
      'Mock Analytics - Collection ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  @override
  Future<void> sendTestEvent() async {
    checkInitialized('sendTestEvent');
    Logger.debug('Mock Analytics - Test event sent');
  }

  @override
  Future<void> logAqiSearch(String zipcode, bool success) async {
    checkInitialized('logAqiSearch');
    // Privacy measure: Only log the first 3 digits of zipcode
    final anonymizedZipcode =
        zipcode.length > 3 ? '${zipcode.substring(0, 3)}XX' : 'unknown';

    Logger.debug(
      'Mock Analytics - AQI Search: $anonymizedZipcode, Success: $success',
    );
  }

  @override
  Future<void> logAqiResultViewed(
    String severityLevel,
    double pm25Value, {
    String? reportingArea,
    String? stateCode,
  }) async {
    checkInitialized('logAqiResultViewed');
    Logger.debug(
      'Mock Analytics - AQI Result Viewed: $severityLevel, PM2.5: $pm25Value',
    );
  }

  @override
  Future<void> logGuideContentViewed(
    String contentId,
    String contentName,
  ) async {
    checkInitialized('logGuideContentViewed');
    Logger.debug(
      'Mock Analytics - Guide Content Viewed: $contentId, $contentName',
    );
  }

  @override
  Future<void> logLearnArticleViewed(
    String articleId,
    String articleCategory,
  ) async {
    checkInitialized('logLearnArticleViewed');
    Logger.debug(
      'Mock Analytics - Learn Article Viewed: $articleId, $articleCategory',
    );
  }

  @override
  Future<void> logRecommendationViewed(
    String severityLevel,
    String recommendationType,
  ) async {
    checkInitialized('logRecommendationViewed');
    Logger.debug(
      'Mock Analytics - Recommendation Viewed: $severityLevel, $recommendationType',
    );
  }

  @override
  Future<void> logContentShared(String contentType, String shareMethod) async {
    checkInitialized('logContentShared');
    Logger.debug('Mock Analytics - Content Shared: $contentType, $shareMethod');
  }

  @override
  Future<void> logFeedbackSubmitted(String feedbackType) async {
    checkInitialized('logFeedbackSubmitted');
    Logger.debug('Mock Analytics - Feedback Submitted: $feedbackType');
  }

  @override
  Future<void> logSettingsChanged(String settingName, String newValue) async {
    checkInitialized('logSettingsChanged');
    Logger.debug('Mock Analytics - Settings Changed: $settingName, $newValue');
  }

  @override
  Future<void> logError(String errorType, String message) async {
    checkInitialized('logError');
    Logger.debug('Mock Analytics - Error: $errorType, Message: $message');
  }

  @override
  Future<void> setReproductiveHealthInterest(String interest) async {
    checkInitialized('setReproductiveHealthInterest');
    Logger.debug('Mock Analytics - Reproductive Health Interest: $interest');
  }

  @override
  Future<void> setAqiRegion(String region) async {
    checkInitialized('setAqiRegion');
    Logger.debug('Mock Analytics - AQI Region: $region');
  }

  @override
  Future<void> setAppUsageFrequency(String frequency) async {
    checkInitialized('setAppUsageFrequency');
    Logger.debug('Mock Analytics - App Usage Frequency: $frequency');
  }

  @override
  Future<void> setEducationSectionsCompleted(int count) async {
    checkInitialized('setEducationSectionsCompleted');
    Logger.debug('Mock Analytics - Education Sections Completed: $count');
  }
}

/// Implementation of analytics service using Firebase Analytics
class AnalyticsService extends BaseService
    implements AnalyticsServiceInterface {
  late FirebaseAnalytics _analytics;
  late bool _analyticsEnabled;

  /// Returns the singleton FirebaseAnalytics instance
  FirebaseAnalytics get analytics => _analytics;

  @override
  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      // Initialize the base service
      await super.initialize();

      // Get the Firebase Analytics enabled setting from environment
      final analyticsEnabledStr = getEnvValue('FIREBASE_ANALYTICS_ENABLED');
      _analyticsEnabled = analyticsEnabledStr?.toLowerCase() == 'true';

      // Initialize Firebase Analytics
      _analytics = FirebaseAnalytics.instance;

      // Set environment as user property
      await _analytics.setUserProperty(
        name: 'environment',
        value: environment.flavorName,
      );

      // Enable or disable analytics collection based on environment
      await _analytics.setAnalyticsCollectionEnabled(_analyticsEnabled);

      if (_analyticsEnabled) {
        Logger.info(
          'AnalyticsService initialized with Firebase Analytics (enabled)',
        );
      } else {
        Logger.info(
          'AnalyticsService initialized with Firebase Analytics (disabled)',
        );
      }
    } catch (e) {
      Logger.error('Failed to initialize AnalyticsService: $e');
      _analyticsEnabled = false;
    }
  }

  @override
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!isInitialized) {
      Logger.warning(
        'Analytics service not initialized when logging event: $eventName',
      );
      return;
    }

    // Skip if analytics is disabled
    if (!_analyticsEnabled) return;

    try {
      // Sanitize parameters to remove any potential PII
      final sanitizedParams = parameters != null 
          ? PiiSanitizer.sanitizeAnalyticsParams(parameters) 
          : null;
          
      await _analytics.logEvent(name: eventName, parameters: sanitizedParams);
      Logger.debug('Analytics - Event logged: $eventName, Params: $sanitizedParams');
    } catch (e) {
      Logger.error('Error logging analytics event: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (!isInitialized) {
      Logger.warning(
        'Analytics service not initialized when setting user property: $name',
      );
      return;
    }

    // Skip if analytics is disabled
    if (!_analyticsEnabled) return;

    try {
      await _analytics.setUserProperty(name: name, value: value);
      Logger.debug('Analytics - User Property set: $name, Value: $value');
    } catch (e) {
      Logger.error('Error setting user property: $e');
    }
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!isInitialized) {
      Logger.warning(
        'Analytics service not initialized when logging screen view: $screenName',
      );
      return;
    }

    // Skip if analytics is disabled
    if (!_analyticsEnabled) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      Logger.debug('Analytics - Screen View logged: $screenName');
    } catch (e) {
      Logger.error('Error logging screen view: $e');
    }
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (!isInitialized) {
      Logger.warning(
        'Analytics service not initialized when setting collection enabled: $enabled',
      );
      return;
    }

    try {
      // Only change if the value is different from current environment setting
      if (enabled != _analyticsEnabled) {
        await _analytics.setAnalyticsCollectionEnabled(enabled);
        _analyticsEnabled = enabled;
        Logger.debug(
          'Analytics collection ${enabled ? 'enabled' : 'disabled'}',
        );
      }
    } catch (e) {
      Logger.error('Error setting analytics collection enabled: $e');
    }
  }

  @override
  Future<void> sendTestEvent() async {
    if (!isInitialized) {
      Logger.warning(
        'Analytics service not initialized when sending test event',
      );
      return;
    }

    // Skip if analytics is disabled
    if (!_analyticsEnabled) return;

    try {
      await _analytics.logEvent(
        name: 'test_firebase_analytics',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'environment': environment.flavorName,
        },
      );
      Logger.debug('Test event sent to Firebase Analytics');
    } catch (e) {
      Logger.error('Error sending test event: $e');
    }
  }

  // Implementation of BloomSafe-specific events

  @override
  Future<void> logAqiSearch(String zipcode, bool success) async {
    // Privacy measure: Only log the first 3 digits of zipcode to anonymize location
    // For US zipcodes, this gives general area without specific location
    final anonymizedZipcode =
        zipcode.length > 3 ? '${zipcode.substring(0, 3)}XX' : 'unknown';

    await logEvent(
      'aqi_search',
      parameters: {
        'region_code': anonymizedZipcode, // renamed from 'zipcode' to 'region_code'
        'success_status': success.toString(),
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logAqiResultViewed(
    String severityLevel,
    double pm25Value, {
    String? reportingArea,
    String? stateCode,
  }) async {
    await logEvent(
      'aqi_result_viewed',
      parameters: {
        'severity_level': severityLevel,
        'pm25_value': pm25Value,
        'reporting_area': reportingArea,
        'state_code': stateCode,
        'environment': environment.flavorName,
      }..removeWhere((key, value) => value == null), // Remove null parameters
    );
  }

  @override
  Future<void> logGuideContentViewed(
    String contentId,
    String contentName,
  ) async {
    await logEvent(
      'guide_content_viewed',
      parameters: {
        'content_id': contentId,
        'content_name': contentName,
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logLearnArticleViewed(
    String articleId,
    String articleCategory,
  ) async {
    await logEvent(
      'learn_article_viewed',
      parameters: {
        'article_id': articleId,
        'article_category': articleCategory,
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logRecommendationViewed(
    String severityLevel,
    String recommendationType,
  ) async {
    await logEvent(
      'recommendation_viewed',
      parameters: {
        'severity_level': severityLevel,
        'recommendation_type': recommendationType,
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logContentShared(String contentType, String shareMethod) async {
    await logEvent(
      'content_shared',
      parameters: {
        'content_type': contentType,
        'share_method': shareMethod,
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logFeedbackSubmitted(String feedbackType) async {
    await logEvent(
      'feedback_submitted',
      parameters: {
        'feedback_type': feedbackType,
        'environment': environment.flavorName,
      },
    );
  }

  // Implementation of BloomSafe-specific user properties

  @override
  Future<void> setReproductiveHealthInterest(String interest) async {
    await setUserProperty('repro_health_interest', interest);
  }

  @override
  Future<void> setAqiRegion(String region) async {
    // Only store the broader region identifier, not specific location
    await setUserProperty('aqi_region', region);
  }

  @override
  Future<void> setAppUsageFrequency(String frequency) async {
    await setUserProperty('app_usage_frequency', frequency);
  }

  @override
  Future<void> setEducationSectionsCompleted(int count) async {
    await setUserProperty('edu_sections_completed', count.toString());
  }

  @override
  Future<void> logSettingsChanged(String settingName, String newValue) async {
    await logEvent(
      'settings_changed',
      parameters: {
        'setting_name': settingName,
        'new_value': newValue,
        'environment': environment.flavorName,
      },
    );
  }

  @override
  Future<void> logError(String errorType, String message) async {
    await logEvent(
      'error',
      parameters: {
        'error_type': errorType,
        'message': message,
        'environment': environment.flavorName,
      },
    );
  }
}
