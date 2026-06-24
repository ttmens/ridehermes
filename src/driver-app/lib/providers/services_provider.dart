import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/services/location_service.dart';
import 'package:ride_hermes_driver/services/ws_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final svc = LocationService();
  ref.onDispose(() => svc.stopLocationUpdates());
  return svc;
});

final wsServiceProvider = Provider<WSService>((ref) {
  final svc = WSService();
  ref.onDispose(() => svc.disconnect());
  return svc;
});
