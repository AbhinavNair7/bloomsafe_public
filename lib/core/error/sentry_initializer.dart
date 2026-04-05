import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:bloomsafe/core/config/environment.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/flavors.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Initializes and configures Sentry for error reporting with enhanced privacy controls
class SentryInitializer {
  /// Initialize Sentry with privacy-optimized configuration
  static Future<void> initialize({
    required EnvConfig envConfig,
    required Environment environment,
  }) async {
    try {
      // Try secure storage first, fallback to environment variable
      final sentryDsn = await envConfig.getSecureSentryDsn();

      // Skip initialization if DSN is not provided
      if (sentryDsn == null || sentryDsn.isEmpty) {
        Logger.warning('Sentry DSN not found, skipping Sentry initialization');
        return;
      }

      // Get package info for release name
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // Initialize Sentry with privacy-focused configuration
      await SentryFlutter.init((options) {
        options.dsn = sentryDsn;
        options.environment = environment.flavorName;
        
        // CRITICAL: Prevent IP collection at the source
        options.sendDefaultPii = false;
        options.attachStacktrace = true; // Keep for debugging
        options.enableAutoSessionTracking = false; // Disable session tracking for privacy
        
        // Configure sample rates based on environment
        options.tracesSampleRate = environment.isDev ? 0.3 : 1.0;
        
        // Set release name using standard format
        options.release = '$appName@$version+$buildNumber';
        
        // Privacy configuration
        options.enableNativeCrashHandling = true;
        options.attachScreenshot = false; // Privacy compliance
        options.enableAutoNativeBreadcrumbs = true;
        
        // CRITICAL FIX: Block IP at network level BEFORE processing
        options.beforeSend = (event, hint) {
          // Step 1: Block IP collection at request level (happens FIRST)
          var cleanedEvent = event;
          if (event.request != null) {
            cleanedEvent = event.copyWith(
              request: event.request!.copyWith(
                env: const {}, // Clear environment variables that might contain IP
                headers: const {}, // Clear headers that might contain IP
                // Keep only essential data for debugging
              ),
            );
          }
          
          // Step 2: Apply complete sanitization
          return _sanitizeEventForPrivacy(cleanedEvent);
        };
      });

      // Add global tags after initialization
      Sentry.configureScope((scope) {
        scope.setTag('flavor', F.name);
        scope.setTag('environment', environment.flavorName);
        scope.setTag('data_classification', 'health_wellness');
        scope.setTag('privacy_mode', 'enhanced');
      });

      Logger.info(
        'Sentry initialized with enhanced privacy for environment: ${environment.flavorName}',
      );
    } catch (e) {
      // Never let Sentry initialization crash the app
      Logger.error('Failed to initialize Sentry: $e');
    }
  }

  /// Privacy-focused event sanitization for BloomSafe reproductive health app
  static SentryEvent? _sanitizeEventForPrivacy(SentryEvent event) {
    // Step 1: Remove all user identification (request already cleaned in beforeSend)
    var sanitizedEvent = event.copyWith(
      user: null, // Remove any user context
      // Request headers/env already cleared in beforeSend callback
    );
    
    // Step 2: Create minimal context with only essential debugging info (no location data)
    final originalContexts = sanitizedEvent.contexts;
    final sanitizedContexts = Contexts();
    
    // Keep only minimal device info for debugging
    if (originalContexts.device != null) {
      sanitizedContexts.device = SentryDevice(
        family: originalContexts.device!.family, // iOS/Android only
        simulator: originalContexts.device!.simulator, // For debugging context
        // All other device properties (timezone, locale, etc.) excluded
      );
    }
    
    // Keep minimal OS info without version details
    if (originalContexts.operatingSystem != null) {
      sanitizedContexts.operatingSystem = SentryOperatingSystem(
        name: originalContexts.operatingSystem!.name, // iOS/Android only
        // Version and build details removed to prevent fingerprinting
      );
    }
    
    // Keep minimal app info
    if (originalContexts.app != null) {
      sanitizedContexts.app = SentryApp(
        name: 'BloomSafe',
        version: originalContexts.app!.version,
        // Remove detailed build info
      );
    }
    
    // Keep minimal runtime info
    sanitizedContexts.runtimes = [
      SentryRuntime(name: 'Flutter'),
      SentryRuntime(name: 'Dart'),
    ];
    
    // Step 3: Apply sanitized contexts
    sanitizedEvent = sanitizedEvent.copyWith(contexts: sanitizedContexts);
    
    // Step 4: Clean error messages
    if (sanitizedEvent.message?.formatted != null) {
      sanitizedEvent = sanitizedEvent.copyWith(
        message: sanitizedEvent.message!.copyWith(
          formatted: _sanitizeErrorMessage(sanitizedEvent.message!.formatted!),
        ),
      );
    }
    
    // Step 5: Clean exception messages
    if (sanitizedEvent.exceptions != null) {
      final sanitizedExceptions = sanitizedEvent.exceptions!.map((exception) {
        return exception.copyWith(
          value: exception.value != null 
            ? _sanitizeErrorMessage(exception.value!) 
            : null,
        );
      }).toList();
      
      sanitizedEvent = sanitizedEvent.copyWith(exceptions: sanitizedExceptions);
    }
    
    // Step 6: Set privacy-compliant metadata
    return sanitizedEvent.copyWith(
      extra: {
        'app_name': 'bloomsafe',
        'privacy_mode': 'enhanced',
      },
      tags: {
        'health_app': 'reproductive_wellness',
      },
    );
  }

  /// Generic location-agnostic error message sanitization
  static String _sanitizeErrorMessage(String message) {
    return message
        // Preserve zipcode anonymization (maintain existing 335XX format)
        .replaceAll(RegExp(r'zipcode: \d{5}'), 'zipcode: [ANONYMIZED]')
        .replaceAll(RegExp(r'\b\d{5}\b'), '[ZIPCODE]')
        
        // Remove ANY geographic location patterns (generic, not region-specific)
        .replaceAll(RegExp(r'\b[A-Z][a-z]+,\s*[A-Z][a-z]+(\s*\([A-Z]{2,3}\))?\b'), '[LOCATION_REMOVED]')
        
        // Remove IP addresses
        .replaceAll(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '[IP_REMOVED]')
        
        // Normalize timezone references to generic UTC
        .replaceAll(RegExp(r'\b[A-Z]{3,4}([+-]\d{1,2})?\b'), 'UTC')
        
        // Normalize any locale indicators to US default
        .replaceAll(RegExp(r'\ben[-_][A-Z]{2}\b'), 'en_US')
        
        // Remove any remaining location-identifying patterns
        .replaceAll(RegExp(r'\b(timezone:|locale:|region:)\s*\S+', caseSensitive: false), '[LOCATION_DATA_REMOVED]');
  }
}
