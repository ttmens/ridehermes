import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/models/order.dart';
import 'package:ride_hermes_passenger/shared/utils/formatters.dart';
import 'package:ride_hermes_passenger/shared/widgets/status_badge.dart';
import 'package:ride_hermes_passenger/core/constants/order_status.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/orders/${widget.orderId}');

    if (!mounted) return;
    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() {
          _order = Order.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '订单不存在';
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

  String _carTypeText(int carType) {
    return switch (carType) {
      1 => '快车',
      2 => '专车',
      3 => '豪华车',
      _ => '未知',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('订单详情'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('订单详情'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.base),
              Text(_error ?? '订单不存在',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.base),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('订单详情 #${order.orderNo}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and order no
            _card(
              children: [
                StatusBadge(
                  text: OrderStatus.text(order.status),
                  color: OrderStatus.color(order.status),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(order.orderNo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            // Trip info
            _card(
              children: [
                const Text('行程信息',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const Divider(),
                _infoRow(Icons.trip_origin, '上车点', order.pickupAddr,
                    color: AppColors.info),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.location_on, '下车点', order.dropoffAddr,
                    color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.directions_car, '车型',
                    _carTypeText(order.carType)),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.straighten, '距离',
                    Formatters.formatDistance(order.estDistance)),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.timer_outlined, '预计时长',
                    Formatters.formatDuration(order.estDuration)),
                const SizedBox(height: AppSpacing.sm),
                _infoRow(Icons.attach_money, '预估费用',
                    Formatters.formatPrice(order.estPrice),
                    valueColor: AppColors.primary),
                if (order.actualPrice > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _infoRow(Icons.receipt, '实际费用',
                      Formatters.formatPrice(order.actualPrice)),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.base),

            // Departure time
            if (order.departureTime != null)
              _card(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.info),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '预约出发时间: ${order.departureTime!.month}/${order.departureTime!.day} '
                        '${order.departureTime!.hour.toString().padLeft(2, "0")}:'
                        '${order.departureTime!.minute.toString().padLeft(2, "0")}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            if (order.departureTime != null)
              const SizedBox(height: AppSpacing.base),

            // Driver info
            if (order.status >= 2 && order.driver != null)
              _card(
                children: [
                  const Text('司机信息',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const Divider(),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 20,
                        child: Text(
                          (order.driver!.nickname?.isNotEmpty == true
                                  ? order.driver!.nickname![0]
                                  : '司')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.driver!.nickname ?? '未知',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          if (order.driver!.rating != null)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 14, color: AppColors.warning),
                                Text(
                                    order.driver!.rating!
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (order.driver!.vehicle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _infoRow(Icons.local_taxi, '车辆',
                        '${order.driver!.vehicle!.brand} ${order.driver!.vehicle!.model}  '
                        '${order.driver!.vehicle!.color} '
                        '${order.driver!.vehicle!.plateNumber}'),
                  ],
                ],
              ),
            if (order.status >= 2 && order.driver != null)
              const SizedBox(height: AppSpacing.base),

            // Time info
            _card(
              children: [
                const Text('时间信息',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const Divider(),
                if (order.createdAt != null)
                  _infoRow(Icons.add_circle_outline, '创建时间',
                      order.createdAt!),
                if (order.acceptedAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.check_circle_outline, '接单时间',
                      order.acceptedAt!),
                ],
                if (order.startedAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.play_circle_outline, '开始时间',
                      order.startedAt!),
                ],
                if (order.endedAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.stop_circle, '结束时间', order.endedAt!),
                ],
                if (order.cancelledAt != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _infoRow(Icons.cancel_outlined, '取消时间',
                      order.cancelledAt!),
                  if (order.cancelReason.isNotEmpty)
                    _infoRow(Icons.info_outline, '取消原因',
                        order.cancelReason),
                ],
              ],
            ),

            // Track button for active orders
            if (order.status >= 2 && order.status <= 6) ...[
              const SizedBox(height: AppSpacing.base),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/trip/${order.id}'),
                  icon: const Icon(Icons.map),
                  label: const Text('查看行程'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? color, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textHint),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor)),
        ),
      ],
    );
  }
}
