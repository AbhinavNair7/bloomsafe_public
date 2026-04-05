import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/config/secure_storage.dart';
import 'package:bloomsafe/core/config/environment.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/network/mock_api_client.dart';
import 'package:bloomsafe/core/network/secure_http_client.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiter.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/repositories/aqi_repository_impl.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/cache/aqi_cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/mock_aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/core/services/discord_service.dart';
import 'package:bloomsafe/core/services/security_service.dart';
import 'package:bloomsafe/core/services/security_service_impl.dart';
import 'package:bloomsafe/core/utils/encryption_utils.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/transformers/aqi_data_transformer.dart';
import 'package:bloomsafe/features/learn/data/services/learn_service.dart';
import 'package:bloomsafe/features/learn/presentation/state/learn_provider.dart';
import 'package:bloomsafe/features/guide/data/services/guide_service.dart';
import 'package:bloomsafe/features/guide/presentation/state/guide_provider.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Global ServiceLocator instance
final sl = GetIt.instance;

/// Initialize the service locator and register all dependencies
Future<void> init({String? environmentFileName}) async {
  await initServiceLocator(environmentFileName: environmentFileName);
}

/// Initialize the service locator and register all dependencies
/// [environmentFileName] is the name of the environment file to use
Future<void> initServiceLocator({String? environmentFileName}) async {
  // Get current environment
  final env = Environment();

  // Register Environment first
  sl.registerSingleton<Environment>(env);

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register RateLimiter
  sl.registerSingleton<RateLimiter>(RateLimiter());

  // Register SecureStorage for credential management
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());

  // Register EncryptionUtils for data encryption
  sl.registerLazySingleton<EncryptionUtils>(() => EncryptionUtils());

  // Register SecurityService for security audits and validation
  sl.registerLazySingleton<SecurityService>(() => SecurityServiceImpl());

  // Environment configuration - using the provided environment file
  final envConfig = EnvConfig();
  await envConfig.initialize(fileName: environmentFileName ?? env.envFile);
  sl.registerSingleton<EnvConfig>(envConfig);

  // App config depends on EnvConfig
  final appConfig = AppConfig();
  await appConfig.initialize();
  sl.registerSingleton<AppConfig>(appConfig);

  // Core network components
  sl.registerLazySingleton<SecureHttpClient>(() => SecureHttpClient());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<EnvConfig>()));
  sl.registerLazySingleton<MockApiClient>(() => MockApiClient(sl<EnvConfig>()));

  // Register service interfaces based on environment
  _registerAnalyticsService(env);
  sl.registerLazySingleton<ConnectivityServiceInterface>(
    () => ConnectivityService(),
  );

  // Register Discord Service
  sl.registerLazySingleton<DiscordService>(() => DiscordService());

  // Transformers
  sl.registerFactory<AQIDataTransformer>(() => AQIDataTransformer());

  // AQI Feature-specific components
  sl.registerFactory<AQICacheService>(() => AQICacheService());
  sl.registerLazySingleton<AQIClient>(
    () => AQIClient(sl<ApiClient>(), sl<EnvConfig>()),
  );
  sl.registerLazySingleton<MockAQIClient>(() => MockAQIClient(sl<EnvConfig>()));

  // Feature: AQI Monitoring
  sl.registerLazySingleton<AQIRepository>(
    () => AQIRepositoryImpl(
      sl<AQIClient>(),
      mockAqiClient: sl<MockAQIClient>(),
      cacheService: sl<AQICacheService>(),
      transformer: sl<AQIDataTransformer>(),
      appConfig: sl<AppConfig>(),
    ),
  );

  // Register AQIProvider
  sl.registerLazySingleton<AQIProvider>(() => AQIProvider(sl<AQIRepository>()));

  // Feature: Learn
  sl.registerLazySingleton<LearnService>(() => LearnService());
  sl.registerLazySingleton<LearnProvider>(
    () => LearnProvider(learnService: sl<LearnService>()),
  );

  // Feature: Guide
  sl.registerLazySingleton<GuideService>(() => GuideService());
  sl.registerLazySingleton<GuideProvider>(
    () => GuideProvider(guideService: sl<GuideService>()),
  );

  // Initialize services that need immediate initialization
  await _initializeServices();
}

/// Register the appropriate analytics service based on environment
void _registerAnalyticsService(Environment env) {
  // In development, use mock analytics to avoid sending real data
  if (env.isDev) {
    Logger.info('Using MockAnalyticsService for dev environment');
    sl.registerLazySingleton<AnalyticsServiceInterface>(
      () => MockAnalyticsService(),
    );
  } else {
    // For production, use the real service
    Logger.info('Using AnalyticsService for prod environment');
    sl.registerLazySingleton<AnalyticsServiceInterface>(
      () => AnalyticsService(),
    );
  }
}

/// Initialize required services after registration
Future<void> _initializeServices() async {
  // Initialize security components
  await sl<EncryptionUtils>().initialize();
  sl<SecureHttpClient>().initialize();

  // Initialize connectivity service
  await sl<ConnectivityServiceInterface>().initialize();

  // Initialize analytics service
  await sl<AnalyticsServiceInterface>().initialize();

  // Initialize Discord service
  await sl<DiscordService>().initialize();
}

/// Reset the service locator (useful for testing)
void resetServiceLocator() {
  // Dispose services that need cleanup
  if (sl.isRegistered<ConnectivityServiceInterface>()) {
    final connectivityService = sl<ConnectivityServiceInterface>();
    if (connectivityService is ConnectivityService) {
      connectivityService.dispose();
    }
  }

  if (sl.isRegistered<AQIRepository>()) {
    final repository = sl<AQIRepository>();
    if (repository is AQIRepositoryImpl) {
      repository.dispose();
    }
  }

  if (sl.isRegistered<SharedPreferences>()) {
    sl.unregister<SharedPreferences>();
  }

  sl.reset();
}
