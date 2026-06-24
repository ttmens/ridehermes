import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:ride_hermes_driver/models/order.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';
import 'package:ride_hermes_driver/services/amap_service.dart';
import 'package:ride_hermes_driver/shared/widgets/ride_map.dart';

class TripScreen extends ConsumerStatefulWidget {
  final int orderId;
  const TripScreen({super.key, required this.orderId});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  final _amapService = AmapService();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _center = const LatLng(0.0, 0.0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadOrder());
  }

  Future<void> _loadOrder() async {
    await ref.read(driverOrderProvider.notifier).fetchOrders();
    final state = ref.read(driverOrderProvider);
    final order = state.currentOrder;
    if (order == null) return;

    _setupMap(order);
    _loadRoute(order);
  }

  void _setupMap(Order order) {
    final pickup = LatLng(order.pickupLat, order.pickupLng);
    final dropoff = LatLng(order.dropoffLat, order.dropoffLng);
    _center = pickup;

    setState(() {
      _markers = {
        Marker(
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: '上车点', snippet: order.pickupAddr),
        ),
        Marker(
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: '下车点', snippet: order.dropoffAddr),
        ),
      };
    });
  }

  Future<void> _loadRoute(Order order) async {
    final pickup = LatLng(order.pickupLat, order.pickupLng);
    final dropoff = LatLng(order.dropoffLat, order.dropoffLng);
    final points = await _amapService.getDrivingRoute(pickup, dropoff);
    if (points != null && mounted) {
      setState(() {
        _polylines = {
          Polyline(
            points: points,
            color: Colors.blue,
            width: 6,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(driverOrderProvider);
    final order = orderState.currentOrder;
    final notifier = ref.read(driverOrderProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('行程详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: order == null
          ? const Center(child: Text('未找到订单'))
          : Column(
              children: [
                // Passenger info
                if (order.passenger != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.passenger!.nickname,
                                  style: theme.textTheme.titleMedium),
                              Text(order.passenger!.phone,
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Map
                Expanded(
                  child: RideMap(
                    initialPosition: _center,
                    markers: _markers,
                    polylines: _polylines,
                    showMyLocation: true,
                  ),
                ),

                // Route info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Metric(label: '距离', value: '${(order.estDistance / 1000).toStringAsFixed(1)}km'),
                          _Metric(label: '预计', value: '${order.estDuration}min'),
                          _Metric(label: '费用', value: '¥${order.estPrice.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(order.pickupAddr, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(order.dropoffAddr, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildActionButton(order, notifier, context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(Order order, DriverOrderNotifier notifier, BuildContext context) {
    if (order.canArrive) {
      return ElevatedButton.icon(
        onPressed: () async {
          await notifier.arrive();
          if (context.mounted) _loadOrder();
        },
        icon: const Icon(Icons.flag),
        label: const Text('到达上车点'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (order.canStart) {
      return ElevatedButton.icon(
        onPressed: () async {
          await notifier.startTrip();
          if (context.mounted) _loadOrder();
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('开始行程'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    if (order.canComplete) {
      return ElevatedButton.icon(
        onPressed: () async {
          await notifier.completeOrder();
          if (context.mounted) context.pop();
        },
        icon: const Icon(Icons.check),
        label: const Text('完成订单'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
