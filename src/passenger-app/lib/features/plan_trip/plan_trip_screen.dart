import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/matching_provider.dart';
import 'package:ride_hermes_passenger/features/plan_trip/driver_select_screen.dart';
import 'package:ride_hermes_passenger/features/poi_search/poi_search_screen.dart';
import 'package:ride_hermes_passenger/models/poi.dart';

/// 计划出行 4 步向导页
class PlanTripScreen extends ConsumerStatefulWidget {
  const PlanTripScreen({super.key});

  @override
  ConsumerState<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends ConsumerState<PlanTripScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: 出行类型
  String _tripType = 'single'; // single | recurring

  // Step 2: 路线与时间
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  DateTime _departureTime = DateTime.now().add(const Duration(hours: 1));
  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;

  // Step 3: 偏好设置
  int _carType = 1;
  double _priceRangeMin = 30;
  double _priceRangeMax = 100;
  double _minTrustScore = 4.0;

  static const _carTypeLabels = {1: '经济型', 2: '舒适型', 3: '商务型'};

  @override
  void dispose() {
    _pageController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitDemand();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitDemand() async {
    if (_pickupLat == null || _dropoffLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择起点和终点')),
      );
      return;
    }

    final notifier = ref.read(matchingProvider.notifier);
    await notifier.publishDemand(
      pickupAddr: _pickupController.text,
      pickupLat: _pickupLat!,
      pickupLng: _pickupLng!,
      dropoffAddr: _dropoffController.text,
      dropoffLat: _dropoffLat!,
      dropoffLng: _dropoffLng!,
      departureTime: _departureTime.toIso8601String(),
      carType: _carType,
      priceRangeMin: _priceRangeMin,
      priceRangeMax: _priceRangeMax,
      minTrustScore: _minTrustScore,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverSelectScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('计划出行'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 进度条
          _buildProgressBar(),
          // 内容区域
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1TripType(),
                _buildStep2Route(),
                _buildStep3Preferences(),
                _buildStep4Confirm(),
              ],
            ),
          ),
          // 底部按钮
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isComplete = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isComplete ? AppColors.success : (isActive ? AppColors.primary : Colors.grey[300]),
                    ),
                    child: isComplete
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1TripType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择出行类型',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '您可以选择单次出行或周期性出行',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildTripTypeCard(
            'single',
            Icons.event,
            '单次出行',
            '适合偶尔出行，灵活安排',
          ),
          const SizedBox(height: 16),
          _buildTripTypeCard(
            'recurring',
            Icons.repeat,
            '周期性出行',
            '每日通勤、每周固定，自动撮合',
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeCard(String value, IconData icon, String title, String subtitle) {
    final isSelected = _tripType == value;
    return InkWell(
      onTap: () => setState(() => _tripType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppColors.primary : Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Route() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '路线与时间',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildLocationField(
            controller: _pickupController,
            icon: Icons.trip_origin,
            label: '起点',
            hint: '选择上车地点',
            color: AppColors.success,
            isPickup: true,
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            controller: _dropoffController,
            icon: Icons.location_on,
            label: '终点',
            hint: '选择下车地点',
            color: AppColors.error,
            isPickup: false,
          ),
          const SizedBox(height: 32),
          const Text(
            '出发时间',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _departureTime,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_departureTime),
                );
                if (time != null) {
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
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${_departureTime.month}/${_departureTime.day} ${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required Color color,
    required bool isPickup,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final poi = await Navigator.push<PoiInfo>(
              context,
              MaterialPageRoute(
                builder: (context) => const PoiSearchScreen(),
              ),
            );
            
            if (poi != null) {
              setState(() {
                controller.text = poi.name;
                if (isPickup) {
                  _pickupLat = poi.lat;
                  _pickupLng = poi.lng;
                } else {
                  _dropoffLat = poi.lat;
                  _dropoffLng = poi.lng;
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? hint : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Preferences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '偏好设置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Text(
            '车型选择',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: _carTypeLabels.entries.map((entry) {
              final isSelected = _carType == entry.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _carType = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            '价格区间',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('¥${_priceRangeMin.toInt()}'),
                    Text('¥${_priceRangeMax.toInt()}'),
                  ],
                ),
                RangeSlider(
                  values: RangeValues(_priceRangeMin, _priceRangeMax),
                  min: 20,
                  max: 200,
                  divisions: 36,
                  activeColor: AppColors.primary,
                  onChanged: (values) {
                    setState(() {
                      _priceRangeMin = values.start;
                      _priceRangeMax = values.end;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '最低信誉分',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('≥'),
                    Text(
                      '${_minTrustScore.toStringAsFixed(1)} 分',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _minTrustScore,
                  min: 3.0,
                  max: 5.0,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _minTrustScore = value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Confirm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '确认出行计划',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildConfirmItem('出行类型', _tripType == 'single' ? '单次出行' : '周期性出行'),
          _buildConfirmItem('起点', _pickupController.text.isEmpty ? '未选择' : _pickupController.text),
          _buildConfirmItem('终点', _dropoffController.text.isEmpty ? '未选择' : _dropoffController.text),
          _buildConfirmItem(
            '出发时间',
            '${_departureTime.month}/${_departureTime.day} ${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
          ),
          _buildConfirmItem('车型', _carTypeLabels[_carType] ?? '经济型'),
          _buildConfirmItem('价格区间', '¥${_priceRangeMin.toInt()} - ¥${_priceRangeMax.toInt()}'),
          _buildConfirmItem('最低信誉分', '≥ ${_minTrustScore.toStringAsFixed(1)} 分'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '发布后，系统将自动为您匹配符合条件的司机',
                    style: TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _currentStep < 3 ? '下一步' : '发布需求',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
