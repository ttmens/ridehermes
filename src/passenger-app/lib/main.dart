import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/app.dart';
import 'package:ride_hermes_passenger/core/location/location_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocationService.init();
  runApp(const ProviderScope(child: RideHermesApp()));
}
