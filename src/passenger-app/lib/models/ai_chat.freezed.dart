// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_chat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AIChatRequest _$AIChatRequestFromJson(Map<String, dynamic> json) {
  return _AIChatRequest.fromJson(json);
}

/// @nodoc
mixin _$AIChatRequest {
  String? get text => throw _privateConstructorUsedError;
  @JsonKey(name: 'audio_base64')
  String? get audioBase64 => throw _privateConstructorUsedError;
  @JsonKey(name: 'session_id')
  String get sessionId => throw _privateConstructorUsedError;

  /// Serializes this AIChatRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIChatRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIChatRequestCopyWith<AIChatRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIChatRequestCopyWith<$Res> {
  factory $AIChatRequestCopyWith(
          AIChatRequest value, $Res Function(AIChatRequest) then) =
      _$AIChatRequestCopyWithImpl<$Res, AIChatRequest>;
  @useResult
  $Res call(
      {String? text,
      @JsonKey(name: 'audio_base64') String? audioBase64,
      @JsonKey(name: 'session_id') String sessionId});
}

/// @nodoc
class _$AIChatRequestCopyWithImpl<$Res, $Val extends AIChatRequest>
    implements $AIChatRequestCopyWith<$Res> {
  _$AIChatRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIChatRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = freezed,
    Object? audioBase64 = freezed,
    Object? sessionId = null,
  }) {
    return _then(_value.copyWith(
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      audioBase64: freezed == audioBase64
          ? _value.audioBase64
          : audioBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AIChatRequestImplCopyWith<$Res>
    implements $AIChatRequestCopyWith<$Res> {
  factory _$$AIChatRequestImplCopyWith(
          _$AIChatRequestImpl value, $Res Function(_$AIChatRequestImpl) then) =
      __$$AIChatRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? text,
      @JsonKey(name: 'audio_base64') String? audioBase64,
      @JsonKey(name: 'session_id') String sessionId});
}

/// @nodoc
class __$$AIChatRequestImplCopyWithImpl<$Res>
    extends _$AIChatRequestCopyWithImpl<$Res, _$AIChatRequestImpl>
    implements _$$AIChatRequestImplCopyWith<$Res> {
  __$$AIChatRequestImplCopyWithImpl(
      _$AIChatRequestImpl _value, $Res Function(_$AIChatRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIChatRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = freezed,
    Object? audioBase64 = freezed,
    Object? sessionId = null,
  }) {
    return _then(_$AIChatRequestImpl(
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      audioBase64: freezed == audioBase64
          ? _value.audioBase64
          : audioBase64 // ignore: cast_nullable_to_non_nullable
              as String?,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIChatRequestImpl implements _AIChatRequest {
  const _$AIChatRequestImpl(
      {this.text,
      @JsonKey(name: 'audio_base64') this.audioBase64,
      @JsonKey(name: 'session_id') this.sessionId = ''});

  factory _$AIChatRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIChatRequestImplFromJson(json);

  @override
  final String? text;
  @override
  @JsonKey(name: 'audio_base64')
  final String? audioBase64;
  @override
  @JsonKey(name: 'session_id')
  final String sessionId;

  @override
  String toString() {
    return 'AIChatRequest(text: $text, audioBase64: $audioBase64, sessionId: $sessionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIChatRequestImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.audioBase64, audioBase64) ||
                other.audioBase64 == audioBase64) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, audioBase64, sessionId);

  /// Create a copy of AIChatRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIChatRequestImplCopyWith<_$AIChatRequestImpl> get copyWith =>
      __$$AIChatRequestImplCopyWithImpl<_$AIChatRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIChatRequestImplToJson(
      this,
    );
  }
}

abstract class _AIChatRequest implements AIChatRequest {
  const factory _AIChatRequest(
          {final String? text,
          @JsonKey(name: 'audio_base64') final String? audioBase64,
          @JsonKey(name: 'session_id') final String sessionId}) =
      _$AIChatRequestImpl;

  factory _AIChatRequest.fromJson(Map<String, dynamic> json) =
      _$AIChatRequestImpl.fromJson;

  @override
  String? get text;
  @override
  @JsonKey(name: 'audio_base64')
  String? get audioBase64;
  @override
  @JsonKey(name: 'session_id')
  String get sessionId;

  /// Create a copy of AIChatRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIChatRequestImplCopyWith<_$AIChatRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AIChatResponse _$AIChatResponseFromJson(Map<String, dynamic> json) {
  return _AIChatResponse.fromJson(json);
}

/// @nodoc
mixin _$AIChatResponse {
  @JsonKey(name: 'session_id')
  String get sessionId => throw _privateConstructorUsedError;
  @JsonKey(name: 'response_text')
  String get responseText => throw _privateConstructorUsedError;
  RideIntent? get intent => throw _privateConstructorUsedError;
  @JsonKey(name: 'asr_text')
  String? get asrText => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_preview')
  OrderPreview? get orderPreview => throw _privateConstructorUsedError;
  bool get fallback => throw _privateConstructorUsedError;

  /// Serializes this AIChatResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIChatResponseCopyWith<AIChatResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIChatResponseCopyWith<$Res> {
  factory $AIChatResponseCopyWith(
          AIChatResponse value, $Res Function(AIChatResponse) then) =
      _$AIChatResponseCopyWithImpl<$Res, AIChatResponse>;
  @useResult
  $Res call(
      {@JsonKey(name: 'session_id') String sessionId,
      @JsonKey(name: 'response_text') String responseText,
      RideIntent? intent,
      @JsonKey(name: 'asr_text') String? asrText,
      @JsonKey(name: 'order_preview') OrderPreview? orderPreview,
      bool fallback});

  $RideIntentCopyWith<$Res>? get intent;
  $OrderPreviewCopyWith<$Res>? get orderPreview;
}

/// @nodoc
class _$AIChatResponseCopyWithImpl<$Res, $Val extends AIChatResponse>
    implements $AIChatResponseCopyWith<$Res> {
  _$AIChatResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? responseText = null,
    Object? intent = freezed,
    Object? asrText = freezed,
    Object? orderPreview = freezed,
    Object? fallback = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      responseText: null == responseText
          ? _value.responseText
          : responseText // ignore: cast_nullable_to_non_nullable
              as String,
      intent: freezed == intent
          ? _value.intent
          : intent // ignore: cast_nullable_to_non_nullable
              as RideIntent?,
      asrText: freezed == asrText
          ? _value.asrText
          : asrText // ignore: cast_nullable_to_non_nullable
              as String?,
      orderPreview: freezed == orderPreview
          ? _value.orderPreview
          : orderPreview // ignore: cast_nullable_to_non_nullable
              as OrderPreview?,
      fallback: null == fallback
          ? _value.fallback
          : fallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RideIntentCopyWith<$Res>? get intent {
    if (_value.intent == null) {
      return null;
    }

    return $RideIntentCopyWith<$Res>(_value.intent!, (value) {
      return _then(_value.copyWith(intent: value) as $Val);
    });
  }

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OrderPreviewCopyWith<$Res>? get orderPreview {
    if (_value.orderPreview == null) {
      return null;
    }

    return $OrderPreviewCopyWith<$Res>(_value.orderPreview!, (value) {
      return _then(_value.copyWith(orderPreview: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AIChatResponseImplCopyWith<$Res>
    implements $AIChatResponseCopyWith<$Res> {
  factory _$$AIChatResponseImplCopyWith(_$AIChatResponseImpl value,
          $Res Function(_$AIChatResponseImpl) then) =
      __$$AIChatResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'session_id') String sessionId,
      @JsonKey(name: 'response_text') String responseText,
      RideIntent? intent,
      @JsonKey(name: 'asr_text') String? asrText,
      @JsonKey(name: 'order_preview') OrderPreview? orderPreview,
      bool fallback});

  @override
  $RideIntentCopyWith<$Res>? get intent;
  @override
  $OrderPreviewCopyWith<$Res>? get orderPreview;
}

/// @nodoc
class __$$AIChatResponseImplCopyWithImpl<$Res>
    extends _$AIChatResponseCopyWithImpl<$Res, _$AIChatResponseImpl>
    implements _$$AIChatResponseImplCopyWith<$Res> {
  __$$AIChatResponseImplCopyWithImpl(
      _$AIChatResponseImpl _value, $Res Function(_$AIChatResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? responseText = null,
    Object? intent = freezed,
    Object? asrText = freezed,
    Object? orderPreview = freezed,
    Object? fallback = null,
  }) {
    return _then(_$AIChatResponseImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      responseText: null == responseText
          ? _value.responseText
          : responseText // ignore: cast_nullable_to_non_nullable
              as String,
      intent: freezed == intent
          ? _value.intent
          : intent // ignore: cast_nullable_to_non_nullable
              as RideIntent?,
      asrText: freezed == asrText
          ? _value.asrText
          : asrText // ignore: cast_nullable_to_non_nullable
              as String?,
      orderPreview: freezed == orderPreview
          ? _value.orderPreview
          : orderPreview // ignore: cast_nullable_to_non_nullable
              as OrderPreview?,
      fallback: null == fallback
          ? _value.fallback
          : fallback // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIChatResponseImpl implements _AIChatResponse {
  const _$AIChatResponseImpl(
      {@JsonKey(name: 'session_id') required this.sessionId,
      @JsonKey(name: 'response_text') required this.responseText,
      this.intent,
      @JsonKey(name: 'asr_text') this.asrText,
      @JsonKey(name: 'order_preview') this.orderPreview,
      this.fallback = false});

  factory _$AIChatResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIChatResponseImplFromJson(json);

  @override
  @JsonKey(name: 'session_id')
  final String sessionId;
  @override
  @JsonKey(name: 'response_text')
  final String responseText;
  @override
  final RideIntent? intent;
  @override
  @JsonKey(name: 'asr_text')
  final String? asrText;
  @override
  @JsonKey(name: 'order_preview')
  final OrderPreview? orderPreview;
  @override
  @JsonKey()
  final bool fallback;

  @override
  String toString() {
    return 'AIChatResponse(sessionId: $sessionId, responseText: $responseText, intent: $intent, asrText: $asrText, orderPreview: $orderPreview, fallback: $fallback)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIChatResponseImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.responseText, responseText) ||
                other.responseText == responseText) &&
            (identical(other.intent, intent) || other.intent == intent) &&
            (identical(other.asrText, asrText) || other.asrText == asrText) &&
            (identical(other.orderPreview, orderPreview) ||
                other.orderPreview == orderPreview) &&
            (identical(other.fallback, fallback) ||
                other.fallback == fallback));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sessionId, responseText, intent,
      asrText, orderPreview, fallback);

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIChatResponseImplCopyWith<_$AIChatResponseImpl> get copyWith =>
      __$$AIChatResponseImplCopyWithImpl<_$AIChatResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIChatResponseImplToJson(
      this,
    );
  }
}

abstract class _AIChatResponse implements AIChatResponse {
  const factory _AIChatResponse(
      {@JsonKey(name: 'session_id') required final String sessionId,
      @JsonKey(name: 'response_text') required final String responseText,
      final RideIntent? intent,
      @JsonKey(name: 'asr_text') final String? asrText,
      @JsonKey(name: 'order_preview') final OrderPreview? orderPreview,
      final bool fallback}) = _$AIChatResponseImpl;

  factory _AIChatResponse.fromJson(Map<String, dynamic> json) =
      _$AIChatResponseImpl.fromJson;

  @override
  @JsonKey(name: 'session_id')
  String get sessionId;
  @override
  @JsonKey(name: 'response_text')
  String get responseText;
  @override
  RideIntent? get intent;
  @override
  @JsonKey(name: 'asr_text')
  String? get asrText;
  @override
  @JsonKey(name: 'order_preview')
  OrderPreview? get orderPreview;
  @override
  bool get fallback;

  /// Create a copy of AIChatResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIChatResponseImplCopyWith<_$AIChatResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RideIntent _$RideIntentFromJson(Map<String, dynamic> json) {
  return _RideIntent.fromJson(json);
}

/// @nodoc
mixin _$RideIntent {
  @JsonKey(name: 'intent_type')
  String get intentType => throw _privateConstructorUsedError;
  AddressInfo? get pickup => throw _privateConstructorUsedError;
  AddressInfo? get dropoff => throw _privateConstructorUsedError;
  @JsonKey(name: 'car_type')
  int? get carType => throw _privateConstructorUsedError;
  @JsonKey(name: 'missing_fields')
  List<String> get missingFields => throw _privateConstructorUsedError;
  @JsonKey(name: 'departure_time')
  String? get departureTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'departure_desc')
  String? get departureDesc => throw _privateConstructorUsedError;

  /// Serializes this RideIntent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RideIntentCopyWith<RideIntent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RideIntentCopyWith<$Res> {
  factory $RideIntentCopyWith(
          RideIntent value, $Res Function(RideIntent) then) =
      _$RideIntentCopyWithImpl<$Res, RideIntent>;
  @useResult
  $Res call(
      {@JsonKey(name: 'intent_type') String intentType,
      AddressInfo? pickup,
      AddressInfo? dropoff,
      @JsonKey(name: 'car_type') int? carType,
      @JsonKey(name: 'missing_fields') List<String> missingFields,
      @JsonKey(name: 'departure_time') String? departureTime,
      @JsonKey(name: 'departure_desc') String? departureDesc});

  $AddressInfoCopyWith<$Res>? get pickup;
  $AddressInfoCopyWith<$Res>? get dropoff;
}

/// @nodoc
class _$RideIntentCopyWithImpl<$Res, $Val extends RideIntent>
    implements $RideIntentCopyWith<$Res> {
  _$RideIntentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? intentType = null,
    Object? pickup = freezed,
    Object? dropoff = freezed,
    Object? carType = freezed,
    Object? missingFields = null,
    Object? departureTime = freezed,
    Object? departureDesc = freezed,
  }) {
    return _then(_value.copyWith(
      intentType: null == intentType
          ? _value.intentType
          : intentType // ignore: cast_nullable_to_non_nullable
              as String,
      pickup: freezed == pickup
          ? _value.pickup
          : pickup // ignore: cast_nullable_to_non_nullable
              as AddressInfo?,
      dropoff: freezed == dropoff
          ? _value.dropoff
          : dropoff // ignore: cast_nullable_to_non_nullable
              as AddressInfo?,
      carType: freezed == carType
          ? _value.carType
          : carType // ignore: cast_nullable_to_non_nullable
              as int?,
      missingFields: null == missingFields
          ? _value.missingFields
          : missingFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      departureTime: freezed == departureTime
          ? _value.departureTime
          : departureTime // ignore: cast_nullable_to_non_nullable
              as String?,
      departureDesc: freezed == departureDesc
          ? _value.departureDesc
          : departureDesc // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressInfoCopyWith<$Res>? get pickup {
    if (_value.pickup == null) {
      return null;
    }

    return $AddressInfoCopyWith<$Res>(_value.pickup!, (value) {
      return _then(_value.copyWith(pickup: value) as $Val);
    });
  }

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AddressInfoCopyWith<$Res>? get dropoff {
    if (_value.dropoff == null) {
      return null;
    }

    return $AddressInfoCopyWith<$Res>(_value.dropoff!, (value) {
      return _then(_value.copyWith(dropoff: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RideIntentImplCopyWith<$Res>
    implements $RideIntentCopyWith<$Res> {
  factory _$$RideIntentImplCopyWith(
          _$RideIntentImpl value, $Res Function(_$RideIntentImpl) then) =
      __$$RideIntentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'intent_type') String intentType,
      AddressInfo? pickup,
      AddressInfo? dropoff,
      @JsonKey(name: 'car_type') int? carType,
      @JsonKey(name: 'missing_fields') List<String> missingFields,
      @JsonKey(name: 'departure_time') String? departureTime,
      @JsonKey(name: 'departure_desc') String? departureDesc});

  @override
  $AddressInfoCopyWith<$Res>? get pickup;
  @override
  $AddressInfoCopyWith<$Res>? get dropoff;
}

/// @nodoc
class __$$RideIntentImplCopyWithImpl<$Res>
    extends _$RideIntentCopyWithImpl<$Res, _$RideIntentImpl>
    implements _$$RideIntentImplCopyWith<$Res> {
  __$$RideIntentImplCopyWithImpl(
      _$RideIntentImpl _value, $Res Function(_$RideIntentImpl) _then)
      : super(_value, _then);

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? intentType = null,
    Object? pickup = freezed,
    Object? dropoff = freezed,
    Object? carType = freezed,
    Object? missingFields = null,
    Object? departureTime = freezed,
    Object? departureDesc = freezed,
  }) {
    return _then(_$RideIntentImpl(
      intentType: null == intentType
          ? _value.intentType
          : intentType // ignore: cast_nullable_to_non_nullable
              as String,
      pickup: freezed == pickup
          ? _value.pickup
          : pickup // ignore: cast_nullable_to_non_nullable
              as AddressInfo?,
      dropoff: freezed == dropoff
          ? _value.dropoff
          : dropoff // ignore: cast_nullable_to_non_nullable
              as AddressInfo?,
      carType: freezed == carType
          ? _value.carType
          : carType // ignore: cast_nullable_to_non_nullable
              as int?,
      missingFields: null == missingFields
          ? _value._missingFields
          : missingFields // ignore: cast_nullable_to_non_nullable
              as List<String>,
      departureTime: freezed == departureTime
          ? _value.departureTime
          : departureTime // ignore: cast_nullable_to_non_nullable
              as String?,
      departureDesc: freezed == departureDesc
          ? _value.departureDesc
          : departureDesc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RideIntentImpl implements _RideIntent {
  const _$RideIntentImpl(
      {@JsonKey(name: 'intent_type') required this.intentType,
      this.pickup,
      this.dropoff,
      @JsonKey(name: 'car_type') this.carType,
      @JsonKey(name: 'missing_fields')
      final List<String> missingFields = const [],
      @JsonKey(name: 'departure_time') this.departureTime,
      @JsonKey(name: 'departure_desc') this.departureDesc})
      : _missingFields = missingFields;

  factory _$RideIntentImpl.fromJson(Map<String, dynamic> json) =>
      _$$RideIntentImplFromJson(json);

  @override
  @JsonKey(name: 'intent_type')
  final String intentType;
  @override
  final AddressInfo? pickup;
  @override
  final AddressInfo? dropoff;
  @override
  @JsonKey(name: 'car_type')
  final int? carType;
  final List<String> _missingFields;
  @override
  @JsonKey(name: 'missing_fields')
  List<String> get missingFields {
    if (_missingFields is EqualUnmodifiableListView) return _missingFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_missingFields);
  }

  @override
  @JsonKey(name: 'departure_time')
  final String? departureTime;
  @override
  @JsonKey(name: 'departure_desc')
  final String? departureDesc;

  @override
  String toString() {
    return 'RideIntent(intentType: $intentType, pickup: $pickup, dropoff: $dropoff, carType: $carType, missingFields: $missingFields, departureTime: $departureTime, departureDesc: $departureDesc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RideIntentImpl &&
            (identical(other.intentType, intentType) ||
                other.intentType == intentType) &&
            (identical(other.pickup, pickup) || other.pickup == pickup) &&
            (identical(other.dropoff, dropoff) || other.dropoff == dropoff) &&
            (identical(other.carType, carType) || other.carType == carType) &&
            const DeepCollectionEquality()
                .equals(other._missingFields, _missingFields) &&
            (identical(other.departureTime, departureTime) ||
                other.departureTime == departureTime) &&
            (identical(other.departureDesc, departureDesc) ||
                other.departureDesc == departureDesc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      intentType,
      pickup,
      dropoff,
      carType,
      const DeepCollectionEquality().hash(_missingFields),
      departureTime,
      departureDesc);

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RideIntentImplCopyWith<_$RideIntentImpl> get copyWith =>
      __$$RideIntentImplCopyWithImpl<_$RideIntentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RideIntentImplToJson(
      this,
    );
  }
}

abstract class _RideIntent implements RideIntent {
  const factory _RideIntent(
          {@JsonKey(name: 'intent_type') required final String intentType,
          final AddressInfo? pickup,
          final AddressInfo? dropoff,
          @JsonKey(name: 'car_type') final int? carType,
          @JsonKey(name: 'missing_fields') final List<String> missingFields,
          @JsonKey(name: 'departure_time') final String? departureTime,
          @JsonKey(name: 'departure_desc') final String? departureDesc}) =
      _$RideIntentImpl;

  factory _RideIntent.fromJson(Map<String, dynamic> json) =
      _$RideIntentImpl.fromJson;

  @override
  @JsonKey(name: 'intent_type')
  String get intentType;
  @override
  AddressInfo? get pickup;
  @override
  AddressInfo? get dropoff;
  @override
  @JsonKey(name: 'car_type')
  int? get carType;
  @override
  @JsonKey(name: 'missing_fields')
  List<String> get missingFields;
  @override
  @JsonKey(name: 'departure_time')
  String? get departureTime;
  @override
  @JsonKey(name: 'departure_desc')
  String? get departureDesc;

  /// Create a copy of RideIntent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RideIntentImplCopyWith<_$RideIntentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AddressInfo _$AddressInfoFromJson(Map<String, dynamic> json) {
  return _AddressInfo.fromJson(json);
}

/// @nodoc
mixin _$AddressInfo {
  String get address => throw _privateConstructorUsedError;
  double? get lat => throw _privateConstructorUsedError;
  double? get lng => throw _privateConstructorUsedError;
  bool get resolved => throw _privateConstructorUsedError;

  /// Serializes this AddressInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AddressInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddressInfoCopyWith<AddressInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddressInfoCopyWith<$Res> {
  factory $AddressInfoCopyWith(
          AddressInfo value, $Res Function(AddressInfo) then) =
      _$AddressInfoCopyWithImpl<$Res, AddressInfo>;
  @useResult
  $Res call({String address, double? lat, double? lng, bool resolved});
}

/// @nodoc
class _$AddressInfoCopyWithImpl<$Res, $Val extends AddressInfo>
    implements $AddressInfoCopyWith<$Res> {
  _$AddressInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddressInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? resolved = null,
  }) {
    return _then(_value.copyWith(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      resolved: null == resolved
          ? _value.resolved
          : resolved // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AddressInfoImplCopyWith<$Res>
    implements $AddressInfoCopyWith<$Res> {
  factory _$$AddressInfoImplCopyWith(
          _$AddressInfoImpl value, $Res Function(_$AddressInfoImpl) then) =
      __$$AddressInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String address, double? lat, double? lng, bool resolved});
}

/// @nodoc
class __$$AddressInfoImplCopyWithImpl<$Res>
    extends _$AddressInfoCopyWithImpl<$Res, _$AddressInfoImpl>
    implements _$$AddressInfoImplCopyWith<$Res> {
  __$$AddressInfoImplCopyWithImpl(
      _$AddressInfoImpl _value, $Res Function(_$AddressInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AddressInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? lat = freezed,
    Object? lng = freezed,
    Object? resolved = null,
  }) {
    return _then(_$AddressInfoImpl(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      lat: freezed == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double?,
      lng: freezed == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double?,
      resolved: null == resolved
          ? _value.resolved
          : resolved // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AddressInfoImpl implements _AddressInfo {
  const _$AddressInfoImpl(
      {required this.address, this.lat, this.lng, this.resolved = false});

  factory _$AddressInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AddressInfoImplFromJson(json);

  @override
  final String address;
  @override
  final double? lat;
  @override
  final double? lng;
  @override
  @JsonKey()
  final bool resolved;

  @override
  String toString() {
    return 'AddressInfo(address: $address, lat: $lat, lng: $lng, resolved: $resolved)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddressInfoImpl &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.resolved, resolved) ||
                other.resolved == resolved));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, address, lat, lng, resolved);

  /// Create a copy of AddressInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddressInfoImplCopyWith<_$AddressInfoImpl> get copyWith =>
      __$$AddressInfoImplCopyWithImpl<_$AddressInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AddressInfoImplToJson(
      this,
    );
  }
}

abstract class _AddressInfo implements AddressInfo {
  const factory _AddressInfo(
      {required final String address,
      final double? lat,
      final double? lng,
      final bool resolved}) = _$AddressInfoImpl;

  factory _AddressInfo.fromJson(Map<String, dynamic> json) =
      _$AddressInfoImpl.fromJson;

  @override
  String get address;
  @override
  double? get lat;
  @override
  double? get lng;
  @override
  bool get resolved;

  /// Create a copy of AddressInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddressInfoImplCopyWith<_$AddressInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderPreview _$OrderPreviewFromJson(Map<String, dynamic> json) {
  return _OrderPreview.fromJson(json);
}

/// @nodoc
mixin _$OrderPreview {
  @JsonKey(name: 'est_price')
  double get estPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'est_distance')
  int get estDistance => throw _privateConstructorUsedError;
  @JsonKey(name: 'est_duration')
  int get estDuration => throw _privateConstructorUsedError;
  @JsonKey(name: 'car_type')
  int get carType => throw _privateConstructorUsedError;

  /// Serializes this OrderPreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderPreviewCopyWith<OrderPreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderPreviewCopyWith<$Res> {
  factory $OrderPreviewCopyWith(
          OrderPreview value, $Res Function(OrderPreview) then) =
      _$OrderPreviewCopyWithImpl<$Res, OrderPreview>;
  @useResult
  $Res call(
      {@JsonKey(name: 'est_price') double estPrice,
      @JsonKey(name: 'est_distance') int estDistance,
      @JsonKey(name: 'est_duration') int estDuration,
      @JsonKey(name: 'car_type') int carType});
}

/// @nodoc
class _$OrderPreviewCopyWithImpl<$Res, $Val extends OrderPreview>
    implements $OrderPreviewCopyWith<$Res> {
  _$OrderPreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? estPrice = null,
    Object? estDistance = null,
    Object? estDuration = null,
    Object? carType = null,
  }) {
    return _then(_value.copyWith(
      estPrice: null == estPrice
          ? _value.estPrice
          : estPrice // ignore: cast_nullable_to_non_nullable
              as double,
      estDistance: null == estDistance
          ? _value.estDistance
          : estDistance // ignore: cast_nullable_to_non_nullable
              as int,
      estDuration: null == estDuration
          ? _value.estDuration
          : estDuration // ignore: cast_nullable_to_non_nullable
              as int,
      carType: null == carType
          ? _value.carType
          : carType // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderPreviewImplCopyWith<$Res>
    implements $OrderPreviewCopyWith<$Res> {
  factory _$$OrderPreviewImplCopyWith(
          _$OrderPreviewImpl value, $Res Function(_$OrderPreviewImpl) then) =
      __$$OrderPreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'est_price') double estPrice,
      @JsonKey(name: 'est_distance') int estDistance,
      @JsonKey(name: 'est_duration') int estDuration,
      @JsonKey(name: 'car_type') int carType});
}

/// @nodoc
class __$$OrderPreviewImplCopyWithImpl<$Res>
    extends _$OrderPreviewCopyWithImpl<$Res, _$OrderPreviewImpl>
    implements _$$OrderPreviewImplCopyWith<$Res> {
  __$$OrderPreviewImplCopyWithImpl(
      _$OrderPreviewImpl _value, $Res Function(_$OrderPreviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderPreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? estPrice = null,
    Object? estDistance = null,
    Object? estDuration = null,
    Object? carType = null,
  }) {
    return _then(_$OrderPreviewImpl(
      estPrice: null == estPrice
          ? _value.estPrice
          : estPrice // ignore: cast_nullable_to_non_nullable
              as double,
      estDistance: null == estDistance
          ? _value.estDistance
          : estDistance // ignore: cast_nullable_to_non_nullable
              as int,
      estDuration: null == estDuration
          ? _value.estDuration
          : estDuration // ignore: cast_nullable_to_non_nullable
              as int,
      carType: null == carType
          ? _value.carType
          : carType // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderPreviewImpl implements _OrderPreview {
  const _$OrderPreviewImpl(
      {@JsonKey(name: 'est_price') this.estPrice = 0,
      @JsonKey(name: 'est_distance') this.estDistance = 0,
      @JsonKey(name: 'est_duration') this.estDuration = 0,
      @JsonKey(name: 'car_type') this.carType = 1});

  factory _$OrderPreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderPreviewImplFromJson(json);

  @override
  @JsonKey(name: 'est_price')
  final double estPrice;
  @override
  @JsonKey(name: 'est_distance')
  final int estDistance;
  @override
  @JsonKey(name: 'est_duration')
  final int estDuration;
  @override
  @JsonKey(name: 'car_type')
  final int carType;

  @override
  String toString() {
    return 'OrderPreview(estPrice: $estPrice, estDistance: $estDistance, estDuration: $estDuration, carType: $carType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderPreviewImpl &&
            (identical(other.estPrice, estPrice) ||
                other.estPrice == estPrice) &&
            (identical(other.estDistance, estDistance) ||
                other.estDistance == estDistance) &&
            (identical(other.estDuration, estDuration) ||
                other.estDuration == estDuration) &&
            (identical(other.carType, carType) || other.carType == carType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, estPrice, estDistance, estDuration, carType);

  /// Create a copy of OrderPreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderPreviewImplCopyWith<_$OrderPreviewImpl> get copyWith =>
      __$$OrderPreviewImplCopyWithImpl<_$OrderPreviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderPreviewImplToJson(
      this,
    );
  }
}

abstract class _OrderPreview implements OrderPreview {
  const factory _OrderPreview(
      {@JsonKey(name: 'est_price') final double estPrice,
      @JsonKey(name: 'est_distance') final int estDistance,
      @JsonKey(name: 'est_duration') final int estDuration,
      @JsonKey(name: 'car_type') final int carType}) = _$OrderPreviewImpl;

  factory _OrderPreview.fromJson(Map<String, dynamic> json) =
      _$OrderPreviewImpl.fromJson;

  @override
  @JsonKey(name: 'est_price')
  double get estPrice;
  @override
  @JsonKey(name: 'est_distance')
  int get estDistance;
  @override
  @JsonKey(name: 'est_duration')
  int get estDuration;
  @override
  @JsonKey(name: 'car_type')
  int get carType;

  /// Create a copy of OrderPreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderPreviewImplCopyWith<_$OrderPreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
