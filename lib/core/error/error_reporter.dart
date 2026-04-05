import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/error/sentry_helper.dart';
import 'package:bloomsafe/core/utils/pii_sanitizer.dart';

/// Centralized error reporting service for BloomSafe
///
/// This class handles reporting errors to Sentry while maintaining
/// privacy safeguards and logging.
@visibleForTesting
class ErrorReporter {
  /// Reports an error to Sentry and logs it via Firebase Analytics
  ///
  /// Privacy safeguards ensure zipcodes are anonymized when sent to Sentry
  static Future<void> report(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    try {
      // Log error to console first
      Logger.error('Error: $error');
      if (context != null) {
        Logger.error('Context: $context');
      }

      // Filter out any zipcodes before reporting
      final sanitizedError = PiiSanitizer.sanitizeString(error.toString());

      // Include sanitized context in the error message for Sentry
      final errorWithContext =
          context != null
              ? '$sanitizedError (Context: ${PiiSanitizer.sanitizeString(context)})'
              : sanitizedError;

      // Use SentryHelper instead of direct Sentry import
      await SentryHelper.captureException(
        errorWithContext,
        stackTrace,
        extra: extras != null ? PiiSanitizer.sanitizeMap(extras) : null,
      );

      // Log to Firebase Analytics for error metrics
      _logToAnalytics('error_occurred', {
        'error_type': error.runtimeType.toString(),
        'context': context != null ? PiiSanitizer.sanitizeString(context) : 'unknown',
      });
    } catch (e) {
      // Ensure errors in error reporting don't crash the app
      Logger.critical('Error in error reporting: $e');
      if (kDebugMode) {
        Logger.debug('Failed to report error: $e');
      }
    }
  }

  /// Reports a handled exception with custom context information
  static Future<void> reportMessage(
    String message, {
    Map<String, dynamic>? extras,
    SentryLevel level = SentryLevel.info,
  }) async {
    try {
      // Log message to console
      Logger.info(message);

      // Filter out any zipcodes
      final sanitizedMessage = PiiSanitizer.sanitizeString(message);

      // Use SentryHelper instead of direct Sentry import
      await SentryHelper.captureMessage(
        sanitizedMessage,
        extras: extras != null ? PiiSanitizer.sanitizeMap(extras) : null,
        level: level,
      );
    } catch (e) {
      Logger.warning('Failed to report message: $e');
    }
  }

  /// Helper method to log to Firebase Analytics with error handling
  static Future<void> _logToAnalytics(
    String eventName,
    Map<String, Object?> parameters,
  ) async {
    try {
      // Sanitize parameters to anonymize zipcodes
      final sanitizedParameters = PiiSanitizer.sanitizeAnalyticsParams(parameters);
      
      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: sanitizedParameters,
      );
    } catch (e) {
      Logger.warning('Failed to log to analytics: $e');
    }
  }

  /// Adds a breadcrumb to trace user interactions and app flow
  /// 
  /// Use this to add context to errors that might occur later.
  /// For example, add breadcrumbs at key points in user flows.
  /// 
  /// @param category The category of the breadcrumb (e.g., 'navigation', 'network')
  /// @param message A short message describing the action
  /// @param data Additional contextual data (will be sanitized)
  static void addBreadcrumb(
    String category,
    String message, {
    Map<String, dynamic>? data,
  }) {
    try {
      // Sanitize data to anonymize zipcodes if provided
      final sanitizedData = data != null ? PiiSanitizer.sanitizeMap(data) : null;
      
      // Log to console in debug mode for easier local debugging
      if (kDebugMode) {
        Logger.debug('Breadcrumb [$category]: $message');
      }
      
      // Add breadcrumb to Sentry
      SentryHelper.addBreadcrumb(category, message, data: sanitizedData);
    } catch (e) {
      // Never let breadcrumb tracking crash the app
      Logger.warning('Failed to add breadcrumb: $e');
    }
  }
}
