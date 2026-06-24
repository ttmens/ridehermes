import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/ride_map.dart';
import 'package:ride_hermes_passenger/shared/widgets/car_type_selector.dart';
import 'package:ride_hermes_passenger/shared/widgets/address_input.dart';

class ScheduleTripScreen extends ConsumerStatefulWidget {
  const ScheduleTripScreen({super.key});

  @override
  ConsumerState<ScheduleTripScreen> createState() =>
      _ScheduleTripScreenState();
}

class _ScheduleTripScreenState extends ConsumerState<ScheduleTripScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  int _selectedCarType = 1;
  bool _isSubmitting = false;
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropoffLat = 0;
  double _dropoffLng = 0;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final _mapKey = GlobalKey<RideMapState>();
  DateTime? _departureTime;

  @override
  void initState() {
    super.initState();
    _departureTime = DateTime.now().add(const Duration(hours: 1));
    _updateMarkers();
    Future.microtask(_initPickupLocation);
  }

  Future<void> _initPickupLocation() async {
    final locSvc = ref.read(locationServiceProvider);
    final loc = await locSvc.getCurrentLocation(forceRefresh: true);
    if (!mounted) return;
    if (loc != null) {
      setState(() {
        _pickupLat = loc.lat;
        _pickupLng = loc.lng;
        _updateMarkers();
      });
      _mapKey.currentState?.moveCamera(loc.lat, loc.lng);
      return;
    }
    final approx = await locSvc.getApproximateLocation();
    if (!mounted) return;
    if (approx != null) {
      _mapKey.currentState?.moveCamera(approx.lat, approx.lng);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('定位失败，请到户外或开启 GPS 后手动填写上车点'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        position: LatLng(_pickupLat, _pickupLng),
        infoWindow: const InfoWindow(title: '上车点'),
      ),
      Marker(
        position: LatLng(_dropoffLat, _dropoffLng),
        infoWindow: const InfoWindow(title: '下车点'),
      ),
    };
  }

  void _onPickupResolved(String latLng) {
    final parts = latLng.split(',');
    if (parts.length != 2) return;
    setState(() {
      _pickupLat = double.parse(parts[0]);
      _pickupLng = double.parse(parts[1]);
      _updateMarkers();
    });
    _mapKey.currentState?.moveCamera(_pickupLat, _pickupLng);
    _fetchRouteIfReady();
  }

  void _onDropoffResolved(String latLng) {
    final parts = latLng.split(',');
    if (parts.length != 2) return;
    setState(() {
      _dropoffLat = double.parse(parts[0]);
      _dropoffLng = double.parse(parts[1]);
      _updateMarkers();
    });
    _mapKey.currentState?.moveCamera(_dropoffLat, _dropoffLng);
    _fetchRouteIfReady();
  }

  void _fetchRouteIfReady() {
    if (_pickupLat == 0 || _pickupLng == 0 ||
        _dropoffLat == 0 || _dropoffLng == 0) return;
    final amap = AmapService();
    amap.getDrivingRoute(
      LatLng(_pickupLat, _pickupLng),
      LatLng(_dropoffLat, _dropoffLng),
    ).then((points) {
      if (!mounted || points == null || points.isEmpty) return;
      setState(() {
        _polylines = {
          Polyline(
            points: points,
            width: 6,
            color: AppColors.primary,
          ),
        };
      });
    });
  }

  Future<void> _pickDepartureTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _departureTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _departureTime ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    setState(() {
      _departureTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDepartureTime() {
    if (_departureTime == null) return '请选择出发时间';
    final dt = _departureTime!;
    return '${dt.month}月${dt.day}日 '
        '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
  }

  Future<void> _onSubmit() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写上车点和下车点')),
      );
      return;
    }
    if (_departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择出发时间')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final api = ref.read(apiServiceProvider);
    final result = await api.post('/api/v1/passenger/orders', data: {
      'pickup_addr': _pickupController.text,
      'pickup_lat': _pickupLat,
      'pickup_lng': _pickupLng,
      'dropoff_addr': _dropoffController.text,
      'dropoff_lat': _dropoffLat,
      'dropoff_lng': _dropoffLng,
      'car_type': _selectedCarType,
      'departure_time': _departureTime!.toIso8601String(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      final orderId = data?['id'];
      if (orderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('行程已确定！')),
        );
        context.push('/trip/$orderId');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '提交行程失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final midLat =
        _dropoffLat != 0 ? (_pickupLat + _dropoffLat) / 2 : _pickupLat;
    final midLng =
        _dropoffLng != 0 ? (_pickupLng + _dropoffLng) / 2 : _pickupLng;
    final city = ref.watch(locationServiceProvider).currentCity;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('安排行程'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Departure time picker
            GestureDetector(
              onTap: _pickDepartureTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.schedule,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('出发时间',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          _formatDepartureTime(),
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Address inputs
            AddressInput(
              label: '上车点',
              hint: '请输入上车点地址',
              icon: Icons.trip_origin,
              iconColor: AppColors.info,
              controller: _pickupController,
              city: city,
              onAddressResolved: _onPickupResolved,
            ),
            const SizedBox(height: AppSpacing.base),
            AddressInput(
              label: '下车点',
              hint: '请输入下车点地址',
              icon: Icons.location_on,
              iconColor: AppColors.error,
              controller: _dropoffController,
              city: city,
              onAddressResolved: _onDropoffResolved,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Car type selection
            const Text('选择车型',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.md),
            CarTypeSelector(
              selectedType: _selectedCarType,
              onChanged: (type) => setState(() => _selectedCarType = type),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Route map
            const Text('行程地图',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: RideMap(
                  key: _mapKey,
                  centerLat: _pickupLat != 0 || _pickupLng != 0 ? midLat : null,
                  centerLng: _pickupLat != 0 || _pickupLng != 0 ? midLng : null,
                  initialZoom: 12,
                  markers: _markers,
                  polylines: _polylines,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确定行程',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
