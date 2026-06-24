import 'package:freezed_annotation/freezed_annotation.dart';

part 'ws_message.freezed.dart';
part 'ws_message.g.dart';

@freezed
class WsMessage with _$WsMessage {
  const factory WsMessage({
    required String type,
    required Map<String, dynamic> data,
  }) = _WsMessage;

  factory WsMessage.fromJson(Map<String, dynamic> json) =>
      _$WsMessageFromJson(json);
}

class WsMessageType {
  static const locationUpdate = 'location_update';
  static const orderAssigned = 'order_assigned';
  static const driverLocation = 'driver_location';
  static const orderStatus = 'order_status';
  static const error = 'error';
  static const pong = 'pong';
}
