import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/models/order.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(driverOrderProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOrderProvider);
    final orders = state.orders;

    return Scaffold(
      appBar: AppBar(title: const Text('订单列表')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(driverOrderProvider.notifier).fetchOrders(),
        child: orders.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: AppColors.textHint),
                        SizedBox(height: AppSpacing.base),
                        Text(
                          '暂无订单记录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          '完成订单后将在这里显示',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final o = orders[i];
                  return _OrderTile(order: o);
                },
              ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _statusColor(order.status).withOpacity(0.15),
        child: Icon(_statusIcon(order.status), color: _statusColor(order.status), size: 20),
      ),
      title: Text(
        '${order.pickupAddr} → ${order.dropoffAddr}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '¥${order.estPrice.toStringAsFixed(2)} | ${order.statusText}',
        style: TextStyle(color: _statusColor(order.status)),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/orders/${order.id}'),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 3:
      case 4:
      case 5:
      case 6:
        return AppColors.warning;
      case 7:
        return AppColors.success;
      case 8:
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  IconData _statusIcon(int status) {
    switch (status) {
      case 3:
      case 4:
      case 5:
      case 6:
        return Icons.directions_car;
      case 7:
        return Icons.check_circle_outline;
      case 8:
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }
}
