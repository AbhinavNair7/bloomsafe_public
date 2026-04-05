// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AQICategory _$AQICategoryFromJson(Map<String, dynamic> json) => AQICategory(
  number: (json['Number'] as num).toInt(),
  name: json['Name'] as String,
);

Map<String, dynamic> _$AQICategoryToJson(AQICategory instance) =>
    <String, dynamic>{'Number': instance.number, 'Name': instance.name};
