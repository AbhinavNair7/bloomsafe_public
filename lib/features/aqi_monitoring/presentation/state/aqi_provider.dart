import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/error/error_processor.dart';
import 'package:bloomsafe/core/services/analytics_service.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Provider that manages AQI data state and fetching logic
class AQIProvider extends ChangeNotifier {

  /// Creates a new AQIProvider with the given repository
  /// Optionally accepts an analytics service for testing purposes
  AQIProvider(this.repository, {AnalyticsServiceInterface? analytics})
    : _analytics = analytics ?? di.sl<AnalyticsServiceInterface>();
  /// Repository for fetching AQI data
  final AQIRepository repository;

  /// Analytics service for tracking events
  final AnalyticsServiceInterface _analytics;

  /// Current AQI data
  AQIData? _data;

  /// Loading state
  bool _loading = false;

  /// Error message if any
  String? _error;

  /// Error category if an error occurred
  ErrorCategory? _errorCategory;

  /// Whether data is from cache
  bool _isFromCache = false;

  /// Last searched zipcode
  String? _lastZipcode;

  /// Current AQI data
  AQIData? get data => _data;

  /// Whether data is currently loading
  bool get isLoading => _loading;

  /// Current error message if any
  String? get error => _error;

  /// Category of the current error, if any
  ErrorCategory? get errorCategory => _errorCategory;

  /// Whether the current data is from cache
  bool get isFromCache => _isFromCache;

  /// Last zipcode that was searched
  String? get lastZipcode => _lastZipcode;

  /// Fetches AQI data for the given zipcode
  Future<void> fetchData(String zipcode) async {
    _loading = true;
    _error = null;
    _errorCategory = null;
    _isFromCache = false;
    _lastZipcode = zipcode;
    notifyListeners();

    try {
      Logger.debug('Fetching AQI data for zipcode: $zipcode');

      // Get data from repository
      _data = await repository.getAQIByZipcode(zipcode);

      // Check if data is available
      if (_data != null) {
        final pm25Data = _data?.getPM25();
        Logger.debug(
          'Successfully fetched AQI data for $zipcode: AQI=${pm25Data?.aqi}, Category=${pm25Data?.category.name}',
        );

        // Properly check if data is from cache using repository response
        // The repository should already have indicated if this was from cache
        // We shouldn't calculate cache status here based on observation time
        _isFromCache = repository.isFromCache();

        // Only log cache info if it's actually from cache
        if (_isFromCache) {
          // Calculate data age from the cache timestamp, not from observation time
          // This shows when the data was actually cached, not when it was observed
          final cacheAge = repository.getCacheAge(zipcode);
          final hours = cacheAge.inHours;
          final minutes = cacheAge.inMinutes % 60;

          final ageString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

          Logger.debug('Data is from cache ($ageString old)');
        }

        // Log successful AQI search event
        await _analytics.logAqiSearch(zipcode, true);

        // Log AQI result viewed event
        if (pm25Data != null) {
          await _analytics.logAqiResultViewed(
            pm25Data.category.name,
            pm25Data.aqi.toDouble(),
          );
        }
      } else {
        Logger.warning('Fetched AQI data is null for zipcode: $zipcode');
        // Log unsuccessful AQI search
        await _analytics.logAqiSearch(zipcode, false);
      }
    } catch (e) {
      // Process the error using ErrorProcessor for consistent handling
      final errorResult = ErrorProcessor.process(e);

      // Set error message from the processor
      _error = errorResult.userMessage;
      _errorCategory = errorResult.category;

      // Log the error with appropriate category
      Logger.error(
        '${errorResult.category} error: ${errorResult.userMessage}',
      );

      // For rate limit errors, log additional details
      if (errorResult.category == ErrorCategory.rateLimit) {
        Logger.warning(
          'Displaying rate limit message to user: "${errorResult.userMessage}"',
        );
      }

      _data = null;

      // Log unsuccessful AQI search with analytics
      await _analytics.logAqiSearch(zipcode, false);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Retries the last search
  Future<void> retry() async {
    if (_lastZipcode != null) {
      await fetchData(_lastZipcode!);
    }
  }

  /// Clears the AQI data and resets the provider state
  void clearData() {
    _data = null;
    _error = null;
    _errorCategory = null;
    _loading = false;
    _isFromCache = false;
    _lastZipcode = null;
    notifyListeners();
  }

  /// Sets an error message manually
  /// Useful for external error handling like connectivity checks
  void setError(
    String errorMessage, {
    ErrorCategory category = ErrorCategory.unknown,
  }) {
    _error = errorMessage;
    _errorCategory = category;
    _loading = false;
    notifyListeners();
  }
}
