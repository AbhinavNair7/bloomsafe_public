import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:bloomsafe/core/network/api_client.dart';
import 'package:bloomsafe/core/services/connectivity_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';

/// A utility class for creating and managing mocks in tests
///
/// This class helps with:
/// - Creating and registering mock dependencies
/// - Providing test-specific implementations
/// - Cleaning up after tests
class MockServiceLocator {
  /// The GetIt instance used for dependency injection
  static final GetIt _instance = GetIt.instance;

  /// Flag to track if mock services have been initialized
  static bool _initialized = false;

  /// Initialize mock services
  static void init() {
    if (_initialized) return;

    // Clear any previous registrations
    if (_instance.isRegistered<ApiClient>()) {
      _instance.unregister<ApiClient>();
    }

    if (_instance.isRegistered<ConnectivityService>()) {
      _instance.unregister<ConnectivityService>();
    }

    if (_instance.isRegistered<AQIRepository>()) {
      _instance.unregister<AQIRepository>();
    }

    if (_instance.isRegistered<AnalyticsServiceInterface>()) {
      _instance.unregister<AnalyticsServiceInterface>();
    }

    // Register mocks
    _instance.registerSingleton<ApiClient>(MockApiClient());
    _instance.registerSingleton<ConnectivityService>(MockConnectivityService());
    _instance.registerSingleton<AQIRepository>(MockAQIRepository());
    _instance.registerSingleton<AnalyticsServiceInterface>(
      MockAnalyticsService(),
    );

    _initialized = true;
  }

  /// Reset all mocks to their initial state
  static void resetMocks() {
    if (!_initialized) return;

    reset(_instance<ApiClient>());
    reset(_instance<ConnectivityService>());
    reset(_instance<AQIRepository>());
    reset(_instance<AnalyticsServiceInterface>());
  }

  /// Clean up and remove all registrations
  static void tearDown() {
    if (!_initialized) return;

    _instance.unregister<ApiClient>();
    _instance.unregister<ConnectivityService>();
    _instance.unregister<AQIRepository>();
    _instance.unregister<AnalyticsServiceInterface>();

    _initialized = false;
  }
}

// Define mock classes
class MockApiClient extends Mock implements ApiClient {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAQIRepository extends Mock implements AQIRepository {}

class MockAnalyticsService extends Mock implements AnalyticsServiceInterface {
  @override
  Future<void> initialize() async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> logFeedbackSubmitted(String feedbackType) async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> logAqiSearch(String zipcode, bool success) async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> logAqiResultViewed(
    String severityLevel,
    double pm25Value, {
    String? reportingArea,
    String? stateCode,
  }) async {
    // No-op for tests
    return Future<void>.value();
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    // No-op for tests
    return Future<void>.value();
  }
}
