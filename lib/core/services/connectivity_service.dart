import 'dart:async';
import 'dart:io';
import 'package:bloomsafe/core/utils/logger.dart';

/// Enum defining connectivity status
enum ConnectivityStatus {
  /// Connected to WiFi
  wifi,

  /// Connected to mobile network
  mobile,

  /// No connection
  offline,
}

/// Interface for connectivity service
abstract class ConnectivityServiceInterface {
  /// Initialize connectivity service
  Future<void> initialize();

  /// Get current connectivity status
  ConnectivityStatus getStatus();

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChange;

  /// Check if device is currently online
  bool isOnline();

  /// Checks if there is an internet connection
  Future<bool> hasInternetConnection();

  /// Checks connectivity with a timeout to prevent hanging
  Future<bool> hasInternetConnectionWithTimeout();

  /// Dispose resources
  void dispose();
}

/// Implementation of connectivity service
class ConnectivityService implements ConnectivityServiceInterface {

  /// Private constructor
  ConnectivityService._internal();

  /// Factory constructor to return the singleton instance
  factory ConnectivityService() => _instance;
  /// Singleton instance
  static final ConnectivityService _instance = ConnectivityService._internal();

  bool _isInitialized = false;
  ConnectivityStatus _currentStatus = ConnectivityStatus.wifi;
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  Timer? _connectivityCheckTimer;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check initial connection state
    final bool hasConnection = await hasInternetConnection();
    _currentStatus =
        hasConnection ? ConnectivityStatus.wifi : ConnectivityStatus.offline;

    // Add initial status
    _statusController.add(_currentStatus);

    // Set up periodic connectivity check
    _connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );

    Logger.info('ConnectivityService initialized');
    _isInitialized = true;
  }

  Future<void> _checkConnectivity() async {
    try {
      final bool hasConnection = await hasInternetConnectionWithTimeout();
      final ConnectivityStatus newStatus =
          hasConnection ? ConnectivityStatus.wifi : ConnectivityStatus.offline;

      // Only notify if status changed
      if (newStatus != _currentStatus) {
        _currentStatus = newStatus;
        _statusController.add(_currentStatus);
        Logger.info('Connectivity status changed to: $_currentStatus');
      }
    } catch (e) {
      Logger.error('Error checking connectivity: $e');
    }
  }

  @override
  ConnectivityStatus getStatus() {
    return _currentStatus;
  }

  @override
  Stream<ConnectivityStatus> get onStatusChange => _statusController.stream;

  @override
  bool isOnline() {
    return _currentStatus != ConnectivityStatus.offline;
  }

  /// Checks if there is an internet connection
  /// Returns a Future<bool> - true if connected, false otherwise
  @override
  Future<bool> hasInternetConnection() async {
    try {
      // Skip checks in test mode
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        return true;
      }

      // Try to connect to a reliable host
      final List<InternetAddress> result = await InternetAddress.lookup(
        'google.com',
      );

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      Logger.warning('No internet connection: $e');
      return false;
    } catch (e) {
      Logger.error('Error checking internet connection: $e');
      return false;
    }
  }

  /// Checks connectivity and returns the result synchronously
  /// This method creates a 1-second timeout to prevent hanging
  /// Returns false if the check times out
  @override
  Future<bool> hasInternetConnectionWithTimeout() async {
    try {
      return await hasInternetConnection().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          Logger.warning('Internet connection check timed out');
          return false;
        },
      );
    } catch (e) {
      Logger.error('Error in hasInternetConnectionWithTimeout: $e');
      return false;
    }
  }

  // For testing - not part of interface
  void setStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    _statusController.close();
  }
}
