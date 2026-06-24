// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ws_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WsMessageImpl _$$WsMessageImplFromJson(Map<String, dynamic> json) =>
    _$WsMessageImpl(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$WsMessageImplToJson(_$WsMessageImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'data': instance.data,
    };
