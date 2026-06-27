import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/recurring_trip_provider.dart';
import '../theme/app_theme.dart';

class RecurringTripsScreen extends ConsumerStatefulWidget {
  const RecurringTripsScreen({super.key});

  @override
  ConsumerState<RecurringTripsScreen> createState() =>
      _RecurringTripsScreenState();
}

class _RecurringTripsScreenState
    extends ConsumerState<RecurringTripsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recurringTripProvider.notifier).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期性出行'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.trips.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.trips.length,
                  itemBuilder: (context, index) {
                    final trip = state.trips[index];
                    return _buildTripCard(trip);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_repeat, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            '暂无周期性出行计划',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角 + 创建您的第一个周期性出行',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: const Icon(Icons.add),
            label: const Text('创建周期性出行'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(RecurringTrip trip) {
    final typeLabel = _getTypeLabel(trip.tripType);
    final typeIcon = _getTypeIcon(trip.tripType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trip.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trip.isActive ? '进行中' : '已暂停',
                    style: TextStyle(
                      fontSize: 12,
                      color: trip.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.pickupAddr,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.flag, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trip.dropoffAddr,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      trip.departureTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _getDaysLabel(trip.daysOfWeek),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _toggleTripStatus(trip),
                  icon: Icon(trip.isActive ? Icons.pause : Icons.play_arrow),
                  label: Text(trip.isActive ? '暂停' : '启用'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteTrip(trip),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'daily':
        return '每日出行';
      case 'workday':
        return '工作日出行';
      case 'weekly':
        return '每周出行';
      default:
        return '自定义出行';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'workday':
        return Icons.work;
      case 'weekly':
        return Icons.date_range;
      default:
        return Icons.event;
    }
  }

  String _getDaysLabel(String daysOfWeek) {
    if (daysOfWeek.isEmpty) return '每天';
    final days = daysOfWeek.split(',');
    const dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${days.map((d) => dayNames[int.tryParse(d) ?? 0]).join('、')}';
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateRecurringTripDialog(),
    );

    if (result != null) {
      final success = await ref
          .read(recurringTripProvider.notifier)
          .createTrip(result);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('周期性出行创建成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleTripStatus(RecurringTrip trip) async {
    final success = await ref
        .read(recurringTripProvider.notifier)
        .toggleTripStatus(trip.id, !trip.isActive);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(trip.isActive ? '已暂停' : '已启用'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteTrip(RecurringTrip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个周期性出行计划吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(recurringTripProvider.notifier)
          .deleteTrip(trip.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class CreateRecurringTripDialog extends StatefulWidget {
  const CreateRecurringTripDialog({super.key});

  @override
  State<CreateRecurringTripDialog> createState() =>
      _CreateRecurringTripDialogState();
}

class _CreateRecurringTripDialogState extends State<CreateRecurringTripDialog> {
  String _tripType = 'workday';
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建周期性出行'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('出行类型', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tripType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日出行')),
                DropdownMenuItem(value: 'workday', child: Text('工作日出行')),
                DropdownMenuItem(value: 'weekly', child: Text('每周出行')),
              ],
              onChanged: (value) {
                setState(() => _tripType = value!);
              },
            ),
            const SizedBox(height: 16),
            const Text('出发时间', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _departureTime,
                );
                if (time != null) {
                  setState(() => _departureTime = time);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('起点', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                hintText: '输入起点地址',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('终点', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                hintText: '输入终点地址',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请填写起点和终点')),
              );
              return;
            }

            Navigator.pop(context, {
              'trip_type': _tripType,
              'departure_time':
                  '${_departureTime.hour.toString().padLeft(2, '0')}:${_departureTime.minute.toString().padLeft(2, '0')}',
              'days_of_week': _selectedDays.join(','),
              'pickup_addr': _pickupController.text,
              'dropoff_addr': _dropoffController.text,
              'pickup_lat': 0.0,
              'pickup_lng': 0.0,
              'dropoff_lat': 0.0,
              'dropoff_lng': 0.0,
              'car_type': 1,
              'start_date': DateTime.now().toIso8601String(),
              'end_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('创建'),
        ),
      ],
    );
  }
}
