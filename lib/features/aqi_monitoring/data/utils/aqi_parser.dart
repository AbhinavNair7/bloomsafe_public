import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart'
    as tzm;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';

/// Exception thrown when there's an error parsing AQI data
class ParserException implements Exception {

  ParserException(this.message);
  final String message;

  @override
  String toString() => 'ParserException: $message';
}

/// Utility class for parsing and extracting information from AQI API responses
class AQIParser {
  /// Maximum age in hours for data to be considered "fresh"
  static const int maxDataAgeHours = 1;

  /// Parses the raw API response and converts it to an AQIData object
  ///
  /// Throws [ParserException] if the response is invalid
  AQIData parseResponse(List<dynamic> response) {
    try {
      // Validate the response
      _validateResponse(response);

      // Cast the raw response to the expected format
      final List<Map<String, dynamic>> typedResponse =
          response
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

      // Use the model's factory to create an AQIData object
      return AQIData.fromApiResponse(typedResponse);
    } catch (e) {
      if (e is ParserException) {
        rethrow;
      }
      throw ParserException('Failed to parse API response: ${e.toString()}');
    }
  }

  /// Extracts PM2.5 data from a raw API response
  ///
  /// Returns null if no PM2.5 data is found
  Map<String, dynamic>? extractPM25(List<dynamic> response) {
    try {
      // Validate the response
      _validateResponse(response);

      // Find the first entry with ParameterName = "PM2.5"
      for (final item in response) {
        final Map<String, dynamic> typedItem = Map<String, dynamic>.from(
          item as Map,
        );
        if (typedItem['ParameterName'] == 'PM2.5') {
          return typedItem;
        }
      }

      // No PM2.5 data found
      return null;
    } catch (e) {
      // Return null on error
      return null;
    }
  }

  /// Creates a timezone-aware DateTime from AirNow API observation data
  ///
  /// Parameters:
  /// - [item]: API response item with DateObserved, HourObserved and LocalTimeZone
  ///
  /// Returns a TZDateTime object in the local timezone from the API response,
  /// properly handling DST transitions and timezone conversions
  tz.TZDateTime createObservationDateTime(Map<String, dynamic> item) {
    final String dateObserved = item['DateObserved'] as String;
    final int hourObserved = item['HourObserved'] as int;
    final String? localTimeZone = item['LocalTimeZone'] as String?;

    return tzm.createObservationDateTime(
      dateObserved: dateObserved,
      hourObserved: hourObserved,
      localTimeZone: localTimeZone,
    );
  }

  /// Calculates the expiry time for AQI data (2 hours after observation)
  ///
  /// Parameters:
  /// - [observationTime]: The observation time as a TZDateTime object
  ///
  /// Returns a TZDateTime representing when the data should expire
  tz.TZDateTime calculateValidUntil(tz.TZDateTime observationTime) {
    return TimeValidator.calculateExpiryTime(observationTime);
  }

  /// Checks if data is considered fresh (observed within last hour)
  bool isDataFresh(tz.TZDateTime observationTime) {
    return TimeValidator.isFresh(
      observationTime,
      freshnessThresholdHours: maxDataAgeHours,
    );
  }

  /// Validates the API response structure
  ///
  /// Throws [ParserException] if the response is invalid
  void _validateResponse(List<dynamic> response) {
    if (response.isEmpty) {
      throw ParserException('Empty API response');
    }

    // Check if the first item has the expected fields
    try {
      final firstItem = response.first as Map;

      // Check for required fields
      if (!firstItem.containsKey('DateObserved') ||
          !firstItem.containsKey('HourObserved') ||
          !firstItem.containsKey('ParameterName') ||
          !firstItem.containsKey('AQI') ||
          !firstItem.containsKey('Category')) {
        throw ParserException('Missing required fields in API response');
      }
    } catch (e) {
      throw ParserException('Invalid API response format: ${e.toString()}');
    }
  }
}

/// Extension on AQIData to add freshness checking
extension AQIDataFreshness on AQIData {
  /// Returns true if the data is fresh (observed within the last hour)
  bool get isFresh => AQIParser().isDataFresh(observationTime);
}
