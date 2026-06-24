import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/config/app_config.dart';
import 'package:ride_hermes_driver/providers/auth_provider.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';
import 'package:ride_hermes_driver/providers/services_provider.dart';

/// Keeps WebSocket + GPS reporting alive while driver is online,
/// independent of DashboardScreen lifecycle (trip screen is outside ShellRoute).
class DriverTrackingController {
  final Ref _ref;
  Timer? _locationTimer;
  StreamSubscription? _locationSub;
  StreamSubscription? _wsSub;
  bool _running = false;

  DriverTrackingController(this._ref);

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    final token = _ref.read(authProvider).tokens?.accessToken;
    if (token == null) return;

    final ws = _ref.read(wsServiceProvider);
    await ws.connect(token);

    _wsSub = ws.messages.listen((msg) {
      if (msg.type == 'order_assigned') {
        _ref.read(driverOrderProvider.notifier).fetchOrders();
      }
    });

    final locSvc = _ref.read(locationServiceProvider);
    locSvc.startLocationUpdates();

    var lat = 0.0;
    var lng = 0.0;
    _locationSub = locSvc.locationStream.listen((pos) {
      lat = pos['latitude'] as double;
      lng = pos['longitude'] as double;
    });

    _locationTimer = Timer.periodic(AppConfig.locationInterval, (_) {
      if (lat != 0 || lng != 0) {
        ws.sendLocationUpdate(latitude: lat, longitude: lng);
      }
    });

    _running = true;
  }

  Future<void> stop() async {
    if (!_running) return;
    _locationTimer?.cancel();
    _locationTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
    _wsSub?.cancel();
    _wsSub = null;
    _ref.read(locationServiceProvider).stopLocationUpdates();
    _ref.read(wsServiceProvider).disconnect();
    _running = false;
  }
}

final driverTrackingProvider = Provider<DriverTrackingController>((ref) {
  final controller = DriverTrackingController(ref);
  ref.onDispose(() => controller.stop());
  return controller;
});
