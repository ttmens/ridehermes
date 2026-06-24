import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ride_hermes_passenger/config/app_config.dart';
import 'package:ride_hermes_passenger/core/storage/token_storage.dart';
import 'package:ride_hermes_passenger/core/ws/ws_reconnect.dart';
import 'package:ride_hermes_passenger/core/ws/ws_message.dart';

class WsClient {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  final _messageController = StreamController<WsMessage>.broadcast();
  final _reconnectStrategy = ExponentialBackoffReconnect();

  bool _isConnected = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  Stream<WsMessage> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  WsClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  Future<void> connect() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return;

    final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      _reconnectStrategy.reset();
      _startHeartbeat();

      _channel!.stream.listen(
        (data) => _onMessage(data),
        onError: (_) => _onDisconnected(),
        onDone: () => _onDisconnected(),
      );
    } catch (_) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void send(WsMessage message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    }
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    double accuracy = 0,
    double speed = 0,
    double bearing = 0,
  }) {
    send(WsMessage(
      type: WsMessageType.locationUpdate,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
      },
    ));
  }

  void _onMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WsMessage.fromJson(json);
      _messageController.add(message);
    } catch (_) {}
  }

  void _onDisconnected() {
    _isConnected = false;
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      AppConfig.heartbeatInterval,
      (_) => send(WsMessage(type: WsMessageType.pong, data: {})),
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _reconnectStrategy.nextDelay();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () => connect());
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _channel?.sink.close();
    _isConnected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
