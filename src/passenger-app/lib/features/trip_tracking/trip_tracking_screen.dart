import 'dart:async';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/models/order.dart';
import 'package:ride_hermes_passenger/shared/utils/formatters.dart';
import 'package:ride_hermes_passenger/shared/widgets/ride_map.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';
import 'package:ride_hermes_passenger/core/storage/token_storage.dart';
import 'package:ride_hermes_passenger/core/ws/ws_client.dart';
import 'package:ride_hermes_passenger/core/ws/ws_message.dart';

class TripTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const TripTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends ConsumerState<TripTrackingScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;
  Timer? _driverLocTimer;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  double? _driverLat;
  double? _driverLng;
  bool _completedNotified = false;
  final _mapKey = GlobalKey<RideMapState>();
  WsClient? _ws;
  StreamSubscription? _wsSub;
  StreamSubscription? _passengerLocSub;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    _startTrackingServices();
  }

  Future<void> _startTrackingServices() async {
    final ws = WsClient(tokenStorage: TokenStorage());
    await ws.connect();
    _ws = ws;
    _wsSub = ws.messages.listen((msg) {
      if (!mounted) return;
      if (msg.type == WsMessageType.orderStatus) {
        _fetchOrderSilently();
      }
    });
    final locSvc = ref.read(locationServiceProvider);
    locSvc.startLocationUpdates();
    _passengerLocSub = locSvc.onLocationChanged.listen((loc) {
      ws.sendLocationUpdate(latitude: loc.lat, longitude: loc.lng);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverLocTimer?.cancel();
    _wsSub?.cancel();
    _passengerLocSub?.cancel();
    _ws?.disconnect();
    super.dispose();
  }

  void _updateMarkers(Order order, {double? driverLat, double? driverLng}) {
    final lat = driverLat ?? _driverLat;
    final lng = driverLng ?? _driverLng;
    final markers = <Marker>{
      Marker(
        position: LatLng(order.pickupLat, order.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '上车点'),
      ),
      Marker(
        position: LatLng(order.dropoffLat, order.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '下车点'),
      ),
    };
    if (lat != null && lng != null && lat != 0 && lng != 0) {
      markers.add(Marker(
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '司机位置'),
      ));
    }
    _markers = markers;
  }

  Future<void> _fetchDriverLocation(Order order) async {
    if (order.driverId == null || order.status < 2) return;
    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/driver-location/${order.id}');
    double? lat;
    double? lng;
    if (result.isSuccess && result.data != null) {
      final locData = result.data!['data'];
      if (locData is Map<String, dynamic>) {
        lat = double.tryParse('${locData['lat'] ?? locData['latitude'] ?? ''}');
        lng = double.tryParse('${locData['lng'] ?? locData['longitude'] ?? ''}');
      }
    }
    if (!mounted || lat == null || lng == null || lat == 0 || lng == 0) return;
    setState(() {
      _driverLat = lat;
      _driverLng = lng;
      _updateMarkers(order, driverLat: lat, driverLng: lng);
    });
    _mapKey.currentState?.moveCamera(lat, lng);
  }

  Future<void> _fetchRoute(Order order) async {
    final amap = AmapService();
    final points = await amap.getDrivingRoute(
      LatLng(order.pickupLat, order.pickupLng),
      LatLng(order.dropoffLat, order.dropoffLng),
    );
    final routePoints = (points != null && points.isNotEmpty)
        ? points
        : [
            LatLng(order.pickupLat, order.pickupLng),
            LatLng(order.dropoffLat, order.dropoffLng),
          ];
    if (mounted) {
      setState(() {
        _polylines = {
          Polyline(
            points: routePoints,
            color: Colors.blue,
            width: 6,
          ),
        };
      });
    }
  }

  Future<void> _fetchOrder() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/orders/${widget.orderId}');

    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final order = Order.fromJson(data);
        setState(() {
          _order = order;
          _isLoading = false;
          _updateMarkers(order);
        });
        _fetchRoute(order);
        _fetchDriverLocation(order);
        _startPolling();
      }
    } else {
      setState(() {
        _error = result.message ?? '加载失败';
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _driverLocTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchOrderSilently());
    _driverLocTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final order = _order;
      if (order != null && order.status >= 2 && order.status <= 6) {
        _fetchDriverLocation(order);
      }
    });
  }

  Future<void> _fetchOrderSilently() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/orders/${widget.orderId}');
    if (result.isSuccess && result.data != null && mounted) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final order = Order.fromJson(data);
        setState(() {
          _order = order;
          _updateMarkers(order);
        });
        if (order.status >= 2 && order.status <= 6) {
          _fetchDriverLocation(order);
        }
        if (order.status == 7) {
          if (_polylines.isEmpty) {
            _fetchRoute(order);
          }
          if (!_completedNotified && mounted) {
            _completedNotified = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('行程已完成')),
            );
          }
        }
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消订单'),
        content: const Text('确定要取消这个订单吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('不用了')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定取消'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final api = ref.read(apiServiceProvider);
      final result = await api.post('/api/v1/passenger/orders/${widget.orderId}/cancel', data: {'reason': '乘客取消'});
      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('订单已取消')));
          if (context.mounted) context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? '取消失败')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('行程追踪'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('行程追踪'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? '订单不存在'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('返回首页')),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final canCancel = order.status >= 1 && order.status <= 3;
    final midLat = (order.pickupLat + order.dropoffLat) / 2;
    final midLng = (order.pickupLng + order.dropoffLng) / 2;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('行程 #${order.orderNo}'),
      ),
      body: Column(
        children: [
          if (order.status >= 2 && order.driver != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 24,
                    child: Text(
                      (order.driver!.nickname?.isNotEmpty == true ? order.driver!.nickname![0] : '司').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.driver!.nickname ?? '司机', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        if (order.driver!.vehicle != null) ...[
                          const SizedBox(height: 2),
                          Text('${order.driver!.vehicle!.plateNumber}  ${order.driver!.vehicle!.brand} ${order.driver!.vehicle!.model}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                        if (order.driver!.rating != null) ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(order.driver!.rating!.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RideMap(
                  key: _mapKey,
                  centerLat: _driverLat ?? midLat,
                  centerLng: _driverLng ?? midLng,
                  markers: _markers,
                  polylines: _polylines,
                  showMyLocation: order.status <= 6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.statusText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(Formatters.formatPrice(order.estPrice),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: theme.colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.trip_origin, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.pickupAddr, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.dropoffAddr, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.straighten, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(Formatters.formatDistance(order.estDistance), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(Formatters.formatDuration(order.estDuration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (canCancel)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('取消订单'),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
