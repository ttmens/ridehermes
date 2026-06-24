// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationInfoImpl _$$LocationInfoImplFromJson(Map<String, dynamic> json) =>
    _$LocationInfoImpl(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$$LocationInfoImplToJson(_$LocationInfoImpl instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy': instance.accuracy,
      'speed': instance.speed,
      'bearing': instance.bearing,
    };
