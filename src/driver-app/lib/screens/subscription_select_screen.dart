import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';

class SubscriptionSelectScreen extends ConsumerStatefulWidget {
  const SubscriptionSelectScreen({super.key});

  @override
  ConsumerState<SubscriptionSelectScreen> createState() =>
      _SubscriptionSelectScreenState();
}

class _SubscriptionSelectScreenState
    extends ConsumerState<SubscriptionSelectScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择订阅套餐'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.plans.isEmpty
              ? const Center(child: Text('暂无可用套餐'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.plans.length,
                  itemBuilder: (context, index) {
                    final plan = state.plans[index];
                    return _buildPlanCard(plan);
                  },
                ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isRecommended = plan.type == 2; // Pro套餐推荐

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRecommended ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '推荐',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¥${plan.monthlyFee}/月',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '流水抽成 ${plan.revenueRate * 100}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '套餐权益',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...plan.benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _subscribe(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '立即订阅',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认订阅'),
        content: Text(
          '您即将订阅 ${plan.name} 套餐\n\n'
          '月费：¥${plan.monthlyFee}\n'
          '流水抽成：${plan.revenueRate * 100}%\n\n'
          '订阅后立即生效，可随时取消。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认订阅'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(subscriptionProvider.notifier)
          .subscribe(plan.type);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订阅成功！'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/driver/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订阅失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
