import 'package:json_annotation/json_annotation.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/pollutant_data.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_zone_mapper.dart'
    as tzm;
import 'package:bloomsafe/features/aqi_monitoring/data/utils/time_validator.dart';
import 'package:bloomsafe/core/utils/logger.dart';

part 'aqi_data.g.dart';

/// Represents the air quality data for a specific location and time
@JsonSerializable(explicitToJson: true)
class AQIData {

  /// Creates a new AQIData with the given values
  /// Only pollutants, dateObserved, and hourObserved are required
  AQIData({
    required this.pollutants,
    this.reportingArea,
    this.stateCode,
    required this.dateObserved,
    required this.hourObserved,
    this.localTimeZone,
    this.latitude,
    this.longitude,
  }) {
    // Initialize the timezone-aware observation time
    observationTime = tzm.createObservationDateTime(
      dateObserved: dateObserved,
      hourObserved: hourObserved,
      localTimeZone: localTimeZone,
    );

    // Calculate expiry time (2 hours after observation time)
    validUntil = TimeValidator.calculateExpiryTime(observationTime);
  }

  /// Creates an AQIData object from a list of API response items
  /// Each item in the response represents a different pollutant for the same location
  factory AQIData.fromApiResponse(List<Map<String, dynamic>> responseItems) {
    if (responseItems.isEmpty) {
      throw ArgumentError('API response is empty');
    }

    // Extract common location data from the first item
    final firstItem = responseItems.first;
    final reportingArea = firstItem['ReportingArea'] as String;
    final stateCode = firstItem['StateCode'] as String;
    final dateObserved = firstItem['DateObserved'] as String;
    final hourObserved = firstItem['HourObserved'] as int;
    final localTimeZone = firstItem['LocalTimeZone'] as String;
    final latitude = firstItem['Latitude'] as double;
    final longitude = firstItem['Longitude'] as double;

    // Create pollutant data for each item in the response
    final pollutants = <PollutantData>[];
    for (final item in responseItems) {
      try {
        pollutants.add(
          PollutantData(
            parameterName: item['ParameterName'] as String,
            aqi: item['AQI'] as int,
            category: AQICategory(
              number:
                  (item['Category'] as Map<String, dynamic>)['Number'] as int,
              name:
                  (item['Category'] as Map<String, dynamic>)['Name'] as String,
            ),
          ),
        );
      } catch (e) {
        // Skip invalid pollutants but log the error
        Logger.debug('Skipping invalid pollutant: ${e.toString()}');
      }
    }

    // Ensure we have at least one valid pollutant
    if (pollutants.isEmpty) {
      throw ArgumentError('No valid pollutants found in API response');
    }

    // Check if PM2.5 data is present
    final bool hasPM25 = pollutants.any((p) => p.isPM25);
    if (!hasPM25) {
      throw ArgumentError('No PM2.5 data found in API response');
    }

    return AQIData(
      pollutants: pollutants,
      reportingArea: reportingArea,
      stateCode: stateCode,
      dateObserved: dateObserved,
      hourObserved: hourObserved,
      localTimeZone: localTimeZone,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Creates an AQIData from a JSON object
  factory AQIData.fromJson(Map<String, dynamic> json) =>
      _$AQIDataFromJson(json);
  /// List of pollutant measurements (PM2.5, O3, PM10)
  final List<PollutantData> pollutants;

  /// The reporting area name (optional)
  final String? reportingArea;

  /// The state code (optional)
  final String? stateCode;

  /// The date of observation
  @JsonKey(name: 'DateObserved')
  final String dateObserved;

  /// The hour of observation
  @JsonKey(name: 'HourObserved')
  final int hourObserved;

  /// The local time zone (optional)
  final String? localTimeZone;

  /// The latitude of the measurement location (optional)
  final double? latitude;

  /// The longitude of the measurement location (optional)
  final double? longitude;

  /// Timezone-aware observation date and time
  @JsonKey(ignore: true)
  late final tz.TZDateTime observationTime;

  /// Timestamp when this data should be considered expired (2 hours after observation)
  @JsonKey(ignore: true)
  late final tz.TZDateTime validUntil;

  /// Converts this AQIData to a JSON object
  Map<String, dynamic> toJson() => _$AQIDataToJson(this);

  /// Gets the PM2.5 specific data
  /// Returns null if no PM2.5 data is available
  PollutantData? getPM25() {
    try {
      return pollutants.firstWhere((p) => p.isPM25);
    } catch (_) {
      return null;
    }
  }

  /// Gets the observation date and time as a DateTime object
  ///
  /// Note: This returns a standard DateTime (not timezone-aware).
  /// Use observationTime for timezone-aware operations.
  DateTime get observationDate {
    try {
      // First try ISO format with T separator (2025-03-24T12:00:00Z)
      if (dateObserved.contains('T')) {
        try {
          return DateTime.parse(dateObserved);
        } catch (e) {
          // If full parsing fails, extract just the date part
          final datePart = dateObserved.split('T')[0];
          final parts = datePart.split('-');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[0]), // year
              int.parse(parts[1]), // month
              int.parse(parts[2]), // day
              hourObserved,
            );
          }
        }
      }

      // Handle different date formats (MM/DD/YYYY or YYYY-MM-DD)
      if (dateObserved.contains('/')) {
        // Format: MM/DD/YYYY
        final parts = dateObserved.split('/');
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[0]), // month
          int.parse(parts[1]), // day
          hourObserved,
        );
      } else if (dateObserved.contains('-')) {
        // Format: YYYY-MM-DD
        final dateParts = dateObserved.split('-');
        return DateTime(
          int.parse(dateParts[0]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[2]), // day
          hourObserved,
        );
      }

      throw FormatException('Unsupported date format: $dateObserved');
    } catch (e) {
      // Log error and return current time as fallback
      Logger.debug(
        'Invalid date format: $dateObserved. Error: ${e.toString()}',
      );
      return DateTime.now();
    }
  }

  /// Checks if this AQI data has expired
  ///
  /// Uses the timezone-aware observations to determine if the data
  /// is still valid (within 2 hours of the observation time)
  bool isExpired() {
    return !TimeValidator.isValid(observationTime, validUntil);
  }

  /// Checks if this AQI data is fresh (observed within the last hour)
  bool isFresh() {
    return TimeValidator.isFresh(observationTime);
  }

  /// Logs the validity metrics for this AQI data (for debugging)
  void logValidityInfo() {
    TimeValidator.logValidityMetrics(
      observationTime,
      validUntil,
      label: 'AQI data for ${reportingArea ?? "unknown location"}',
    );
  }

  @override
  String toString() {
    final pm25 = getPM25();
    final pm25Info = pm25 != null ? 'PM2.5: ${pm25.aqi}' : 'No PM2.5 data';
    final location =
        reportingArea != null && stateCode != null
            ? '$reportingArea, $stateCode'
            : 'Unknown location';
    return '$location - $pm25Info';
  }
}
