import 'dart:async';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/auth_provider.dart';
import 'package:ride_hermes_driver/providers/driver_tracking_provider.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';
import 'package:ride_hermes_driver/providers/services_provider.dart';
import 'package:ride_hermes_driver/screens/widgets/dashboard_widgets.dart';
import 'package:ride_hermes_driver/shared/widgets/ride_map.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  StreamSubscription? _mapLocationSub;
  AMapController? _mapController;
  double _currentLat = 0;
  double _currentLng = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initDashboard());
  }

  Future<void> _initDashboard() async {
    final notifier = ref.read(driverOrderProvider.notifier);
    await notifier.fetchOrders();
    if (ref.read(driverOrderProvider).isOnline) {
      await ref.read(driverTrackingProvider).start();
      _subscribeMapLocation();
    }
  }

  void _subscribeMapLocation() {
    _mapLocationSub?.cancel();
    final locSvc = ref.read(locationServiceProvider);
    var firstFix = true;
    _mapLocationSub = locSvc.locationStream.listen((pos) {
      if (!mounted) return;
      final lat = pos['latitude'] as double;
      final lng = pos['longitude'] as double;
      _currentLat = lat;
      _currentLng = lng;
      if (firstFix) {
        firstFix = false;
        _mapController?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
      }
    });
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!mounted) return false;
    if (!status.isGranted && !status.isLimited) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要定位权限才能使用出车功能')),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _mapLocationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final orderState = ref.watch(driverOrderProvider);
    final notifier = ref.read(driverOrderProvider.notifier);

    final hasPending = orderState.pendingOrders.isNotEmpty;
    final hasCurrent = orderState.currentOrder != null;

    Set<Marker> markers = {};
    LatLng? mapCenter;

    if (hasCurrent) {
      final o = orderState.currentOrder!;
      final pickup = LatLng(o.pickupLat, o.pickupLng);
      markers.add(Marker(
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: '上车点', snippet: o.pickupAddr),
      ));
      if (o.dropoffLat != 0 && o.dropoffLng != 0) {
        markers.add(Marker(
          position: LatLng(o.dropoffLat, o.dropoffLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: '下车点', snippet: o.dropoffAddr),
        ));
      }
      mapCenter = pickup;
    } else if (hasPending) {
      final o = orderState.pendingOrders.first;
      final pickup = LatLng(o.pickupLat, o.pickupLng);
      markers.add(Marker(
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: '上车点', snippet: o.pickupAddr),
      ));
      mapCenter = pickup;
    }

    final showMap = mapCenter != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: 14,
              ),
              color: orderState.isOnline
                  ? AppColors.success.withOpacity( 0.08)
                  : AppColors.background,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: orderState.isOnline
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    orderState.isOnline ? '空闲待接单' : '已收车',
                    style: TextStyle(
                      color: orderState.isOnline
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    authState.user?.nickname ?? '司机',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 24, color: AppColors.textSecondary),
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        // Operation grid
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppSpacing.base,
                          crossAxisSpacing: AppSpacing.base,
                          children: [
                            OpTile(
                              icon: Icons.receipt_long,
                              label: '今日订单',
                              color: AppColors.info,
                              iconSize: 36,
                              fontSize: 15,
                              onTap: () => context.go('/orders'),
                            ),
                            OpTile(
                              icon: Icons.account_balance_wallet,
                              label: '今日收入',
                              color: AppColors.warning,
                              value: '¥0.00',
                              iconSize: 36,
                              fontSize: 15,
                            ),
                            OpTile(
                              icon: Icons.star,
                              label: '我的评分',
                              color: AppColors.info,
                              value: '5.0',
                              iconSize: 36,
                              fontSize: 15,
                            ),
                            OpTile(
                              icon: Icons.notifications,
                              label: '消息中心',
                              color: AppColors.error,
                              value: '暂无新消息',
                              iconSize: 36,
                              fontSize: 15,
                            ),
                            OpTile(
                              icon: Icons.person,
                              label: '个人中心',
                              color: AppColors.primary,
                              iconSize: 36,
                              fontSize: 15,
                              onTap: () => context.go('/profile'),
                            ),
                            OpTile(
                              icon: Icons.headset_mic,
                              label: '客服帮助',
                              color: AppColors.primary,
                              value: '400-xxx-xxxx',
                              iconSize: 36,
                              fontSize: 15,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Map area
                        if (showMap)
                          Container(
                            height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.divider),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: RideMap(
                              initialPosition: mapCenter,
                              initialZoom: 14,
                              markers: markers,
                              showMyLocation: orderState.isOnline,
                              onMapCreated: (ctrl) {
                                _mapController = ctrl;
                              },
                            ),
                          )
                        else if (orderState.isOnline)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.divider),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: RideMap(
                              initialPosition: (_currentLat != 0 && _currentLng != 0)
                                  ? LatLng(_currentLat, _currentLng)
                                  : null,
                              initialZoom: 13,
                              showMyLocation: true,
                            ),
                          ),

                        const SizedBox(height: AppSpacing.base),

                        // Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.drive_eta, size: 44, color: Colors.white),
                              SizedBox(height: AppSpacing.md),
                              Text(
                                '安全驾驶，文明出行',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'RideHermes 伴您一路平安',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.base),

                        // Online info row
                        if (orderState.isOnline)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.base,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity( 0.08),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.success.withOpacity( 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.success, size: 24),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    '您已上线，系统将为您自动派单',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Dispatch notification overlay
                  if (hasPending)
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: PendingOrdersPanel(
                        orders: orderState.pendingOrders,
                        onAccept: (orderId) => notifier.acceptOrder(orderId),
                        onReject: (orderId) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('确认拒绝'),
                              content: const Text('确定要拒绝这个订单吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('拒绝'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            notifier.rejectOrder(orderId);
                          }
                        },
                        onTap: (orderId) => context.push('/trip/$orderId'),
                      ),
                    ),
                  // Current order bar
                  if (hasCurrent && !hasPending)
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: CurrentOrderBar(
                        order: orderState.currentOrder!,
                        onTap: () =>
                            context.push('/trip/${orderState.currentOrder!.id}'),
                      ),
                    ),
                ],
              ),
            ),

            // Online/Offline button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    final tracking = ref.read(driverTrackingProvider);
                    if (orderState.isOnline) {
                      await tracking.stop();
                      await notifier.goOffline();
                      _mapLocationSub?.cancel();
                    } else {
                      final ok = await _requestLocationPermission();
                      if (!ok) return;
                      await notifier.goOnline(
                        lat: _currentLat,
                        lng: _currentLng,
                      );
                      if (ref.read(driverOrderProvider).isOnline) {
                        await tracking.start();
                        _subscribeMapLocation();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orderState.isOnline
                        ? AppColors.error
                        : AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(orderState.isOnline ? '收  车' : '出  车'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
