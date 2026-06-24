import 'package:freezed_annotation/freezed_annotation.dart';

part 'location.freezed.dart';
part 'location.g.dart';

@freezed
class LocationInfo with _$LocationInfo {
  const factory LocationInfo({
    required double lat,
    required double lng,
    @Default(0) double accuracy,
    @Default(0) double speed,
    @Default(0) double bearing,
  }) = _LocationInfo;

  factory LocationInfo.fromJson(Map<String, dynamic> json) =>
      _$LocationInfoFromJson(json);
}
