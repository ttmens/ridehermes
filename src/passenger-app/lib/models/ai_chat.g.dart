// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIChatRequestImpl _$$AIChatRequestImplFromJson(Map<String, dynamic> json) =>
    _$AIChatRequestImpl(
      text: json['text'] as String?,
      audioBase64: json['audio_base64'] as String?,
      sessionId: json['session_id'] as String? ?? '',
    );

Map<String, dynamic> _$$AIChatRequestImplToJson(_$AIChatRequestImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'audio_base64': instance.audioBase64,
      'session_id': instance.sessionId,
    };

_$AIChatResponseImpl _$$AIChatResponseImplFromJson(Map<String, dynamic> json) =>
    _$AIChatResponseImpl(
      sessionId: json['session_id'] as String,
      responseText: json['response_text'] as String,
      intent: json['intent'] == null
          ? null
          : RideIntent.fromJson(json['intent'] as Map<String, dynamic>),
      asrText: json['asr_text'] as String?,
      orderPreview: json['order_preview'] == null
          ? null
          : OrderPreview.fromJson(
              json['order_preview'] as Map<String, dynamic>),
      fallback: json['fallback'] as bool? ?? false,
    );

Map<String, dynamic> _$$AIChatResponseImplToJson(
        _$AIChatResponseImpl instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'response_text': instance.responseText,
      'intent': instance.intent,
      'asr_text': instance.asrText,
      'order_preview': instance.orderPreview,
      'fallback': instance.fallback,
    };

_$RideIntentImpl _$$RideIntentImplFromJson(Map<String, dynamic> json) =>
    _$RideIntentImpl(
      intentType: json['intent_type'] as String,
      pickup: json['pickup'] == null
          ? null
          : AddressInfo.fromJson(json['pickup'] as Map<String, dynamic>),
      dropoff: json['dropoff'] == null
          ? null
          : AddressInfo.fromJson(json['dropoff'] as Map<String, dynamic>),
      carType: (json['car_type'] as num?)?.toInt(),
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      departureTime: json['departure_time'] as String?,
      departureDesc: json['departure_desc'] as String?,
    );

Map<String, dynamic> _$$RideIntentImplToJson(_$RideIntentImpl instance) =>
    <String, dynamic>{
      'intent_type': instance.intentType,
      'pickup': instance.pickup,
      'dropoff': instance.dropoff,
      'car_type': instance.carType,
      'missing_fields': instance.missingFields,
      'departure_time': instance.departureTime,
      'departure_desc': instance.departureDesc,
    };

_$AddressInfoImpl _$$AddressInfoImplFromJson(Map<String, dynamic> json) =>
    _$AddressInfoImpl(
      address: json['address'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      resolved: json['resolved'] as bool? ?? false,
    );

Map<String, dynamic> _$$AddressInfoImplToJson(_$AddressInfoImpl instance) =>
    <String, dynamic>{
      'address': instance.address,
      'lat': instance.lat,
      'lng': instance.lng,
      'resolved': instance.resolved,
    };

_$OrderPreviewImpl _$$OrderPreviewImplFromJson(Map<String, dynamic> json) =>
    _$OrderPreviewImpl(
      estPrice: (json['est_price'] as num?)?.toDouble() ?? 0,
      estDistance: (json['est_distance'] as num?)?.toInt() ?? 0,
      estDuration: (json['est_duration'] as num?)?.toInt() ?? 0,
      carType: (json['car_type'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$OrderPreviewImplToJson(_$OrderPreviewImpl instance) =>
    <String, dynamic>{
      'est_price': instance.estPrice,
      'est_distance': instance.estDistance,
      'est_duration': instance.estDuration,
      'car_type': instance.carType,
    };
