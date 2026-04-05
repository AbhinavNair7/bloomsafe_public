import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart' as sentry;
import 'package:bloomsafe/core/utils/pii_sanitizer.dart';

/// SentryHelper provides an abstraction to work with Sentry
/// without requiring direct imports of the Sentry package.
///
/// This helps avoid linter errors when Sentry is dynamically loaded.
@visibleForTesting
class SentryHelper {
  /// Report an exception to Sentry without directly importing it
  static Future<void> captureException(
    dynamic exception,
    StackTrace stackTrace, {
    Map<String, dynamic>? extra,
    List<String>? tags,
  }) async {
    try {
      // Only sanitize zipcodes in exception messages
      final sanitizedExceptionMessage = exception is String 
          ? PiiSanitizer.sanitizeString(exception)
          : PiiSanitizer.sanitizeString(exception.toString());
      
      // Use direct call to Sentry with sanitized exception
      await sentry.Sentry.captureException(
        sanitizedExceptionMessage, 
        stackTrace: stackTrace,
      );

      // Add extras as structured breadcrumbs (sanitized for zipcodes only)
      if (extra != null && extra.isNotEmpty) {
        final sanitizedExtra = PiiSanitizer.sanitizeMap(extra);
        _addBreadcrumb('Error Context', sanitizedExtra);
      }

      // Add tags if provided (sanitized for zipcodes only)
      if (tags != null && tags.isNotEmpty) {
        final sanitizedTags = tags.map((tag) => PiiSanitizer.sanitizeString(tag)).toList();
        await _addTags(sanitizedTags);
      }
    } catch (e) {
      Logger.error('Error reporting exception to Sentry: $e');
    }
  }

  /// Report a message to Sentry without directly importing it
  static Future<void> captureMessage(
    String message, {
    Map<String, dynamic>? extras,
    SentryLevel level = SentryLevel.info,
  }) async {
    try {
      // Map our level enum to Sentry's level enum
      final sentryLevel = _mapToSentryLevel(level);

      // Only sanitize zipcodes in messages
      final sanitizedMessage = PiiSanitizer.sanitizeString(message);

      // Add extras as structured breadcrumbs (sanitized for zipcodes only)
      if (extras != null && extras.isNotEmpty) {
        final sanitizedExtras = PiiSanitizer.sanitizeMap(extras);
        _addBreadcrumb('Message Context', sanitizedExtras);
      }

      // Use direct call to Sentry with sanitized message
      await sentry.Sentry.captureMessage(sanitizedMessage, level: sentryLevel);
    } catch (e) {
      Logger.error('Error reporting message to Sentry: $e');
    }
  }

  /// Configure Sentry scope with tags
  static void configureScope(Function(dynamic) scopeCallback) {
    try {
      // Use direct call to Sentry
      sentry.Sentry.configureScope((scope) {
        scopeCallback(scope);
      });
    } catch (e) {
      Logger.error('Error configuring Sentry scope: $e');
    }
  }

  /// Add a tag to the current Sentry scope
  static Future<void> addTag(String key, String value) async {
    try {
      // Only sanitize zipcodes in tag values
      final sanitizedKey = key;
      final sanitizedValue = PiiSanitizer.sanitizeString(value);
      
      configureScope((scope) {
        try {
          scope.setTag(sanitizedKey, sanitizedValue);
        } catch (e) {
          Logger.error('Error setting tag $sanitizedKey: $e');
        }
      });
    } catch (e) {
      Logger.error('Error adding tag to Sentry: $e');
    }
  }

  /// Add multiple tags to the current Sentry scope
  static Future<void> _addTags(List<String> tags) async {
    for (final tag in tags) {
      if (tag.contains(':')) {
        final parts = tag.split(':');
        if (parts.length == 2) {
          await addTag(parts[0].trim(), parts[1].trim());
        }
      }
    }
  }

  /// Add a breadcrumb to the current Sentry scope
  static void _addBreadcrumb(String category, Map<String, dynamic> data) {
    try {
      // Data should already be sanitized for zipcodes by the caller
      sentry.Sentry.addBreadcrumb(
        sentry.Breadcrumb(
          category: category,
          data: PiiSanitizer.removeSanitizationMarker(data),
          level: sentry.SentryLevel.info,
        ),
      );
    } catch (e) {
      Logger.error('Error adding breadcrumb to Sentry: $e');
    }
  }

