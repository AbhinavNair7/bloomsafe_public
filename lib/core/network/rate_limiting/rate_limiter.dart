import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limiting_strategy.dart';
import 'package:bloomsafe/core/network/rate_limiting/rate_limit_storage.dart';
import 'package:bloomsafe/core/config/env_config.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;

/// Enhanced rate limiter that tracks API usage and prevents exceeding rate limits
class RateLimiter extends ChangeNotifier with WidgetsBindingObserver {

  /// Private constructor for the singleton
  RateLimiter._({
    RateLimitStorage? storage,
    Duration cleanupInterval = defaultCleanupInterval,
  }) : _storage = storage ?? SecureStorageRateLimitStorage() {
    WidgetsBinding.instance.addObserver(this);
    _init(cleanupInterval);
  }

  /// Factory constructor that returns the singleton instance
  factory RateLimiter({
    RateLimitStorage? storage,
    Duration cleanupInterval = defaultCleanupInterval,
  }) {
    _instance ??= RateLimiter._(
      storage: storage,
      cleanupInterval: cleanupInterval,
    );
    return _instance!;
  }

  /// Test-specific constructor that skips storage initialization
  @visibleForTesting
  factory RateLimiter.forTest() {
    if (_instance != null) {
      _instance!._cleanupTimer?.cancel();
      _instance!.dispose();
    }

    // Create a non-storing implementation for tests
    final testStorage = _TestRateLimitStorage();
    _instance = RateLimiter._(storage: testStorage);
    _instance!._initialized = true;
    return _instance!;
  }
  // Singleton instance
  static RateLimiter? _instance;

  // Rate limit strategy
  late RateLimitingStrategy _strategy;

  // Current status
  RateLimitStatus _currentStatus = RateLimitStatus.normal;

  // Storage implementation
  final RateLimitStorage _storage;

  // Timer for automatically checking and clearing request counts
  Timer? _cleanupTimer;

  // Initialization status
  bool _initialized = false;

  // Default cleanup check interval
  static const Duration defaultCleanupInterval = Duration(seconds: 30);

  /// Reset the instance for testing purposes
  @visibleForTesting
  static void resetForTesting() {
    if (_instance != null) {
      _instance!._cleanupTimer?.cancel();
      _instance!.dispose();
    }
    _instance = null;
  }

  /// Check if rate limiting is disabled in environment
  bool get _isRateLimitingDisabled {
    try {
      // Try to get the EnvConfig instance from the service locator
      final envConfig = di.sl<EnvConfig>();
      return envConfig.disableRateLimit;
    } catch (e) {
      // If unable to get EnvConfig (like during tests), default to false
      return false;
    }
  }

  /// Initialize the rate limiter
  Future<void> _init([
    Duration cleanupInterval = defaultCleanupInterval,
  ]) async {
    // Set the default strategy
    _strategy = ClientSideRateLimitingStrategy();

    // Setup cleanup timer
    _setupCleanupTimer(cleanupInterval);

    _initialized = true;

    // Update status immediately
    await _updateStatusFromStorage();

    // Log initialization
    Logger.debug(
      'RateLimiter: Initialized with ${_strategy.rateLimitType} strategy',
    );

    // Log if rate limiting is disabled
    if (_isRateLimitingDisabled) {
      Logger.info(
        'RateLimiter: Rate limiting is DISABLED by environment setting',
      );
    }
  }

