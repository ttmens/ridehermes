import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/models/order.dart';
import 'package:ride_hermes_passenger/core/constants/order_status.dart';
import 'package:ride_hermes_passenger/shared/widgets/status_badge.dart';
import 'package:ride_hermes_passenger/shared/widgets/empty_state.dart';
import 'package:ride_hermes_passenger/shared/widgets/error_view.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/orders',
        params: {'offset': 0, 'limit': 50});

    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        final list = (data['list'] as List?)
                ?.map((o) => Order.fromJson(o as Map<String, dynamic>))
                .toList() ??
            [];
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = result.message ?? '加载失败';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _fetchOrders)
              : _orders.isEmpty
                  ? const EmptyState(
                      message: '暂无订单',
                      icon: Icons.inbox,
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.base),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNo,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  StatusBadge(
                    text: OrderStatus.text(order.status),
                    color: OrderStatus.color(order.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.trip_origin,
                      size: 14, color: AppColors.info),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(order.pickupAddr,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.error),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(order.dropoffAddr,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '¥${order.estPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (order.createdAt != null)
                    Text(
                      order.createdAt!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
