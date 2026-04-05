import 'package:bloomsafe/core/constants/strings.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/exceptions/aqi_exceptions.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Utility class for parsing AirNow API responses
class AQIResponseParser {
  /// The parameter name for PM2.5 data in the API response
  static const String pm25ParameterName = 'PM2.5';

  /// Extracts PM2.5 AQI data from the AirNow API response
  /// Returns the PM2.5 AQI value and related data
  /// Throws AQIException if data cannot be retrieved for any reason
  static Map<String, dynamic> extractPM25Data(List<dynamic> responseData) {
    try {
      // Check if response is empty
      if (responseData.isEmpty) {
        // For empty responses, throw an AQIException with the standard message
        throw AQIException(apiConnectionErrorMessage);
      }

      // Find PM2.5 data in the response
      Map<String, dynamic>? pm25Data;
      try {
        pm25Data =
            responseData.firstWhere(
                  (item) => item['ParameterName'] == pm25ParameterName,
                )
                as Map<String, dynamic>;
      } catch (_) {
        // Item not found
        pm25Data = null;
      }

      // Check if PM2.5 data was found
      if (pm25Data == null) {
        // No PM2.5 data found, use the standard error message
        throw AQIException(apiConnectionErrorMessage);
      }

      // Check for extreme AQI values
      final aqi = pm25Data['AQI'];
      if (aqi is num) {
        // AQI range should typically be 0-500 in the standard EPA scale
        // Values above 500 are considered extreme/unusual
        // Very low negative values could also indicate unusual data
        if (aqi > 500 || aqi < 0) {
          throw AQIException(extremeAqiValuesMessage);
        }

        // Also check for weird fluctuations or unusual values
        if (aqi == 500 || (aqi > 450 && aqi < 500)) {
          Logger.warning(
            '⚠️ Unusual AQI value detected: $aqi (near maximum range)',
          );
          // Only log for borderline cases, still return the data
        }
      }

      return pm25Data;
    } catch (e) {
      // If it's already an AQIException, just rethrow it
      if (e is AQIException) {
        rethrow;
      }

      // Handle any parsing errors with the standard message
      throw AQIException(apiConnectionErrorMessage);
    }
  }
}
