import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/theme/app_theme.dart';
import 'package:ride_hermes_passenger/router/app_router.dart';

class RideHermesApp extends ConsumerStatefulWidget {
  const RideHermesApp({super.key});

  @override
  ConsumerState<RideHermesApp> createState() => _RideHermesAppState();
}

class _RideHermesAppState extends ConsumerState<RideHermesApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final router = ref.watch(appRouterProvider);

    if (!authState.isInitialized) {
      return MaterialApp(
        title: 'RideHermes',
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'RideHermes',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
