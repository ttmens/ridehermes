import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:ride_hermes_passenger/config/app_config.dart';
class RideMap extends StatefulWidget {
  final double? centerLat;
  final double? centerLng;
  final double initialZoom;
  final Set<Marker> markers;
  final Set<Polyline>? polylines;
  final bool showMyLocation;
  final void Function(AMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;

  const RideMap({
    super.key,
    this.centerLat,
    this.centerLng,
    this.initialZoom = 15,
    this.markers = const <Marker>{},
    this.polylines,
    this.showMyLocation = true,
    this.onMapCreated,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<RideMap> createState() => RideMapState();
}

class RideMapState extends State<RideMap> {
  AMapController? _controller;
  LatLng? _pendingCamera;

  // 默认中心点：北京望京 SOHO（不再是 0,0 大西洋）
  static const double defaultLat = 39.996171;
  static const double defaultLng = 116.470293;

  static const _apiKey = AMapApiKey(
    androidKey: AppConfig.amapAndroidKey,
    iosKey: AppConfig.amapIosKey,
  );
  static const _privacyStatement = AMapPrivacyStatement(
    hasContains: true,
    hasShow: true,
    hasAgree: true,
  );

  void moveCamera(double lat, double lng, {double zoom = 15}) {
    final target = LatLng(lat, lng);
    if (_controller != null) {
      _controller!.moveCamera(CameraUpdate.newLatLngZoom(target, zoom));
    } else {
      _pendingCamera = target;
    }
  }

  @override
  void didUpdateWidget(RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.centerLat ?? defaultLat;
    final lng = widget.centerLng ?? defaultLng;
    final oldLat = oldWidget.centerLat ?? defaultLat;
    final oldLng = oldWidget.centerLng ?? defaultLng;
    if (lat != oldLat || lng != oldLng) {
      moveCamera(lat, lng, zoom: widget.initialZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerLat = widget.centerLat ?? defaultLat;
    final centerLng = widget.centerLng ?? defaultLng;

    return AMapWidget(
      apiKey: _apiKey,
      privacyStatement: _privacyStatement,
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLng),
        zoom: widget.initialZoom,
      ),
      markers: widget.markers,
      polylines: widget.polylines ?? <Polyline>{},
      myLocationStyleOptions: MyLocationStyleOptions(widget.showMyLocation),
      onMapCreated: (controller) {
        _controller = controller;
        if (_pendingCamera != null) {
          controller.moveCamera(
            CameraUpdate.newLatLngZoom(_pendingCamera!, widget.initialZoom),
          );
          _pendingCamera = null;
        }
        widget.onMapCreated?.call(controller);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}
