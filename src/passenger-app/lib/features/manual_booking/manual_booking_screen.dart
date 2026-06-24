import 'dart:async';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/ride_map.dart';
import 'package:ride_hermes_passenger/core/location/amap_service.dart';

class ManualBookingScreen extends ConsumerStatefulWidget {
  const ManualBookingScreen({super.key});

  @override
  ConsumerState<ManualBookingScreen> createState() => _ManualBookingScreenState();
}

class _ManualBookingScreenState extends ConsumerState<ManualBookingScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  int _selectedCarType = 1;
  bool _isSubmitting = false;
  double _pickupLat = 0;
  double _pickupLng = 0;
  double _dropoffLat = 0;
  double _dropoffLng = 0;
  Set<Marker> _markers = {};
  final _amapService = AmapService();
  Timer? _pickupDebounce;
  Timer? _dropoffDebounce;
  final _mapKey = GlobalKey<RideMapState>();

  static const _carTypes = {1: '快车', 2: '专车', 3: '豪华车'};

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationServiceProvider).currentLocation;
    if (loc != null) {
      _pickupLat = loc.lat;
      _pickupLng = loc.lng;
    }
    _updateMarkers();
  }

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropoffDebounce?.cancel();
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
      _pickupController.text = '已选位置 (${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)})';
      _updateMarkers();
    });
  }

  void _onPickupChanged(String text) {
    _pickupDebounce?.cancel();
    if (text.trim().isEmpty) return;
    _pickupDebounce = Timer(const Duration(milliseconds: 500), () async {
      final city = ref.read(locationServiceProvider).currentCity;
      final pos = await _amapService.geocode(text, city: city);
      if (pos != null && mounted) {
        setState(() {
          _pickupLat = pos.latitude;
          _pickupLng = pos.longitude;
          _updateMarkers();
        });
        _mapKey.currentState?.moveCamera(_pickupLat, _pickupLng);
      }
    });
  }

  void _onDropoffChanged(String text) {
    _dropoffDebounce?.cancel();
    if (text.trim().isEmpty) return;
    _dropoffDebounce = Timer(const Duration(milliseconds: 500), () async {
      final city = ref.read(locationServiceProvider).currentCity;
      final pos = await _amapService.geocode(text, city: city);
      if (pos != null && mounted) {
        setState(() {
          _dropoffLat = pos.latitude;
          _dropoffLng = pos.longitude;
          _updateMarkers();
        });
        _mapKey.currentState?.moveCamera(_dropoffLat, _dropoffLng);
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写上车点和下车点')),
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
      'departure_time': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      final orderId = data?['id'];
      if (orderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('叫车成功！')));
        context.push('/trip/$orderId');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '叫车失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final midLat = _dropoffLat != 0 ? (_pickupLat + _dropoffLat) / 2 : _pickupLat;
    final midLng = _dropoffLng != 0 ? (_pickupLng + _dropoffLng) / 2 : _pickupLng;

    return Scaffold(
      appBar: AppBar(title: const Text('手动叫车')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('AI 助手暂不可用，请手动输入叫车信息',
                    style: TextStyle(color: Colors.orange, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pickupController,
              onChanged: _onPickupChanged,
              decoration: const InputDecoration(
                labelText: '上车点',
                prefixIcon: Icon(Icons.trip_origin, color: Colors.blue),
                hintText: '请输入上车点地址或点击地图选点',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dropoffController,
              onChanged: _onDropoffChanged,
              decoration: const InputDecoration(
                labelText: '下车点',
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
                hintText: '请输入下车点地址',
              ),
            ),
            const SizedBox(height: 24),
            const Text('选择车型', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: _carTypes.entries.map((entry) {
                final isSelected = _selectedCarType == entry.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCarType = entry.key),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Icon(_carIcon(entry.key),
                            color: isSelected ? theme.colorScheme.primary : Colors.grey),
                        const SizedBox(height: 4),
                        Text(entry.value, style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? theme.colorScheme.primary : Colors.black87,
                        )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RideMap(
                  key: _mapKey,
                  centerLat: midLat,
                  centerLng: midLng,
                  initialZoom: 12,
                  markers: _markers,
                  onTap: _onMapTap,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('点击地图设置上车点', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _onSubmit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('叫车', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _carIcon(int carType) {
    return switch (carType) {
      1 => Icons.directions_car,
      2 => Icons.airport_shuttle,
      3 => Icons.stars,
      _ => Icons.directions_car,
    };
  }
}
