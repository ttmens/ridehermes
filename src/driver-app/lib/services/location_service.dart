import 'dart:async';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:ride_hermes_driver/config/app_config.dart';

class LocationService {
  final AMapFlutterLocation _location = AMapFlutterLocation();
  final StreamController<Map<String, dynamic>> _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reportTimer;
  static bool _initialized = false;
  String? _currentCity;

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  String? get currentCity => _currentCity;

  static void init() {
    if (_initialized) return;
    AMapFlutterLocation.setApiKey(
      AppConfig.amapApiKey,
      AppConfig.amapApiKeyIos,
    );
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    _initialized = true;
  }

  Future<void> startLocationUpdates() async {
    init();
    _location.startLocation();
    _location.onLocationChanged().listen((Map<String, Object> result) {
      final lat = result['latitude'] as double?;
      final lng = result['longitude'] as double?;
      if (lat == null || lng == null) return;
      if (result.containsKey('city') && result['city'] is String) {
        _currentCity = result['city'] as String;
      }
      _locationController.add({
        'latitude': lat,
        'longitude': lng,
        'accuracy': result['accuracy'] ?? 0,
        'speed': result['speed'] ?? 0,
        'bearing': result['bearing'] ?? 0,
      });
    });
  }

  void stopLocationUpdates() {
    _location.stopLocation();
    _reportTimer?.cancel();
    _locationController.close();
  }
}
