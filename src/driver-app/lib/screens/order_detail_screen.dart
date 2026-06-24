import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(driverOrderProvider);
    final order = orderState.orders.where((o) => o.id == orderId).firstOrNull;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: const Center(child: Text('未找到订单')),
      );
    }

    String carTypeText(int type) {
      switch (type) {
        case 1: return '快车';
        case 2: return '专车';
        case 3: return '豪华车';
        default: return '未知';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('订单 #${order.orderNo}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          _Section(title: '订单信息', children: [
            _RowItem(label: '订单号', value: order.orderNo),
            _RowItem(label: '状态', value: order.statusText),
            _RowItem(label: '车型', value: carTypeText(order.carType)),
            _RowItem(label: '预约出发时间', value: order.departureTime != null
                ? '${order.departureTime!.year}-${order.departureTime!.month.toString().padLeft(2, '0')}-${order.departureTime!.day.toString().padLeft(2, '0')} ${order.departureTime!.hour.toString().padLeft(2, '0')}:${order.departureTime!.minute.toString().padLeft(2, '0')}'
                : '未指定'),
            _RowItem(label: '预估费用', value: '¥${order.estPrice.toStringAsFixed(2)}'),
            _RowItem(label: '预估距离', value: '${(order.estDistance / 1000).toStringAsFixed(1)}km'),
            _RowItem(label: '预估时长', value: '${order.estDuration}分钟'),
          ]),
          const SizedBox(height: AppSpacing.base),
          _Section(title: '地址信息', children: [
            _RowItem(label: '上车点', value: order.pickupAddr),
            _RowItem(label: '下车点', value: order.dropoffAddr),
          ]),
          if (order.passenger != null) ...[
            const SizedBox(height: AppSpacing.base),
            _Section(title: '乘客信息', children: [
              _RowItem(label: '昵称', value: order.passenger!.nickname),
              _RowItem(label: '手机号', value: order.passenger!.phone),
            ]),
          ],
          if (order.canAccept) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: orderState.isLoading
                        ? null
                        : () => _onAccept(context, ref, order.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('接单', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: orderState.isLoading
                        ? null
                        : () => _onReject(context, ref, order.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text('拒绝', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _onAccept(BuildContext context, WidgetRef ref, int orderId) async {
  final notifier = ref.read(driverOrderProvider.notifier);
  await notifier.acceptOrder(orderId);
  if (context.mounted) {
    final state = ref.read(driverOrderProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    } else {
      context.pop();
    }
  }
}

Future<void> _onReject(BuildContext context, WidgetRef ref, int orderId) async {
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
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('拒绝'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final notifier = ref.read(driverOrderProvider.notifier);
  await notifier.rejectOrder(orderId);
  if (context.mounted) {
    final state = ref.read(driverOrderProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    } else {
      context.pop();
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;

  const _RowItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
