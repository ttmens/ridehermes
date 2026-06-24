import 'dart:async';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:flutter/foundation.dart';
import 'package:ride_hermes_passenger/config/app_config.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';
import 'package:ride_hermes_passenger/models/location.dart';

class LocationService {
  LocationInfo? _currentLocation;
  String? _currentAddress;
  String? _currentCity;
  final _locationController = StreamController<LocationInfo>.broadcast();
  Stream<LocationInfo> get onLocationChanged => _locationController.stream;
  LocationInfo? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  String? get currentCity => _currentCity;

  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  StreamSubscription<Map<String, Object>>? _locationSub;
  bool _started = false;

  static void init() {
    debugPrint('[LocationService] init() called');
    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    AMapFlutterLocation.setApiKey(AppConfig.amapAndroidKey, AppConfig.amapIosKey);
    debugPrint('[LocationService] init() done, androidKey=${AppConfig.amapAndroidKey}');
  }

  void startLocationUpdates() {
    if (_started) {
      debugPrint('[LocationService] already started');
      return;
    }
    _started = true;
    debugPrint('[LocationService] startLocationUpdates()');

    final option = AMapLocationOption(
      onceLocation: false,
      needAddress: true,
      geoLanguage: GeoLanguage.ZH,
      locationInterval: 3000,
      locationMode: AMapLocationMode.Hight_Accuracy,
    );
    _locationPlugin.setLocationOption(option);

    _locationSub = _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {
      debugPrint('[LocationService] onLocationChanged: $result');
      if (result.containsKey('errorCode')) {
        debugPrint('[LocationService] error: code=${result['errorCode']}, info=${result['errorInfo']}');
        return;
      }
      if (result.containsKey('latitude') && result.containsKey('longitude')) {
        final lat = result['latitude'];
        final lng = result['longitude'];
        if (lat != null && lng != null) {
          final latVal = (lat is num) ? lat.toDouble() : 0.0;
          final lngVal = (lng is num) ? lng.toDouble() : 0.0;
          if (latVal != 0 && lngVal != 0) {
            final loc = LocationInfo(
              lat: latVal,
              lng: lngVal,
              accuracy: (result['accuracy'] is num) ? (result['accuracy'] as num).toDouble() : 0,
              speed: (result['speed'] is num) ? (result['speed'] as num).toDouble() : 0,
              bearing: (result['bearing'] is num) ? (result['bearing'] as num).toDouble() : 0,
            );
            _currentLocation = loc;
            _locationController.add(loc);

            if (result.containsKey('address') && result['address'] is String) {
              _currentAddress = result['address'] as String;
            }
            if (result.containsKey('city') && result['city'] is String) {
              _currentCity = result['city'] as String;
            }
          }
        }
      }
    });

    _locationPlugin.startLocation();
    debugPrint('[LocationService] startLocation() called');
  }

  void stopLocationUpdates() {
    _locationSub?.cancel();
    _locationSub = null;
    _started = false;
    _locationPlugin.stopLocation();
  }

  Future<LocationInfo?> getCurrentLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentLocation != null) return _currentLocation;
    startLocationUpdates();
    try {
      return await _locationController.stream.first.timeout(const Duration(seconds: 15));
    } catch (_) {}
    return null;
  }

  /// IP-based approximate location, intended ONLY for map center hints
  /// (not as a real pickup coordinate). Returns null if the lookup fails.
  Future<LocationInfo?> getApproximateLocation() async {
    final ipLoc = await AmapService().ipLocation();
    if (ipLoc != null) {
      return LocationInfo(lat: ipLoc.latitude, lng: ipLoc.longitude);
    }
    return null;
  }

  void dispose() {
    stopLocationUpdates();
    _locationPlugin.destroy();
    _locationController.close();
  }
}
