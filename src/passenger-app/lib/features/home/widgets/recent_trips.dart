import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_passenger/models/order.dart';
import 'package:ride_hermes_passenger/providers/order_provider.dart';

class RecentTrips extends ConsumerStatefulWidget {
  const RecentTrips({super.key});

  @override
  ConsumerState<RecentTrips> createState() => _RecentTripsState();
}

class _RecentTripsState extends ConsumerState<RecentTrips> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (_initialized) return;
      _initialized = true;
      ref.read(orderProvider.notifier).fetchOrders(limit: 3);
    });
  }

  String _statusLabel(Order o) {
    switch (o.status) {
      case 1:
        return '待派单';
      case 2:
        return '已派单';
      case 3:
        return '已接单';
      case 5:
        return '已到达';
      case 6:
        return '行程中';
      case 7:
        return '已完成';
      case 8:
        return '已取消';
      default:
        return '未知';
    }
  }

  Color _statusColor(Order o) {
    switch (o.status) {
      case 7:
        return Colors.green;
      case 8:
        return Colors.grey;
      case 6:
        return Colors.blue;
      case 3:
      case 5:
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  String _priceLabel(Order o) {
    final p = o.actualPrice > 0 ? o.actualPrice : o.estPrice;
    if (p <= 0) return '--';
    return '¥${p.toStringAsFixed(2)}';
  }

  String _timeLabel(Order o) {
    final t = o.endedAt ?? o.startedAt ?? o.acceptedAt ?? o.createdAt;
    if (t == null || t.isEmpty) return '';
    try {
      final dt = DateTime.parse(t).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
      if (diff.inHours < 24) return '${diff.inHours} 小时前';
      if (diff.inDays < 7) return '${diff.inDays} 天前';
      return '${dt.month}-${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final trips = state.orders.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
              child: Row(
                children: [
                  const Text(
                    '最近行程',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.push('/orders'),
                    child: const Text('查看全部', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            if (state.isLoading && trips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (trips.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey[400], size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '暂无行程，去安排一次吧',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ...trips.asMap().entries.map((entry) {
                final idx = entry.key;
                final o = entry.value;
                return InkWell(
                  onTap: () => context.push('/order/${o.id}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: idx < trips.length - 1
                          ? Border(top: BorderSide(color: Colors.grey[200]!))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.directions_car, color: primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      o.pickupAddr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey[400]),
                                  ),
                                  Flexible(
                                    child: Text(
                                      o.dropoffAddr,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(o).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _statusLabel(o),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _statusColor(o),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _timeLabel(o),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _priceLabel(o),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
