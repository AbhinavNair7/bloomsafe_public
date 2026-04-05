import 'package:flutter/foundation.dart';
import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/core/utils/logger.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';

/// Transforms raw API data into domain models for the AQI feature
class AQIDataTransformer {
  /// Transforms API response data into an AQIData model
  ///
  /// Throws [AQIException] if the response data cannot be properly transformed
  AQIData transformApiResponse(List<dynamic> responseData, String zipcode) {
    // Check if response is empty
    if (responseData.isEmpty) {
      throw AQIException(apiConnectionErrorMessage);
    }

    // Parse response into AQIData model
    AQIData aqiData;
    try {
      aqiData = AQIData.fromApiResponse(
        List<Map<String, dynamic>>.from(responseData),
      );
    } catch (e) {
      // Convert any errors (including ArgumentError) to our standard API connection error
      Logger.error('🔴 Error creating AQIData from response: ${e.toString()}');
      throw AQIException(apiConnectionErrorMessage);
    }

    // Make sure we have at least one pollutant
    if (aqiData.pollutants.isEmpty) {
      throw AQIException(apiConnectionErrorMessage);
    }

    // Check if PM2.5 data is available
    final pm25Data = aqiData.getPM25();
    if (pm25Data == null) {
      Logger.error('🔴 No PM2.5 data available for zipcode: $zipcode');
      throw AQIException(apiConnectionErrorMessage);
    }

    // Log success
    Logger.info(
      '✅ Successfully transformed API data for $zipcode: '
      'AQI=${pm25Data.aqi}, Category=${pm25Data.category.name}, Type=${pm25Data.parameterName}',
    );

    // Check data freshness
    logDataFreshness(aqiData);

    return aqiData;
  }

  /// Logs information about how fresh the data is
  void logDataFreshness(AQIData data) {
    final age = TimeValidator.dataAge(data.observationTime);
    final hoursSinceObservation = age.inHours;

    if (hoursSinceObservation > 3) {
      Logger.info(
        'ℹ️ Data is relatively old (${hoursSinceObservation}h since observation)',
      );
    }

    // Log detailed validity metrics if in debug mode
    if (kDebugMode) {
      data.logValidityInfo();
    }
  }

  /// Validates if AQIData is still valid based on its observation time and valid until time
  bool isDataValid(AQIData data) {
    return TimeValidator.isValid(data.observationTime, data.validUntil);
  }

  /// Checks if data is fresh enough (observed within the last hour)
  bool isDataFresh(AQIData data) {
    return TimeValidator.isFresh(data.observationTime);
  }

  /// Checks if data can be used as a fallback even though it's expired
  bool isUsableAsFallback(AQIData data, {required Duration maxAge}) {
    return TimeValidator.isUsableAsFallback(
      data.observationTime,
      data.validUntil,
      maxFallbackAge: maxAge,
    );
  }
}
