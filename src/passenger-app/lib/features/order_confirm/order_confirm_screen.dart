import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/ride_map.dart';
import 'package:ride_hermes_passenger/shared/widgets/car_type_selector.dart';
import 'package:ride_hermes_passenger/shared/widgets/address_input.dart';

class OrderConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? orderPreview;
  const OrderConfirmScreen({super.key, this.orderPreview});

  @override
  ConsumerState<OrderConfirmScreen> createState() =>
      _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends ConsumerState<OrderConfirmScreen> {
  int _selectedCarType = 1;
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _isSubmitting = false;
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropoffLat = 0;
  double _dropoffLng = 0;
  Set<Marker> _markers = {};
  final _mapKey = GlobalKey<RideMapState>();
  DateTime? _departureTime;

  @override
  void initState() {
    super.initState();
    final preview = widget.orderPreview;
    if (preview != null) {
      if (preview['pickup'] != null) {
        _pickupController.text = preview['pickup']['address'] ?? '';
        final lat = preview['pickup']['lat'];
        final lng = preview['pickup']['lng'];
        if (lat != null) _pickupLat = (lat as num).toDouble();
        if (lng != null) _pickupLng = (lng as num).toDouble();
      }
      if (preview['dropoff'] != null) {
        _dropoffController.text = preview['dropoff']['address'] ?? '';
        final lat = preview['dropoff']['lat'];
        final lng = preview['dropoff']['lng'];
        if (lat != null) _dropoffLat = (lat as num).toDouble();
        if (lng != null) _dropoffLng = (lng as num).toDouble();
      }
      _selectedCarType = preview['car_type'] as int? ?? 1;
    }
    if (_pickupLat == 0 && _pickupLng == 0) {
      final loc = ref.read(locationServiceProvider).currentLocation;
      if (loc != null) {
        _pickupLat = loc.lat;
        _pickupLng = loc.lng;
      }
    }
    _updateMarkers();
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

  void _onMapTap(LatLng point) {
    setState(() {
      _pickupLat = point.latitude;
      _pickupLng = point.longitude;
      _pickupController.text =
          '已选择位置 (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})';
      _updateMarkers();
    });
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

  Future<void> _onConfirm() async {
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
        context.go('/trip/$orderId');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '创建订单失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.orderPreview;
    final estPrice = preview?['est_price'] as double? ?? 0;

    final midLat =
        _dropoffLat != 0 ? (_pickupLat + _dropoffLat) / 2 : _pickupLat;
    final midLng =
        _dropoffLng != 0 ? (_pickupLng + _dropoffLng) / 2 : _pickupLng;
    final city = ref.watch(locationServiceProvider).currentCity;

    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('确认预约')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: RideMap(
                  key: _mapKey,
                  centerLat: midLat,
                  centerLng: midLng,
                  markers: _markers,
                  onTap: _onMapTap,
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              children: [
                AddressInput(
                  label: '上车点',
                  hint: '请输入上车点或点击地图选点',
                  icon: Icons.trip_origin,
                  iconColor: AppColors.info,
                  controller: _pickupController,
                  city: city,
                  onAddressResolved: _onPickupResolved,
                ),
                const SizedBox(height: AppSpacing.md),
                AddressInput(
                  label: '下车点',
                  hint: '请输入下车点',
                  icon: Icons.location_on,
                  iconColor: AppColors.error,
                  controller: _dropoffController,
                  city: city,
                  onAddressResolved: _onDropoffResolved,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: CarTypeSelector(
              selectedType: _selectedCarType,
              onChanged: (type) =>
                  setState(() => _selectedCarType = type),
              showPrice: estPrice > 0,
              priceEstimates: estPrice > 0
                  ? {1: estPrice, 2: estPrice, 3: estPrice}
                  : null,
            ),
          ),
          const Spacer(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: InkWell(
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
                    const Icon(Icons.schedule, color: AppColors.info),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _departureTime != null
                          ? '出发时间: ${_departureTime!.month}/${_departureTime!.day} '
                              '${_departureTime!.hour.toString().padLeft(2, "0")}:${_departureTime!.minute.toString().padLeft(2, "0")}'
                          : '请选择出发时间',
                      style: TextStyle(
                        fontSize: 15,
                        color: _departureTime != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onConfirm,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('确认预约',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
