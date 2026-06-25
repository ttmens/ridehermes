import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/agent_provider.dart';

/// Agent 配置面板：接单偏好 / 定价策略 / 在线时间
class AgentConfigScreen extends ConsumerStatefulWidget {
  const AgentConfigScreen({super.key});

  @override
  ConsumerState<AgentConfigScreen> createState() => _AgentConfigScreenState();
}

class _AgentConfigScreenState extends ConsumerState<AgentConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _carTypeLabels = {1: '经济型', 2: '舒适型', 3: '商务型'};
  static const _dayLabels = {
    1: '周一',
    2: '周二',
    3: '周三',
    4: '周四',
    5: '周五',
    6: '周六',
    7: '周日',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(agentConfigProvider.notifier).loadConfig();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentConfigProvider);
    final notifier = ref.read(agentConfigProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('我的Agent', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '接单偏好'),
            Tab(text: '定价策略'),
            Tab(text: '在线时间'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPreferencesTab(state, notifier),
                _buildPricingTab(state, notifier),
                _buildScheduleTab(state, notifier),
              ],
            ),
    );
  }

  // ─── 接单偏好 Tab ───────────────────────────────────────────────
  Widget _buildPreferencesTab(AgentConfigState state, AgentConfigNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 信誉分卡片
          _ReputationCard(state: state),
          const SizedBox(height: AppSpacing.lg),

          // 最大接单距离
          _SectionCard(
            title: '最大接单距离',
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${state.maxDistanceKm} 公里',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: state.maxDistanceKm.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  activeColor: AppColors.primary,
                  label: '${state.maxDistanceKm}km',
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(maxDistanceKm: v.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1km', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('50km', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 最低每公里价格
          _SectionCard(
            title: '最低每公里价格',
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '¥${state.minPricePerKm.toStringAsFixed(1)}/km',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: state.minPricePerKm,
                  min: 1.0,
                  max: 10.0,
                  divisions: 18,
                  activeColor: AppColors.primary,
                  label: '¥${state.minPricePerKm.toStringAsFixed(1)}',
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(minPricePerKm: double.parse(v.toStringAsFixed(1)));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('¥1.0', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('¥10.0', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 接受车型
          _SectionCard(
            title: '接受车型',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _carTypeLabels.entries.map((entry) {
                final selected = state.acceptedCarTypes.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (v) {
                    final types = List<int>.from(state.acceptedCarTypes);
                    if (v) {
                      types.add(entry.key);
                    } else {
                      types.remove(entry.key);
                    }
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(acceptedCarTypes: types);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // 开关选项
          _SectionCard(
            title: '其他偏好',
            child: Column(
              children: [
                _SwitchTile(
                  title: '接受预约单',
                  subtitle: '允许接收提前预约的订单',
                  value: state.acceptScheduledOrders,
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(acceptScheduledOrders: v);
                  },
                ),
                const Divider(height: 1),
                _SwitchTile(
                  title: '接受长途单',
                  subtitle: '允许接收超过30公里的长途订单',
                  value: state.acceptLongDistance,
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(acceptLongDistance: v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 保存按钮
          _SaveButton(
            label: '保存接单偏好',
            onPressed: () async {
              final ok = await notifier.savePreferences();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '偏好已保存' : '保存失败: ${state.error ?? ""}'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ─── 定价策略 Tab ───────────────────────────────────────────────
  Widget _buildPricingTab(AgentConfigState state, AgentConfigNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '基础价格倍率',
            subtitle: '调整基础价格的接受倍率',
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${state.basePriceMultiplier.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      state.basePriceMultiplier > 1.0
                          ? '加价${((state.basePriceMultiplier - 1) * 100).toInt()}%'
                          : state.basePriceMultiplier < 1.0
                              ? '降价${((1 - state.basePriceMultiplier) * 100).toInt()}%'
                              : '标准价格',
                      style: TextStyle(
                        fontSize: 13,
                        color: state.basePriceMultiplier > 1.0
                            ? AppColors.warning
                            : state.basePriceMultiplier < 1.0
                                ? AppColors.info
                                : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: state.basePriceMultiplier,
                  min: 0.8,
                  max: 2.0,
                  divisions: 24,
                  activeColor: AppColors.primary,
                  label: '${state.basePriceMultiplier.toStringAsFixed(1)}x',
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(basePriceMultiplier: double.parse(v.toStringAsFixed(1)));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0.8x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('2.0x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          _SectionCard(
            title: '高峰时段加价',
            subtitle: '早晚高峰期间的加价倍率',
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${state.peakHourMultiplier.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: state.peakHourMultiplier,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  activeColor: AppColors.warning,
                  label: '${state.peakHourMultiplier.toStringAsFixed(1)}x',
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(peakHourMultiplier: double.parse(v.toStringAsFixed(1)));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1.0x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('3.0x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          _SectionCard(
            title: '夜间加价',
            subtitle: '22:00 - 06:00 夜间时段加价',
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.nightlight_round, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${state.nightMultiplier.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Slider(
                  value: state.nightMultiplier,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  activeColor: AppColors.info,
                  label: '${state.nightMultiplier.toStringAsFixed(1)}x',
                  onChanged: (v) {
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(nightMultiplier: double.parse(v.toStringAsFixed(1)));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('1.0x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                    Text('3.0x', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          _SectionCard(
            title: '自动还价',
            child: _SwitchTile(
              title: '启用自动还价',
              subtitle: 'Agent 自动根据策略对低价订单还价',
              value: state.autoCounterOffer,
              onChanged: (v) {
                ref.read(agentConfigProvider.notifier).state =
                    state.copyWith(autoCounterOffer: v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _SaveButton(
            label: '保存定价策略',
            onPressed: () async {
              final ok = await notifier.savePricing();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '定价策略已保存' : '保存失败: ${state.error ?? ""}'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ─── 在线时间 Tab ───────────────────────────────────────────────
  Widget _buildScheduleTab(AgentConfigState state, AgentConfigNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: '工作时间',
            child: Column(
              children: [
                // 上班时间
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm, color: AppColors.success, size: 24),
                  title: const Text('上班时间'),
                  subtitle: Text(
                    state.workStart?.formatted ?? '未设置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: state.workStart != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, color: AppColors.textHint),
                  onTap: () => _pickTime(isStart: true),
                ),
                const Divider(height: 1),
                // 下班时间
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm_off, color: AppColors.error, size: 24),
                  title: const Text('下班时间'),
                  subtitle: Text(
                    state.workEnd?.formatted ?? '未设置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: state.workEnd != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, color: AppColors.textHint),
                  onTap: () => _pickTime(isStart: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          _SectionCard(
            title: '工作日',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _dayLabels.entries.map((entry) {
                final selected = state.workDays.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (v) {
                    final days = List<int>.from(state.workDays);
                    if (v) {
                      days.add(entry.key);
                    } else {
                      days.remove(entry.key);
                    }
                    ref.read(agentConfigProvider.notifier).state =
                        state.copyWith(workDays: days);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          _SectionCard(
            title: '自动上线',
            child: _SwitchTile(
              title: '工作时间自动上线',
              subtitle: '到达上班时间后自动切换为在线状态',
              value: state.autoOnline,
              onChanged: (v) {
                ref.read(agentConfigProvider.notifier).state =
                    state.copyWith(autoOnline: v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _SaveButton(
            label: '保存在线时间',
            onPressed: () async {
              final ok = await notifier.saveSchedule();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '在线时间已保存' : '保存失败: ${state.error ?? ""}'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _pickTime({required bool isStart}) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (ref.read(agentConfigProvider).workStart != null
              ? TimeOfDay(
                  hour: ref.read(agentConfigProvider).workStart!.hour,
                  minute: ref.read(agentConfigProvider).workStart!.minute,
                )
              : const TimeOfDay(hour: 8, minute: 0))
          : (ref.read(agentConfigProvider).workEnd != null
              ? TimeOfDay(
                  hour: ref.read(agentConfigProvider).workEnd!.hour,
                  minute: ref.read(agentConfigProvider).workEnd!.minute,
                )
              : const TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final td = AgentTime(hour: picked.hour, minute: picked.minute);
      if (isStart) {
        ref.read(agentConfigProvider.notifier).state =
            ref.read(agentConfigProvider).copyWith(workStart: td);
      } else {
        ref.read(agentConfigProvider.notifier).state =
            ref.read(agentConfigProvider).copyWith(workEnd: td);
      }
    }
  }
}

// ─── 信誉分卡片 ───────────────────────────────────────────────────
class _ReputationCard extends StatelessWidget {
  final AgentConfigState state;
  const _ReputationCard({required this.state});

  Color get _scoreColor {
    if (state.reputationScore >= 90) return AppColors.success;
    if (state.reputationScore >= 70) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreLevel {
    if (state.reputationScore >= 90) return '优秀';
    if (state.reputationScore >= 70) return '良好';
    if (state.reputationScore >= 50) return '一般';
    return '待提升';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_scoreColor.withOpacity(0.1), _scoreColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scoreColor.withOpacity(0.15),
                ),
                child: Center(
                  child: Text(
                    '${state.reputationScore}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '信誉分 · $_scoreLevel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _scoreColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '总订单 ${state.totalOrders} · 完单率 ${(state.completionRate * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified, color: _scoreColor, size: 28),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: state.reputationScore / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(_scoreColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('接单 ${state.acceptCount}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('拒单 ${state.rejectCount}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 通用组件 ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SaveButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
