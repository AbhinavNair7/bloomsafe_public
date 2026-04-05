import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:bloomsafe/core/config/environment.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/error/sentry_initializer.dart';
import 'package:bloomsafe/flavors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bloomsafe/core/config/firebase/firebase_options.dart';

/// Utility class to handle common app initialization logic across flavors
class AppInitializer {
  /// Initialize the app with the specified flavor
  static Future<void> initialize({required Flavor flavor}) async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Configure logger early for better debugging
    Logger.configure(
      showTimestamps: true, 
      debugInRelease: flavor == Flavor.dev,
    );
    
    // 2. Initialize environment with proper flavor setting
    final environment = Environment();
    environment.setFlavor(flavor);
    Logger.info('Set ${flavor.name} environment');

    // 3. Initialize environment (loads the proper .env file)
    await environment.initialize();

    // 4. Initialize timezone database early
    tz.initializeTimeZones();

    // 5. Initialize environment configuration to access env vars
    final envConfig = EnvConfig();
    await envConfig.initialize(fileName: environment.envFile);
    
    // 6. Set app flavor
    F.appFlavor = flavor;

    // 7. Initialize Firebase with error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      Logger.info('Firebase initialized successfully');
    } catch (e) {
      Logger.error('Firebase initialization failed: $e');
      Logger.warning('Using mock services due to Firebase initialization failure');
    }

    // 8. Initialize Sentry with environment context (before other services)
    await SentryInitializer.initialize(
      envConfig: envConfig,
      environment: environment,
    );

    // 9. Initialize service locator with the correct environment file
    await di.initServiceLocator(environmentFileName: environment.envFile);

    Logger.info('Application initialized with ${flavor.name} flavor');
  }
}
