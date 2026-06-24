import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_chat.freezed.dart';
part 'ai_chat.g.dart';

@freezed
class AIChatRequest with _$AIChatRequest {
  const factory AIChatRequest({
    String? text,
    @JsonKey(name: 'audio_base64') String? audioBase64,
    @JsonKey(name: 'session_id') @Default('') String sessionId,
  }) = _AIChatRequest;

  factory AIChatRequest.fromJson(Map<String, dynamic> json) =>
      _$AIChatRequestFromJson(json);
}

@freezed
class AIChatResponse with _$AIChatResponse {
  const factory AIChatResponse({
    @JsonKey(name: 'session_id') required String sessionId,
    @JsonKey(name: 'response_text') required String responseText,
    RideIntent? intent,
    @JsonKey(name: 'asr_text') String? asrText,
    @JsonKey(name: 'order_preview') OrderPreview? orderPreview,
    @Default(false) bool fallback,
  }) = _AIChatResponse;

  factory AIChatResponse.fromJson(Map<String, dynamic> json) =>
      _$AIChatResponseFromJson(json);
}

@freezed
class RideIntent with _$RideIntent {
  const factory RideIntent({
    @JsonKey(name: 'intent_type') required String intentType,
    AddressInfo? pickup,
    AddressInfo? dropoff,
    @JsonKey(name: 'car_type') int? carType,
    @JsonKey(name: 'missing_fields') @Default([]) List<String> missingFields,
    @JsonKey(name: 'departure_time') String? departureTime,
    @JsonKey(name: 'departure_desc') String? departureDesc,
  }) = _RideIntent;

  factory RideIntent.fromJson(Map<String, dynamic> json) =>
      _$RideIntentFromJson(json);
}

@freezed
class AddressInfo with _$AddressInfo {
  const factory AddressInfo({
    required String address,
    double? lat,
    double? lng,
    @Default(false) bool resolved,
  }) = _AddressInfo;

  factory AddressInfo.fromJson(Map<String, dynamic> json) =>
      _$AddressInfoFromJson(json);
}

@freezed
class OrderPreview with _$OrderPreview {
  const factory OrderPreview({
    @JsonKey(name: 'est_price') @Default(0) double estPrice,
    @JsonKey(name: 'est_distance') @Default(0) int estDistance,
    @JsonKey(name: 'est_duration') @Default(0) int estDuration,
    @JsonKey(name: 'car_type') @Default(1) int carType,
  }) = _OrderPreview;

  factory OrderPreview.fromJson(Map<String, dynamic> json) =>
      _$OrderPreviewFromJson(json);
}
