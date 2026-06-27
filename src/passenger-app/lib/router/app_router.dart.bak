import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/features/home/home_screen.dart';
import 'package:ride_hermes_passenger/features/login/login_screen.dart';
import 'package:ride_hermes_passenger/features/order_confirm/order_confirm_screen.dart';
import 'package:ride_hermes_passenger/features/trip_tracking/trip_tracking_screen.dart';
import 'package:ride_hermes_passenger/features/order_list/order_list_screen.dart';
import 'package:ride_hermes_passenger/features/order_detail/order_detail_screen.dart';
import 'package:ride_hermes_passenger/features/profile/profile_screen.dart';
import 'package:ride_hermes_passenger/features/schedule_trip/schedule_trip_screen.dart';
import 'package:ride_hermes_passenger/features/home/ai_chat_screen.dart';
import 'package:ride_hermes_passenger/features/agent_auth/agent_auth_screen.dart';
import 'package:ride_hermes_passenger/screens/plan_trip_screen.dart';
import 'package:ride_hermes_passenger/screens/recurring_trips_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/ai-chat',
        builder: (context, state) => const AIChatScreen(),
      ),
      GoRoute(
        path: '/order-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OrderConfirmScreen(orderPreview: extra);
        },
      ),
      GoRoute(
        path: '/trip/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return TripTrackingScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/schedule-trip',
        builder: (context, state) => const ScheduleTripScreen(),
      ),
      GoRoute(
        path: '/plan-trip',
        builder: (context, state) => const PlanTripScreen(),
      ),
      GoRoute(
        path: '/recurring-trips',
        builder: (context, state) => const RecurringTripsScreen(),
      ),
      GoRoute(
        path: '/agent-auth',
        builder: (context, state) => const AgentAuthScreen(),
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/orders');
            case 2:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '订单'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}
