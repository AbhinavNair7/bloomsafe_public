// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aqi_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AQIData _$AQIDataFromJson(Map<String, dynamic> json) => AQIData(
  pollutants:
      (json['pollutants'] as List<dynamic>)
          .map((e) => PollutantData.fromJson(e as Map<String, dynamic>))
          .toList(),
  reportingArea: json['reportingArea'] as String?,
  stateCode: json['stateCode'] as String?,
  dateObserved: json['DateObserved'] as String,
  hourObserved: (json['HourObserved'] as num).toInt(),
  localTimeZone: json['localTimeZone'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AQIDataToJson(AQIData instance) => <String, dynamic>{
  'pollutants': instance.pollutants.map((e) => e.toJson()).toList(),
  'reportingArea': instance.reportingArea,
  'stateCode': instance.stateCode,
  'DateObserved': instance.dateObserved,
  'HourObserved': instance.hourObserved,
  'localTimeZone': instance.localTimeZone,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
