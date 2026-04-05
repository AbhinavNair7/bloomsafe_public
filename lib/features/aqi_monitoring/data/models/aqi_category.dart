import 'package:json_annotation/json_annotation.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:flutter/material.dart';

part 'aqi_category.g.dart';

/// Represents an AQI category with a number (1-6) and a name
@JsonSerializable()
class AQICategory {

  /// Creates a new AQICategory with the given number and name
  /// Throws a [RangeError] if number is not between 1 and 6
  AQICategory({required this.number, required this.name}) {
    if (number < minCategoryNumber || number > maxCategoryNumber) {
      throw RangeError(
        'Category number must be between $minCategoryNumber and $maxCategoryNumber, got $number',
      );
    }
  }

  /// Creates an AQICategory from a JSON object
  factory AQICategory.fromJson(Map<String, dynamic> json) {
    final number = json['Number'] as int;
    if (number < minCategoryNumber || number > maxCategoryNumber) {
      throw RangeError(
        'Category number must be between $minCategoryNumber and $maxCategoryNumber, got $number',
      );
    }
    return _$AQICategoryFromJson(json);
  }
  /// The minimum valid category number (Good)
  static const int minCategoryNumber = 1;

  /// The maximum valid category number (Hazardous)
  static const int maxCategoryNumber = 6;

  /// The category number (1-6)
  @JsonKey(name: 'Number')
  final int number;

  /// The category name (Good, Moderate, etc.)
  @JsonKey(name: 'Name')
  final String name;

  /// Converts this AQICategory to a JSON object
  Map<String, dynamic> toJson() => _$AQICategoryToJson(this);

  /// Returns the color associated with this AQI category
  Color get color {
    switch (number) {
      case 1:
        return nurturingZoneColor; // Green (Good)
      case 2:
        return mindfulZoneColor; // Yellow (Moderate)
      case 3:
        return cautiousZoneColor; // Orange (Unhealthy for Sensitive Groups)
      case 4:
        return shieldZoneColor; // Red (Unhealthy)
      case 5:
        return shelterZoneColor; // Purple (Very Unhealthy)
      case 6:
        return protectionZoneColor; // Maroon (Hazardous)
      default:
        return Colors.grey; // Unknown
    }
  }

  @override
  String toString() => 'AQICategory $number: $name';
}
