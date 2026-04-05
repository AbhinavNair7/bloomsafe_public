import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/flavors.dart';

/// A class that provides information about the current environment
class Environment {
  /// Factory constructor to return the singleton instance
  factory Environment() => _instance;

  /// Private constructor for singleton pattern
  Environment._internal();
  
  /// Singleton instance
  static final Environment _instance = Environment._internal();

  /// The current application flavor
  Flavor? _flavor;

  /// Returns the current flavor
  Flavor get flavor {
    if (_flavor == null) {
      throw StateError(
        'Environment flavor not set. Call setFlavor() first.',
      );
    }
    return _flavor!;
  }

  /// Returns true if the current flavor is dev
  bool get isDev => flavor == Flavor.dev;

  /// Returns true if the current flavor is prod
  bool get isProd => flavor == Flavor.prod;

  /// Returns the name of the current flavor
  String get flavorName => flavor.toString().split('.').last;

  /// Corresponding environment file for the flavor
  String get envFile => '.env.$flavorName';

  /// Returns true if running in debug mode
  bool get isDebug => kDebugMode;

  /// Returns true if running in release mode
  bool get isRelease => kReleaseMode;

  /// Returns true if running in profile mode
  bool get isProfile => kProfileMode;

  /// Set the flavor explicitly (called by AppInitializer)
  void setFlavor(Flavor flavor) {
    _flavor = flavor;
    Logger.info('Environment flavor set to $flavorName');
  }

  /// Initialize the environment by loading the appropriate .env file
  Future<void> initialize() async {
    try {
      await _loadEnvironmentVariables();
      Logger.info(
        'Environment initialized: flavor=$flavorName, debug=$isDebug, release=$isRelease',
      );
    } catch (e) {
      Logger.error('Failed to initialize environment: $e');
      // Initialize empty environment for secure storage fallback
      dotenv.env.clear();
      Logger.info('Initialized with empty environment - using secure storage and defaults');
    }
  }

  /// Load environment variables from the flavor-specific file
  Future<void> _loadEnvironmentVariables() async {
    final envFileName = envFile;
    try {
      await dotenv.load(fileName: envFileName);
      Logger.info('Loaded environment variables from $envFileName');
    } catch (e) {
      Logger.warning(
        'Failed to load $envFileName: $e. App will use secure storage and defaults.',
      );
      // Initialize empty environment - sensitive data comes from secure storage
      dotenv.env.clear();
    }
  }

  /// Get a value from the environment
  String? getValue(String key) {
    return dotenv.env[key];
  }
}

