import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/recurring_trip_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/address_input.dart';

class RecurringTripsScreen extends ConsumerStatefulWidget {
  const RecurringTripsScreen({super.key});

  @override
  ConsumerState<RecurringTripsScreen> createState() => _RecurringTripsScreenState();
}

class _RecurringTripsScreenState extends ConsumerState<RecurringTripsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recurringTripProvider.notifier).loadTrips();
    });
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateRecurringTripDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recurringTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期性出行'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '暂无周期性出行计划',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击右上角 + 创建新的周期性出行',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.trips.length,
                  itemBuilder: (context, index) {
                    final trip = state.trips[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: trip.isActive ? Colors.green : Colors.grey,
                          child: Icon(
                            trip.isActive ? Icons.check : Icons.pause,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(trip.pickupAddr),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('→ ${trip.dropoffAddr}'),
                            const SizedBox(height: 4),
                            Text(
                              '类型: ${trip.tripType} | 出发: ${trip.departureTime}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'toggle',
                              child: Text('启用/禁用'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('删除', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'toggle') {
                              ref.read(recurringTripProvider.notifier).toggleTripStatus(trip.id);
                            } else if (value == 'delete') {
                              _confirmDelete(trip.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个周期性出行计划吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(recurringTripProvider.notifier).deleteTrip(id);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CreateRecurringTripDialog extends ConsumerStatefulWidget {
  const _CreateRecurringTripDialog();

  @override
  ConsumerState<_CreateRecurringTripDialog> createState() => _CreateRecurringTripDialogState();
}

class _CreateRecurringTripDialogState extends ConsumerState<_CreateRecurringTripDialog> {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  String _tripType = 'daily';
  String _departureTime = '08:00';

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写起点和终点')),
      );
      return;
    }

    ref.read(recurringTripProvider.notifier).createTrip(
      pickupAddr: _pickupController.text,
      dropoffAddr: _dropoffController.text,
      tripType: _tripType,
      departureTime: _departureTime,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建周期性出行'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            DropdownButtonFormField<String>(
              value: _tripType,
              decoration: const InputDecoration(labelText: '出行类型'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每日')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'workday', child: Text('工作日')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tripType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _departureTime,
              decoration: const InputDecoration(labelText: '出发时间 (HH:MM)'),
              onChanged: (value) => _departureTime = value,
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
          onPressed: _submit,
          child: const Text('创建'),
        ),
      ],
    );
  }
}
