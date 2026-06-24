import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_passenger/models/ai_chat.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/providers/ai_chat_provider.dart';
import 'package:ride_hermes_passenger/shared/utils/formatters.dart';

class RideConfirmCard extends ConsumerStatefulWidget {
  final RideIntent intent;
  final OrderPreview? preview;

  const RideConfirmCard({
    super.key,
    required this.intent,
    this.preview,
  });

  @override
  ConsumerState<RideConfirmCard> createState() => _RideConfirmCardState();
}

class _RideConfirmCardState extends ConsumerState<RideConfirmCard> {
  bool _isSubmitting = false;
  DateTime? _selectedDepartureTime;

  @override
  void initState() {
    super.initState();
    final dt = widget.intent.departureTime;
    if (dt != null && dt.isNotEmpty) {
      _selectedDepartureTime = DateTime.tryParse(dt);
    }
  }

  Future<void> _pickDepartureTime() async {
    final now = DateTime.now();
    final initial = _selectedDepartureTime ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDepartureTime ?? now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDepartureTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _onConfirm() async {
    setState(() => _isSubmitting = true);

    final pickup = widget.intent.pickup!;
    final dropoff = widget.intent.dropoff!;
    final departureTime = _selectedDepartureTime?.toIso8601String();
    final sessionId = ref.read(aiChatProvider).sessionId;

    final api = ref.read(apiServiceProvider);
    final result = await api.post('/api/v1/passenger/orders', data: {
      'pickup_addr': pickup.address,
      'pickup_lat': pickup.lat ?? 0,
      'pickup_lng': pickup.lng ?? 0,
      'dropoff_addr': dropoff.address,
      'dropoff_lat': dropoff.lat ?? 0,
      'dropoff_lng': dropoff.lng ?? 0,
      'car_type': widget.intent.carType ?? 1,
      'departure_time': departureTime ?? DateTime.now().toIso8601String(),
      'session_id': sessionId,
    });

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      final orderId = data?['id'];
      if (orderId != null) {
        ref.read(aiChatProvider.notifier).replaceLastRideConfirm(
              '已为您叫车成功！订单编号: ${data?['order_no'] ?? orderId}',
            );
        context.push('/trip/$orderId');
        return;
      }
    }

    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '创建订单失败，请重试')),
      );
    }
  }

  void _onDismiss() {
    ref.read(aiChatProvider.notifier).replaceLastRideConfirm(
          '好的，您可以继续调整行程信息。',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.preview;
    final pickup = widget.intent.pickup!;
    final dropoff = widget.intent.dropoff!;
    final carType = widget.intent.carType ?? 1;
    final carName = {1: '快车', 2: '专车', 3: '豪华车'}[carType] ?? '快车';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_taxi, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '确认行程',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(carName,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 14),

          // Pickup
          _AddressRow(
            icon: Icons.trip_origin,
            color: Colors.green,
            label: '上车点',
            address: pickup.address,
          ),
          const SizedBox(height: 8),
          // Dropoff
          _AddressRow(
            icon: Icons.location_on,
            color: Colors.red,
            label: '下车点',
            address: dropoff.address,
          ),

          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDepartureTime,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 18, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Text('出发时间: ',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey)),
                  Text(
                    _selectedDepartureTime != null
                        ? _formatDeparture(_selectedDepartureTime!)
                        : '现在出发',
                    style: TextStyle(
                      fontSize: 13,
                      color: _selectedDepartureTime != null
                          ? Colors.teal
                          : Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit, size: 14, color: Colors.blueGrey),
                ],
              ),
            ),
          ),

          if (preview != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                    icon: Icons.payments_outlined,
                    label: Formatters.formatPrice(preview.estPrice)),
                _InfoItem(
                    icon: Icons.route_outlined,
                    label: Formatters.formatDistance(preview.estDistance)),
                _InfoItem(
                    icon: Icons.timer_outlined,
                    label: Formatters.formatDuration(preview.estDuration)),
              ],
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('确认叫车', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isSubmitting ? null : _onDismiss,
              child: const Text('暂不叫车，继续对话',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeparture(DateTime dt) {
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(address,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
