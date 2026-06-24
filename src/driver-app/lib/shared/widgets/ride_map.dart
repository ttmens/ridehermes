import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:ride_hermes_driver/config/app_config.dart';

class RideMap extends StatefulWidget {
  final LatLng? initialPosition;
  final double initialZoom;
  final Set<Marker> markers;
  final Set<Polyline>? polylines;
  final bool showMyLocation;
  final void Function(AMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;

  const RideMap({
    super.key,
    this.initialPosition,
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

  // 默认中心点：北京望京 SOHO（不再是 0,0 大西洋）
  static const LatLng defaultPosition = LatLng(39.996171, 116.470293);

  static const _apiKey = AMapApiKey(
    androidKey: AppConfig.amapApiKey,
    iosKey: AppConfig.amapApiKeyIos,
  );
  static const _privacyStatement = AMapPrivacyStatement(
    hasContains: true,
    hasShow: true,
    hasAgree: true,
  );

  void moveCamera(LatLng target, {double zoom = 15}) {
    _controller?.moveCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  @override
  Widget build(BuildContext context) {
    return AMapWidget(
      apiKey: _apiKey,
      privacyStatement: _privacyStatement,
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition ?? defaultPosition,
        zoom: widget.initialZoom,
      ),
      markers: widget.markers,
      polylines: widget.polylines ?? <Polyline>{},
      myLocationStyleOptions: MyLocationStyleOptions(widget.showMyLocation),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}
