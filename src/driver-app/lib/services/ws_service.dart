import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ride_hermes_driver/config/app_config.dart';

class WSMessage {
  final String type;
  final Map<String, dynamic> data;

  WSMessage({required this.type, required this.data});

  factory WSMessage.fromJson(Map<String, dynamic> json) {
    return WSMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }
}

class WSService {
  WebSocketChannel? _channel;
  final StreamController<WSMessage> _messageController =
      StreamController<WSMessage>.broadcast();
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  Stream<WSMessage> get messages => _messageController.stream;

  Future<void> connect(String token) async {
    final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _startHeartbeat();

    _channel!.stream.listen(
      (data) {
        final json = jsonDecode(data as String);
        _messageController.add(WSMessage.fromJson(json));
      },
      onError: (_) => _scheduleReconnect(token),
      onDone: () => _scheduleReconnect(token),
    );
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    double accuracy = 0,
    double speed = 0,
    double bearing = 0,
  }) {
    _send({
      'type': 'location_update',
      'data': {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
      },
    });
  }

  void _send(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      AppConfig.heartbeatInterval,
      (_) => _send({'type': 'heartbeat'}),
    );
  }

  void _scheduleReconnect(String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () => connect(token));
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}
