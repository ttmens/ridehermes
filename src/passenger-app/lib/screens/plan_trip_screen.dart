import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/matching_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/address_input.dart';
import 'package:ride_hermes_passenger/shared/widgets/car_type_selector.dart';

class PlanTripScreen extends ConsumerStatefulWidget {
  const PlanTripScreen({super.key});

  @override
  ConsumerState<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends ConsumerState<PlanTripScreen> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _departureDateController = TextEditingController();
  final _departureTimeController = TextEditingController();
  
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  int _carType = 1;
  double _priceRangeMin = 30;
  double _priceRangeMax = 100;
  double _minTrustScore = 4.0;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _departureDateController.dispose();
    _departureTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _departureDate = date;
        _departureDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _departureTime = time;
        _departureTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitDemand() async {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写起点和终点')),
      );
      return;
    }

    if (_departureDate == null || _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择出发时间')),
      );
      return;
    }

    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    final notifier = ref.read(matchingProvider.notifier);
    await notifier.publishDemand(
      pickupAddr: _pickupController.text,
      dropoffAddr: _dropoffController.text,
      departureTime: departureDateTime.toIso8601String(),
      carType: _carType,
      priceRangeMin: _priceRangeMin,
      priceRangeMax: _priceRangeMax,
      minTrustScore: _minTrustScore,
    );

    if (mounted) {
      Navigator.pushNamed(context, '/driver-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('计划出行'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddressInput(
              controller: _pickupController,
              label: '起点',
              hint: '请输入上车地点',
            ),
            const SizedBox(height: 16),
            AddressInput(
              controller: _dropoffController,
              label: '终点',
              hint: '请输入下车地点',
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('出发日期'),
              subtitle: Text(_departureDateController.text.isEmpty ? '请选择日期' : _departureDateController.text),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            ListTile(
              title: const Text('出发时间'),
              subtitle: Text(_departureTimeController.text.isEmpty ? '请选择时间' : _departureTimeController.text),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            const Text('车型选择', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CarTypeSelector(
              selectedType: _carType,
              onSelected: (type) => setState(() => _carType = type),
            ),
            const SizedBox(height: 16),
            const Text('价格范围', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            RangeSlider(
              values: RangeValues(_priceRangeMin, _priceRangeMax),
              min: 10,
              max: 500,
              divisions: 49,
              labels: RangeLabels('¥${_priceRangeMin.toInt()}', '¥${_priceRangeMax.toInt()}'),
              onChanged: (values) {
                setState(() {
                  _priceRangeMin = values.start;
                  _priceRangeMax = values.end;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('最低信誉分要求', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _minTrustScore,
              min: 0,
              max: 5,
              divisions: 50,
              label: _minTrustScore.toStringAsFixed(1),
              onChanged: (value) {
                setState(() => _minTrustScore = value);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitDemand,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('发布需求', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
