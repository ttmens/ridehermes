import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/app.dart';
import 'package:ride_hermes_driver/services/location_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocationService.init();
  runApp(const ProviderScope(child: RideHermesDriverApp()));
}
