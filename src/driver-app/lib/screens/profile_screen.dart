import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Avatar + name
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              (user?.nickname ?? 'D')[0].toUpperCase(),
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            user?.nickname ?? '司机',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Stats row
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: '总订单', value: '0'),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  _StatItem(label: '评分', value: '5.0'),
                  Container(width: 1, height: 32, color: AppColors.divider),
                  _StatItem(label: '服务天数', value: '1'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Vehicle info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '车辆信息',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(),
                  _InfoRow(label: '车牌号', value: '京A00001'),
                  const Divider(height: 1),
                  _InfoRow(label: '车型', value: '丰田·卡罗拉'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.base),

          // Account info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '账号信息',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(),
                  _InfoRow(label: '手机号', value: user?.phone ?? '-'),
                  const Divider(height: 1),
                  _InfoRow(label: '角色', value: '司机'),
                  const Divider(height: 1),
                  _InfoRow(label: '账号状态', value: '正常'),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Logout button
          OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('退出登录', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
