import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/auth_provider.dart';
import 'package:ride_hermes_driver/screens/agent_config_screen.dart';
import 'package:ride_hermes_driver/screens/driver_shell.dart';
import 'package:ride_hermes_driver/screens/dashboard_screen.dart';
import 'package:ride_hermes_driver/screens/login_screen.dart';
import 'package:ride_hermes_driver/screens/order_detail_screen.dart';
import 'package:ride_hermes_driver/screens/orders_screen.dart';
import 'package:ride_hermes_driver/screens/profile_screen.dart';
import 'package:ride_hermes_driver/screens/trust_score_screen.dart';
import 'package:ride_hermes_driver/screens/trip_screen.dart';
import 'package:ride_hermes_driver/screens/subscription_select_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (!authState.isInitialized) {
        return '/splash';
      }

      final isLoggedIn = authState.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/splash';

      if (isSplashRoute) {
        return isLoggedIn ? '/dashboard' : '/login';
      }
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_taxi, size: 80, color: AppColors.primary),
                const SizedBox(height: AppSpacing.base),
                const Text(
                  'RideHermes Driver',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const CircularProgressIndicator(color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/agent-config',
            builder: (context, state) => const AgentConfigScreen(),
          ),
          GoRoute(
            path: '/trust-score',
            builder: (context, state) => const TrustScoreScreen(),
          ),
          GoRoute(
            path: '/subscription-select',
            builder: (context, state) => const SubscriptionSelectScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/trip/:orderId',
        builder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          return TripScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return OrderDetailScreen(orderId: id);
        },
      ),
    ],
  );
});