  /// Add a public breadcrumb to the current Sentry scope with a message
  /// 
  /// Use this to create breadcrumbs that trace user flows and application state
  static void addBreadcrumb(
    String category,
    String message, {
    Map<String, dynamic>? data,
  }) {
    try {
      // Only sanitize zipcodes in message and data
      final sanitizedMessage = PiiSanitizer.sanitizeString(message);
      final sanitizedData = data != null ? PiiSanitizer.sanitizeMap(data) : null;
      
      sentry.Sentry.addBreadcrumb(
        sentry.Breadcrumb(
          category: category,
          message: sanitizedMessage,
          data: sanitizedData != null ? PiiSanitizer.removeSanitizationMarker(sanitizedData) : null,
          level: sentry.SentryLevel.info,
        ),
      );
    } catch (e) {
      Logger.error('Error adding breadcrumb to Sentry: $e');
    }
  }

  /// Start a performance transaction for monitoring
  static dynamic startTransaction(String name, String operation) {
    try {
      // Only sanitize zipcodes in transaction names/operations
      final sanitizedName = PiiSanitizer.sanitizeString(name);
      final sanitizedOperation = PiiSanitizer.sanitizeString(operation);
      
      // Use direct call to Sentry
      return sentry.Sentry.startTransaction(sanitizedName, sanitizedOperation);
    } catch (e) {
      Logger.error('Error starting Sentry transaction: $e');
    }
    return null;
  }

  /// Finish a performance transaction
  static void finishTransaction(dynamic transaction) {
    if (transaction == null) return;

    try {
      transaction.finish();
    } catch (e) {
      Logger.error('Error finishing Sentry transaction: $e');
    }
  }

  /// Map our SentryLevel enum to Sentry's SentryLevel enum
  static sentry.SentryLevel _mapToSentryLevel(SentryLevel level) {
    switch (level) {
      case SentryLevel.debug:
        return sentry.SentryLevel.debug;
      case SentryLevel.info:
        return sentry.SentryLevel.info;
      case SentryLevel.warning:
        return sentry.SentryLevel.warning;
      case SentryLevel.error:
        return sentry.SentryLevel.error;
      case SentryLevel.fatal:
        return sentry.SentryLevel.fatal;
    }
  }

  /// Monitor an operation with a Sentry transaction and return its result
  /// 
  /// This is a convenience method to wrap an operation with a transaction.
  /// Example usage:
  /// ```dart
  /// final result = await SentryHelper.monitorOperation(
  ///   'fetch_data',
  ///   'network',
  ///   () async => await repository.fetchData(),
  /// );
  /// ```
  static Future<T> monitorOperation<T>(
    String name,
    String operation,
    Future<T> Function() callback, {
    Map<String, dynamic>? tags,
  }) async {
    final transaction = startTransaction(name, operation);
    try {
      // Add operation tags if provided (sanitized)
      if (tags != null && tags.isNotEmpty && transaction != null) {
        final sanitizedTags = PiiSanitizer.sanitizeMap(tags);
        for (final entry in sanitizedTags.entries) {
          if (entry.key != PiiSanitizer.sanitizedMarker) {
            transaction.setTag(entry.key, entry.value.toString());
          }
        }
      }
      
      // Execute the operation
      return await callback();
    } catch (e, stackTrace) {
      // If there's an error, attach it to the transaction
      if (transaction != null) {
        transaction.setTag('error', 'true');
        transaction.setTag('error_type', e.runtimeType.toString());
      }
      
      // Still need to report the error separately
      await captureException(
        e, 
        stackTrace,
        extra: {'transaction': name, 'operation': operation},
      );
      
      // Rethrow to maintain normal error flow
      rethrow;
    } finally {
      // Always finish the transaction
      finishTransaction(transaction);
    }
  }
}

/// Sentry severity levels for message reporting
enum SentryLevel { debug, info, warning, error, fatal }
