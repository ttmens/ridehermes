import 'package:flutter/material.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/models/order.dart';

/// Operation tile used in the dashboard grid.
class OpTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? value;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onTap;

  const OpTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.iconSize = 36,
    this.fontSize = 15,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: iconSize, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (value != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                value!,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom panel showing pending orders that need driver confirmation.
class PendingOrdersPanel extends StatelessWidget {
  final List<Order> orders;
  final void Function(int orderId) onAccept;
  final void Function(int orderId) onReject;
  final void Function(int orderId) onTap;

  const PendingOrdersPanel({
    super.key,
    required this.orders,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.15), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '待确认订单 (${orders.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...orders.take(3).map((order) => _PendingOrderCard(
                order: order,
                onAccept: () => onAccept(order.id),
                onReject: () => onReject(order.id),
                onTap: () => onTap(order.id),
              )),
        ],
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _PendingOrderCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final departureStr = order.departureTime != null
        ? '${order.departureTime!.month}/${order.departureTime!.day} ${order.departureTime!.hour.toString().padLeft(2, '0')}:${order.departureTime!.minute.toString().padLeft(2, '0')}'
        : '未指定';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '出发: $departureStr',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '¥${order.estPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.info),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    order.pickupAddr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    order.dropoffAddr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('接单', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 40),
                    ),
                    child: const Text('拒绝', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar showing the current active order.
class CurrentOrderBar extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const CurrentOrderBar({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity( 0.15), blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity( 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.directions_car, color: AppColors.info, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '进行中: ${order.statusText}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${order.pickupAddr} → ${order.dropoffAddr}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
