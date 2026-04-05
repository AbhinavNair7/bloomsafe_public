import 'package:flutter/foundation.dart';

/// Logger is a core utility class that provides consistent logging across the app.
///
/// This belongs in core/utils because it's a cross-cutting concern used by multiple features
/// and isn't specific to any particular feature domain.
class Logger {
  /// Log levels in order of increasing severity
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  static const int _levelCritical = 4;

  /// The current minimum log level to display
  /// Debug logs are only shown in debug mode
  static int _minLevel = kDebugMode ? _levelDebug : _levelInfo;

  /// Whether to show timestamps in log messages
  static bool _showTimestamps = true;

  /// Whether this is a test environment
  static bool _isTestEnvironment = false;

  /// The logger implementation to use
  static LoggerImplementation _implementation = DefaultLoggerImplementation();

  /// Configure the logger settings
  static void configure({
    bool showTimestamps = true,
    bool debugInRelease = false,
    bool isTestEnvironment = false,
    LoggerImplementation? implementation,
    LogLevel? minLevel,
  }) {
    _showTimestamps = showTimestamps;
    _isTestEnvironment = isTestEnvironment;

    if (implementation != null) {
      _implementation = implementation;
    }

    if (minLevel != null) {
      _minLevel = _convertLogLevel(minLevel);
    } else if (debugInRelease) {
      _minLevel = _levelDebug;
    }
  }

  /// Convert from public LogLevel enum to internal level value
  static int _convertLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _levelDebug;
      case LogLevel.info:
        return _levelInfo;
      case LogLevel.warning:
        return _levelWarning;
      case LogLevel.error:
        return _levelError;
      case LogLevel.critical:
        return _levelCritical;
    }
  }

  /// Log a debug message - only visible in debug/test environment
  static void debug(String message) {
    if (_shouldLog(_levelDebug)) {
      _log(message, _levelDebug, 'DEBUG');
    }
  }

  /// Log an info message - general app information
  static void info(String message) {
    if (_shouldLog(_levelInfo)) {
      _log(message, _levelInfo, 'INFO');
    }
  }

  /// Log a warning message - potential issues that don't prevent operation
  static void warning(String message) {
    if (_shouldLog(_levelWarning)) {
      _log(message, _levelWarning, 'WARNING');
    }
  }

  /// Log an error message - errors that affect functionality
  static void error(String message) {
    if (_shouldLog(_levelError)) {
      _log(message, _levelError, 'ERROR');
    }

    // Only report to error service in production (not debug or test)
    if (!kDebugMode && !_isTestEnvironment) {
      _reportError(message, isCritical: false);
    }
  }

  /// Log a critical error message - severe errors that may crash the app
  static void critical(String message) {
    if (_shouldLog(_levelCritical)) {
      _log(message, _levelCritical, 'CRITICAL');
    }

    // Always send critical errors to error reporting in production
    if (!kDebugMode && !_isTestEnvironment) {
      _reportError(message, isCritical: true);
    }
  }

  /// Log a network request - information about network activity
  static void network(String message) {
    if (_shouldLog(_levelInfo)) {
      _log(message, _levelInfo, 'NETWORK');
    }
  }

  /// Log a performance-related message
  ///
  /// These messages provide information about app performance
  static void performance(String message) {
    if (_shouldLog(_levelInfo)) {
      _log(message, _levelInfo, 'PERFORMANCE');
    }
  }

  /// Determine if a message at the given level should be logged
  static bool _shouldLog(int level) {
    // Debug logs are only shown in debug mode or test environment by default
    return (kDebugMode || _isTestEnvironment || level >= _minLevel) &&
        level >= _minLevel;
  }

  /// Internal logging implementation with appropriate level filtering
  static void _log(String message, int level, String levelName) {
    // Skip logs below minimum level - this is a double-check as _shouldLog is usually called first
    if (level < _minLevel) return;

    // All console logging is now guarded by the public methods
    final String timestamp =
        _showTimestamps ? '[${DateTime.now().toIso8601String()}] ' : '';

    // Different emoji prefixes for different log levels
    final String emoji =
        level == _levelDebug
            ? '🔍'
            : level == _levelInfo
            ? 'ℹ️'
            : level == _levelWarning
            ? '⚠️'
            : level == _levelError
            ? '❌'
            : '🔥';

    final String fullMessage = '$timestamp$emoji [$levelName] $message';

    // Forward to implementation
    _implementation.log(fullMessage, level, levelName);
  }

  /// Report errors to error reporting service in production
  static void _reportError(String message, {required bool isCritical}) {
    // No direct console output in production
    // Errors will be reported through the ErrorReporter class
    // which centralizes Sentry reporting
  }

  /// For testing only - resets the logger to default settings
  @visibleForTesting
  static void resetForTesting() {
    _showTimestamps = true;
    _isTestEnvironment = false;
    _minLevel = kDebugMode ? _levelDebug : _levelInfo;
    _implementation = DefaultLoggerImplementation();
  }
}

/// Public enum for configuring log levels
enum LogLevel { debug, info, warning, error, critical }

/// Interface for logger implementations
abstract class LoggerImplementation {
  /// Log a message with given level and name
  void log(String formattedMessage, int level, String levelName);
}

/// Default implementation that logs to console with color coding
class DefaultLoggerImplementation implements LoggerImplementation {
  @override
  void log(String formattedMessage, int level, String levelName) {
    // Only output in debug mode or test environment
    if (!kDebugMode && !Logger._isTestEnvironment) return;

    // Print to console with color coding
    if (level >= Logger._levelCritical) {
      debugPrint('\x1B[31m$formattedMessage\x1B[0m'); // Red for critical
    } else if (level >= Logger._levelError) {
      debugPrint('\x1B[31m$formattedMessage\x1B[0m'); // Red for errors
    } else if (level >= Logger._levelWarning) {
      debugPrint('\x1B[33m$formattedMessage\x1B[0m'); // Yellow for warnings
    } else if (level >= Logger._levelInfo) {
      debugPrint('\x1B[36m$formattedMessage\x1B[0m'); // Cyan for info
    } else {
      debugPrint('\x1B[90m$formattedMessage\x1B[0m'); // Gray for debug
    }
  }
}
