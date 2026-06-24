import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _ServiceItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
}

class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    final items = [
      _ServiceItem(
        icon: Icons.directions_car,
        label: '立即叫车',
        sub: '最快 3 分钟',
        color: primary,
        onTap: () => context.push('/schedule-trip'),
      ),
      _ServiceItem(
        icon: Icons.airport_shuttle,
        label: '机场接送',
        sub: '预约不误点',
        color: Colors.orange,
        onTap: () => context.push('/schedule-trip'),
      ),
      _ServiceItem(
        icon: Icons.groups,
        label: '多人出行',
        sub: '6/7 座可选',
        color: Colors.purple,
        onTap: () => context.push('/schedule-trip'),
      ),
      _ServiceItem(
        icon: Icons.event_available,
        label: '预约用车',
        sub: '7 天内可订',
        color: secondary,
        onTap: () => context.push('/schedule-trip'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: items.map((it) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: it.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: it.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(it.icon, color: it.color, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          it.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          it.sub,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
