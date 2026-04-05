// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pollutant_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PollutantData _$PollutantDataFromJson(Map<String, dynamic> json) =>
    PollutantData(
      parameterName: json['parameterName'] as String,
      aqi: (json['aqi'] as num).toInt(),
      category: AQICategory.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PollutantDataToJson(PollutantData instance) =>
    <String, dynamic>{
      'parameterName': instance.parameterName,
      'aqi': instance.aqi,
      'category': instance.category.toJson(),
    };
