import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/order_provider.dart';

class DriverShell extends ConsumerWidget {
  final Widget child;

  const DriverShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final orderState = ref.watch(driverOrderProvider);
    final pendingCount = orderState.pendingOrders.length;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.drive_eta_outlined),
            selectedIcon: Icon(Icons.drive_eta),
            label: '工作台',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.list_alt_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              backgroundColor: AppColors.error,
              child: const Icon(Icons.list_alt),
            ),
            label: '订单',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location == '/orders') return 1;
    if (location == '/profile') return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
}
