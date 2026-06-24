import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class GreetingBar extends ConsumerWidget {
  const GreetingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final greeting = _getGreeting();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            radius: 24,
            child: Text(
              user?.nickname.isNotEmpty == true
                  ? user!.nickname[0]
                  : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting，${user?.nickname ?? '用户'}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  '温暖出行，安全到家',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }
}
