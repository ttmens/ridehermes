import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';
import 'package:ride_hermes_passenger/shared/widgets/avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final nickname = user?.nickname;
    final initials =
        (nickname != null && nickname.isNotEmpty) ? nickname[0] : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('个人信息')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AvatarWidget(
              initials: initials,
              radius: 50,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              user?.nickname ?? '未知用户',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user?.phone ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _settingItem(Icons.person, '个人信息'),
            _settingItem(Icons.smart_toy, '智能体授权', onTap: () => context.push('/agent-auth')),
            _settingItem(Icons.settings, '行程偏好'),
            _settingItem(Icons.help_outline, '帮助与反馈'),
            _settingItem(Icons.info_outline, '关于我们'),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('退出登录'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('确定',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
