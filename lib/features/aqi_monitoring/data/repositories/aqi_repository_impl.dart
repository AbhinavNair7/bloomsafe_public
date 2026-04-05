import 'dart:async';
import 'package:bloomsafe/core/config/app_config.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/error/error_reporter.dart';
import 'package:bloomsafe/core/network/exceptions/api_exceptions.dart'
    hide AQIException, InvalidZipcodeException;
import 'package:bloomsafe/features/aqi_monitoring/data/cache/aqi_cache_service.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/network/mock_aqi_client.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/transformers/aqi_data_transformer.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/repositories/aqi_repository.dart';
import 'package:bloomsafe/features/aqi_monitoring/domain/utils/validation_utils.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Implementation of the AQI Repository that handles data fetching, caching and validation
///
/// This class is responsible for:
/// - Fetching AQI data from the API or mock data source
/// - Caching results with proper expiration handling
/// - Validating zip codes and managing data freshness
/// - Transforming raw API data to domain models
class AQIRepositoryImpl implements AQIRepository {

  /// Creates a new AQIRepositoryImpl with the given dependencies
  AQIRepositoryImpl(
    this._aqiClient, {
    required MockAQIClient mockAqiClient,
    required AQICacheService cacheService,
    required AQIDataTransformer transformer,
    required AppConfig appConfig,
  }) : _mockAqiClient = mockAqiClient,
       _cacheService = cacheService,
       _transformer = transformer,
       _appConfig = appConfig;
  /// The AQI-specific client used for making network requests
  final AQIClient _aqiClient;

  /// Mock AQI client for development/testing
  final MockAQIClient _mockAqiClient;

  /// Cache service for AQI data
  final AQICacheService _cacheService;

  /// Data transformer for API responses
  final AQIDataTransformer _transformer;

  /// App configuration for toggle between mock and real API
  final AppConfig _appConfig;

  /// Tracks whether the last retrieved data was from cache
  bool _lastDataFromCache = false;

  /// Tracks when items were added to cache
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Maximum age for fallback data (24 hours)
  static const Duration maxFallbackAge = Duration(hours: 24);

  /// Fetches AQI data for the specified zip code
  ///
  /// Will attempt to get data from cache first, then fall back to API if needed.
  /// Data is cached with proper timezone handling for expiration.
  @override
  Future<AQIData> getAQIByZipcode(String zipcode) async {
    // Validate zip code format
    final errorMessage = AQIValidationUtils.validateZipCode(zipcode);
    if (errorMessage != null) {
      throw InvalidZipcodeException(errorMessage);
    }

    try {
      // Check cache first
      final cachedData = await _cacheService.getForZipCode(zipcode);
      if (cachedData != null) {
        Logger.debug('📦 Using cached data for zipcode: $zipcode');
        _lastDataFromCache = true;

        // If we don't have a timestamp for this zipcode, create one now
        if (!_cacheTimestamps.containsKey(zipcode)) {
          _cacheTimestamps[zipcode] = DateTime.now().subtract(
            const Duration(minutes: 5),
          );
        }

        return cachedData;
      }

      // For API calls, set lastDataFromCache to false
      _lastDataFromCache = false;

      // Check if we're rate limited and should avoid API calls
      if (!_appConfig.useMockApi) {
        final shouldUseOnlyCache = await _aqiClient.shouldUseCacheOnly();
        if (shouldUseOnlyCache) {
          // No fallback to stale data - if cache is empty or expired, throw exception
          throw RateLimitExceededException(maxSearchesReachedMessage);
        }
      }

      // Fetch from API (or mock if configured)
      final rawData =
          _appConfig.useMockApi
              ? await _mockAqiClient.getAirQualityByZipCode(zipcode, 'json', 25)
              : await _aqiClient.getAirQualityByZipCode(zipcode, 'json', 25);

      // Transform raw data to domain model
      final aqiData = _transformer.transformApiResponse(rawData, zipcode);

      // Cache the result
      await _cacheService.storeForZipCode(zipcode, aqiData);
      _cacheTimestamps[zipcode] = DateTime.now();

      return aqiData;
    } catch (e) {
      // No special handling for rate limit exceptions - we won't use stale data
      // Just rethrow all exceptions
      if (e is ApiException) {
        // Report API exceptions to error monitoring service with context
        ErrorReporter.report(
          e,
          StackTrace.current,
          context: 'AQI API request for zipcode: $zipcode',
          extras: {
            'useMockApi': _appConfig.useMockApi.toString(),
            'errorType': 'ApiException',
          },
        );
        rethrow;
      }

      // For other errors, wrap in a general AQI exception
      Logger.error('🔴 Error fetching AQI data: ${e.toString()}');

      // Report to error monitoring with additional context
      ErrorReporter.report(
        e,
        StackTrace.current,
        context: 'AQI API request for zipcode: $zipcode',
        extras: {
          'useMockApi': _appConfig.useMockApi.toString(),
          'errorType': 'GeneralException',
          'errorMessage': e.toString(),
        },
      );

      throw AQIException('Failed to fetch AQI data: ${e.toString()}');
    }
  }

  /// Checks if data for a zip code is available in cache
  @override
  Future<bool> hasDataForZipCode(String zipCode) async {
    final data = await _cacheService.getForZipCode(zipCode);
    return data != null;
  }

  /// Gets cached data without making API requests
  ///
  /// Returns null if no valid cached data exists
  @override
  Future<AQIData?> getCachedDataForZipCode(String zipCode) async {
    return await _cacheService.getForZipCode(zipCode);
  }

  /// Clears all cached data
  @override
  Future<void> clearCache() async {
    await _cacheService.clear();
  }

  /// Returns whether the last retrieved data was from cache
  @override
  bool isFromCache() {
    return _lastDataFromCache;
  }

  /// Returns the age of the cached data for the given zipcode
  @override
  Duration getCacheAge(String zipCode) {
    if (!_cacheTimestamps.containsKey(zipCode)) {
      return Duration.zero;
    }

    return DateTime.now().difference(_cacheTimestamps[zipCode]!);
  }

  /// Disposes of resources
  void dispose() {
    _cacheService.dispose();
  }
}