  /// Setup a timer to periodically check and clean up rate limits
  void _setupCleanupTimer([Duration interval = defaultCleanupInterval]) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) {
      // Only reset count if not locked out
      _resetCountIfMinutePassed();
      // Check if lockout period (10 minutes) has expired
      _checkAndClearLockout();
    });
  }

  /// Reset request count if a minute has passed since last reset
  Future<void> _resetCountIfMinutePassed() async {
    final isLocked = await _storage.loadLockoutState(_strategy.rateLimitType);
    if (isLocked) return; // Don't reset counter during lockout

    final lastResetTime = await _storage.loadLastResetTime(
      _strategy.rateLimitType,
    );
    final now = DateTime.now();

    // Reset counter if a minute has passed since last reset
    if (lastResetTime != null && now.difference(lastResetTime).inMinutes >= 1) {
      await _storage.saveRequestCount(_strategy.rateLimitType, 0);
      await _storage.saveLastResetTime(_strategy.rateLimitType, now);

      // Update status after resetting count
      await _updateStatusFromStorage();
    }
  }

  /// Check if lockout has expired and clear if needed
  Future<void> _checkAndClearLockout() async {
    final isLocked = await _storage.loadLockoutState(_strategy.rateLimitType);
    if (!isLocked) return;

    final lockoutTime = await _storage.loadLastResetTime(
      _strategy.rateLimitType,
    );
    if (lockoutTime == null) {
      // Invalid state - clear lockout
      await _storage.saveLockoutState(_strategy.rateLimitType, false);
      return;
    }

    final now = DateTime.now();
    final lockoutDurationSecs = _strategy.lockoutDurationMinutes * 60;

    // Clear lockout if duration has passed
    if (now.difference(lockoutTime).inSeconds >= lockoutDurationSecs) {
      await _storage.saveLockoutState(_strategy.rateLimitType, false);
      await _storage.saveRequestCount(_strategy.rateLimitType, 0);
      await _updateStatusFromStorage();
    }
  }

  /// Clear old request counts when appropriate
  Future<void> clearOldRequestCounts() async {
    await _ensureInitialized();
    await _resetCountIfMinutePassed();
  }

  /// Check if lockout should be expired
  Future<void> checkLockoutExpiration() async {
    await _ensureInitialized();
    await _checkAndClearLockout();
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The app has come back to the foreground
      // Check for expired lockouts or reset timeframes
      _checkAndClearLockout();
      _resetCountIfMinutePassed();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Configure a specific rate limiting strategy
  void setStrategy(RateLimitingStrategy strategy) {
    _strategy = strategy;
    Logger.debug('RateLimiter: Configured strategy ${strategy.rateLimitType}');
  }

  /// Configure for client-side rate limiting (typically 5 req/min)
  void useClientSideStrategy() {
    setStrategy(ClientSideRateLimitingStrategy());
  }

  /// Configure a custom strategy with specific settings
  void configureStrategy({
    required int maxRequests,
    required int lockoutDurationMinutes,
  }) {
    setStrategy(
      ClientSideRateLimitingStrategy(
        maxRequests: maxRequests,
        lockoutDurationMinutes: lockoutDurationMinutes,
      ),
    );
  }

  /// The current rate limit status
  Future<RateLimitStatus> get status async {
    await _ensureInitialized();
    await _updateStatusFromStorage();
    return _currentStatus;
  }

  /// Number of requests made in the current minute
  Future<int> get requestsThisMinute async {
    await _ensureInitialized();
    return await _storage.loadRequestCount(_strategy.rateLimitType);
  }

  /// Maximum allowed requests per minute based on the current strategy
  int get maxRequestsPerMinute => _strategy.maxRequests;

  /// Get the active rate limit type
  RateLimitType get activeRateLimitType => _strategy.rateLimitType;

  /// Get the lockout duration in minutes from the current strategy
  int get lockoutDurationMinutes => _strategy.lockoutDurationMinutes;

  /// Calculate usage percentage (0.0 to 1.0+)
  Future<double> get usagePercentage async {
    await _ensureInitialized();
    final count = await _storage.loadRequestCount(_strategy.rateLimitType);
    return _strategy.calculateUsagePercentage(count);
  }

  /// Ensure the rate limiter is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  /// Check if a request should be allowed based on current rate limit status
  Future<bool> isRequestAllowed() async {
    await _ensureInitialized();

    // If rate limiting is disabled in the environment, always allow requests
    if (_isRateLimitingDisabled) {
      Logger.debug('RateLimiter: Request allowed (rate limiting disabled)');
      return true;
    }

    final count = await _storage.loadRequestCount(_strategy.rateLimitType);
    final isInLockout = await _storage.loadLockoutState(
      _strategy.rateLimitType,
    );

    return _strategy.isRequestAllowed(count, isInLockout);
  }

  /// Record that a request has been made
  Future<void> recordRequest() async {
    await _ensureInitialized();

    // If rate limiting is disabled, don't record requests
    if (_isRateLimitingDisabled) {
      Logger.debug(
        'RateLimiter: Request not recorded (rate limiting disabled)',
      );
      return;
    }

    final oldStatus = _currentStatus;

    // Get current count & lockout state
    final count = await _storage.loadRequestCount(_strategy.rateLimitType);
    final isInLockout = await _storage.loadLockoutState(
      _strategy.rateLimitType,
    );

    if (isInLockout) {
      // We're in lockout, no need to count requests
      Logger.warning(
        'RateLimiter: Request rejected - currently in lockout period',
      );
      return;
    }

    // Get or initialize the last reset time
    var lastResetTime = await _storage.loadLastResetTime(
      _strategy.rateLimitType,
    );
    final now = DateTime.now();

    // Initialize reset time if not set
    if (lastResetTime == null) {
      lastResetTime = now;
      await _storage.saveLastResetTime(_strategy.rateLimitType, now);
    }

    // Check if it's been more than a minute since the last reset
    final timeSinceReset = now.difference(lastResetTime).inMinutes;

    if (timeSinceReset >= 1) {
      // Reset counter if it's been more than a minute
      await _storage.saveRequestCount(
        _strategy.rateLimitType,
        1,
      ); // This is the first request in new minute
      await _storage.saveLastResetTime(_strategy.rateLimitType, now);
      _currentStatus = RateLimitStatus.normal;

      Logger.debug(
        'RateLimiter: New minute - request recorded. Count: 1/${_strategy.maxRequests}',
      );
    } else {
      // Still in same minute window, increment counter
      final newCount = count + 1;
      await _storage.saveRequestCount(_strategy.rateLimitType, newCount);

      Logger.debug(
        'RateLimiter: Request recorded. Count: $newCount/${_strategy.maxRequests}',
      );

      // If we've hit or exceeded the limit (normally 5), set lockout
      if (newCount >= _strategy.maxRequests) {
        await _enterLockout(now);
      } else {
        // Update status based on new count
        _currentStatus = _strategy.getStatus(newCount, false);
      }
    }

    // Notify listeners if status changed
    if (oldStatus != _currentStatus) {
      notifyListeners();
    }
  }

  /// Helper method to enter lockout mode
  Future<void> _enterLockout(DateTime timestamp) async {
    await _storage.saveLockoutState(_strategy.rateLimitType, true);
    await _storage.saveLastResetTime(
      _strategy.rateLimitType,
      timestamp,
    ); // Start lockout timer

    _currentStatus = RateLimitStatus.exceeded;
    Logger.warning(
      'RateLimiter: Rate limit exceeded (${_strategy.maxRequests} requests). ' 'Starting ${_strategy.lockoutDurationMinutes}-minute lockout.',
    );
  }

  /// Manually trigger API lockout (used when getting 429 responses)
  Future<void> enterApiLockout() async {
    await _ensureInitialized();
    await _enterLockout(DateTime.now());
    notifyListeners();
    Logger.warning(
      'RateLimiter: API lockout manually triggered for ${_strategy.rateLimitType}',
    );
  }

  /// Calculate lockout remaining time in minutes
  Future<int> getLockoutRemainingTime() async {
    await _ensureInitialized();

    final isInLockout = await _storage.loadLockoutState(
      _strategy.rateLimitType,
    );

    if (!isInLockout) return 0;

    final lockoutStartTime = await _storage.loadLastResetTime(
      _strategy.rateLimitType,
    );
    final now = DateTime.now();

    if (lockoutStartTime == null) return 0;

    final elapsedMinutes = now.difference(lockoutStartTime).inMinutes;
    final remainingMinutes = _strategy.lockoutDurationMinutes - elapsedMinutes;

    // Ensure we don't return negative values
    return remainingMinutes > 0 ? remainingMinutes : 0;
  }

  /// Calculate remaining lockout time in seconds (more granular than minutes)
  Future<int> lockoutRemainingSeconds() async {
    await _ensureInitialized();

    final isInLockout = await _storage.loadLockoutState(
      _strategy.rateLimitType,
    );

    if (!isInLockout) return 0;

    final lockoutStartTime = await _storage.loadLastResetTime(
      _strategy.rateLimitType,
    );
    final now = DateTime.now();

    if (lockoutStartTime == null) return 0;

    final lockoutDurationSecs = _strategy.lockoutDurationMinutes * 60;
    final elapsedSeconds = now.difference(lockoutStartTime).inSeconds;
    final remainingSeconds = lockoutDurationSecs - elapsedSeconds;

    // Ensure we don't return negative values
    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  /// Updates the current status based on storage values
  Future<void> _updateStatusFromStorage() async {
    final count = await _storage.loadRequestCount(_strategy.rateLimitType);
    final isInLockout = await _storage.loadLockoutState(
      _strategy.rateLimitType,
    );

    final newStatus = _strategy.getStatus(count, isInLockout);

    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      notifyListeners();
    }
  }

  /// Set a specific maximum requests count for testing
  @visibleForTesting
  void setMaxRequestsForTest(int max) {
    if (_strategy is ClientSideRateLimitingStrategy) {
      // This is just for testing, so we're using a non-standard way to modify the strategy
      (_strategy as dynamic).maxRequests = max;
    }
  }

  /// Check if the API is currently locked out due to rate limiting
  Future<bool> isLockedOut() async {
    await _ensureInitialized();
    return await _storage.loadLockoutState(_strategy.rateLimitType);
  }
}

/// Test implementation of RateLimitStorage that operates in-memory
class _TestRateLimitStorage implements RateLimitStorage {
  final Map<RateLimitType, int> _requestCounts = {};
  final Map<RateLimitType, bool> _lockoutStates = {};
  final Map<RateLimitType, DateTime> _lastResetTimes = {};

  @override
  Future<int> loadRequestCount(RateLimitType type) async {
    return _requestCounts[type] ?? 0;
  }

  @override
  Future<void> saveRequestCount(RateLimitType type, int count) async {
    _requestCounts[type] = count;
  }

  @override
  Future<bool> loadLockoutState(RateLimitType type) async {
    return _lockoutStates[type] ?? false;
  }

  @override
  Future<void> saveLockoutState(RateLimitType type, bool isInLockout) async {
    _lockoutStates[type] = isInLockout;
  }

  @override
  Future<DateTime?> loadLastResetTime(RateLimitType type) async {
    return _lastResetTimes[type];
  }

  @override
  Future<void> saveLastResetTime(RateLimitType type, DateTime time) async {
    _lastResetTimes[type] = time;
  }

  @override
  Future<void> clearStorage() async {
    _requestCounts.clear();
    _lockoutStates.clear();
    _lastResetTimes.clear();
  }
}
