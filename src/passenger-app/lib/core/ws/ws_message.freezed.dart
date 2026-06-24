// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ws_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WsMessage _$WsMessageFromJson(Map<String, dynamic> json) {
  return _WsMessage.fromJson(json);
}

/// @nodoc
mixin _$WsMessage {
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;

  /// Serializes this WsMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WsMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WsMessageCopyWith<WsMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WsMessageCopyWith<$Res> {
  factory $WsMessageCopyWith(WsMessage value, $Res Function(WsMessage) then) =
      _$WsMessageCopyWithImpl<$Res, WsMessage>;
  @useResult
  $Res call({String type, Map<String, dynamic> data});
}

/// @nodoc
class _$WsMessageCopyWithImpl<$Res, $Val extends WsMessage>
    implements $WsMessageCopyWith<$Res> {
  _$WsMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WsMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WsMessageImplCopyWith<$Res>
    implements $WsMessageCopyWith<$Res> {
  factory _$$WsMessageImplCopyWith(
          _$WsMessageImpl value, $Res Function(_$WsMessageImpl) then) =
      __$$WsMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String type, Map<String, dynamic> data});
}

/// @nodoc
class __$$WsMessageImplCopyWithImpl<$Res>
    extends _$WsMessageCopyWithImpl<$Res, _$WsMessageImpl>
    implements _$$WsMessageImplCopyWith<$Res> {
  __$$WsMessageImplCopyWithImpl(
      _$WsMessageImpl _value, $Res Function(_$WsMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of WsMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? data = null,
  }) {
    return _then(_$WsMessageImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WsMessageImpl implements _WsMessage {
  const _$WsMessageImpl(
      {required this.type, required final Map<String, dynamic> data})
      : _data = data;

  factory _$WsMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$WsMessageImplFromJson(json);

  @override
  final String type;
  final Map<String, dynamic> _data;
  @override
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  String toString() {
    return 'WsMessage(type: $type, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WsMessageImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, const DeepCollectionEquality().hash(_data));

  /// Create a copy of WsMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WsMessageImplCopyWith<_$WsMessageImpl> get copyWith =>
      __$$WsMessageImplCopyWithImpl<_$WsMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WsMessageImplToJson(
      this,
    );
  }
}

abstract class _WsMessage implements WsMessage {
  const factory _WsMessage(
      {required final String type,
      required final Map<String, dynamic> data}) = _$WsMessageImpl;

  factory _WsMessage.fromJson(Map<String, dynamic> json) =
      _$WsMessageImpl.fromJson;

  @override
  String get type;
  @override
  Map<String, dynamic> get data;

  /// Create a copy of WsMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WsMessageImplCopyWith<_$WsMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
