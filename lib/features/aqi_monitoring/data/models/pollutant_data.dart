import 'package:json_annotation/json_annotation.dart';
import 'package:bloomsafe/features/aqi_monitoring/data/models/aqi_category.dart';

part 'pollutant_data.g.dart';

/// Represents the pollution data for a specific parameter (e.g., PM2.5, O3, PM10)
@JsonSerializable(explicitToJson: true)
class PollutantData {

  /// Creates a new PollutantData with the given values
  /// Throws a [FormatException] if parameterName is not a valid pollutant type
  PollutantData({
    required this.parameterName,
    required this.aqi,
    required this.category,
  }) {
    if (!validParameterNames.contains(parameterName)) {
      throw FormatException('Unsupported pollutant type: $parameterName');
    }
  }

  /// Creates a PollutantData from a JSON object
  factory PollutantData.fromJson(Map<String, dynamic> json) {
    final parameterName = json['parameterName'] as String;

    // Validate parameter name
    if (!validParameterNames.contains(parameterName)) {
      throw FormatException('Unsupported pollutant type: $parameterName');
    }

    return _$PollutantDataFromJson(json);
  }
  /// Static set of valid parameter names
  static const Set<String> validParameterNames = {'PM2.5', 'O3', 'PM10'};

  /// The name of the parameter (e.g., PM2.5, O3, PM10)
  final String parameterName;

  /// The AQI value for the parameter
  final int aqi;

  /// The category information for the parameter
  final AQICategory category;

  /// Converts this PollutantData to a JSON object
  Map<String, dynamic> toJson() => _$PollutantDataToJson(this);

  /// Checks if this is PM2.5 data
  bool get isPM25 => parameterName == 'PM2.5';

  /// Checks if this is ozone (O3) data
  bool get isO3 => parameterName == 'O3';

  /// Checks if this is PM10 data
  bool get isPM10 => parameterName == 'PM10';

  @override
  String toString() => '$parameterName: AQI $aqi (${category.name})';
}
