import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/agent_provider.dart';

/// 撮合邀请数据模型
class MatchingInvitation {
  final int id;
  final String orderNo;
  final String pickupAddr;
  final String dropoffAddr;
  final double estPrice;
  final double distance; // km
  final int estDuration; // 分钟
  final String passengerName;
  final double passengerRating;
  final DateTime createdAt;
  final int? expireSeconds; // 倒计时秒数

  const MatchingInvitation({
    required this.id,
    required this.orderNo,
    required this.pickupAddr,
    required this.dropoffAddr,
    required this.estPrice,
    required this.distance,
    required this.estDuration,
    required this.passengerName,
    required this.passengerRating,
    required this.createdAt,
    this.expireSeconds,
  });

  factory MatchingInvitation.fromJson(Map<String, dynamic> json) {
    return MatchingInvitation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderNo: json['order_no'] as String? ?? '',
      pickupAddr: json['pickup_addr'] as String? ?? '',
      dropoffAddr: json['dropoff_addr'] as String? ?? '',
      estPrice: (json['est_price'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      estDuration: (json['est_duration'] as num?)?.toInt() ?? 0,
      passengerName: json['passenger_name'] as String? ?? '',
      passengerRating: (json['passenger_rating'] as num?)?.toDouble() ?? 5.0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      expireSeconds: (json['expire_seconds'] as num?)?.toInt(),
    );
  }
}

/// 撮合邀请弹窗：接受 / 拒绝 / 还价
class MatchingInvitationDialog extends ConsumerStatefulWidget {
  final MatchingInvitation invitation;

  const MatchingInvitationDialog({super.key, required this.invitation});

  /// 显示弹窗并返回操作结果
  static Future<MatchingDialogResult?> show(
    BuildContext context, {
    required MatchingInvitation invitation,
  }) {
    return showDialog<MatchingDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MatchingInvitationDialog(invitation: invitation),
    );
  }

  @override
  ConsumerState<MatchingInvitationDialog> createState() =>
      _MatchingInvitationDialogState();
}

/// 弹窗操作结果
class MatchingDialogResult {
  final MatchingDialogAction action;
  final double? counterPrice;

  const MatchingDialogResult({required this.action, this.counterPrice});
}

enum MatchingDialogAction { accept, reject, counterOffer, timeout }

class _MatchingInvitationDialogState extends ConsumerState<MatchingInvitationDialog> {
  bool _isProcessing = false;
  bool _showCounterOffer = false;
  late double _counterPrice;
  int _remainingSeconds;
  bool _expired = false;

  static const _defaultExpire = 30; // 默认30秒

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.invitation.expireSeconds ?? _defaultExpire;
    _counterPrice = widget.invitation.estPrice * 1.2; // 默认还价 +20%
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _expired || _isProcessing) return false;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _expired = true;
          Navigator.of(context).pop(
            const MatchingDialogResult(action: MatchingDialogAction.timeout),
          );
          return false;
        }
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部标题栏 + 倒计时
            _buildHeader(),
            // 订单信息
            _buildOrderInfo(inv),
            // 乘客信息
            _buildPassengerInfo(inv),
            // 还价区域
            if (_showCounterOffer) _buildCounterOfferSection(inv),
            // 操作按钮
            if (!_showCounterOffer) _buildActionButtons(inv),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isUrgent = _remainingSeconds <= 10;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [AppColors.error.withOpacity(0.1), AppColors.warning.withOpacity(0.05)]
              : [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent 撮合邀请',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '根据您的偏好为您匹配',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // 倒计时
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: isUrgent ? AppColors.error.withOpacity(0.1) : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: isUrgent ? AppColors.error.withOpacity(0.3) : AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: isUrgent ? AppColors.error : AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_remainingSeconds}s',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? AppColors.error : AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(MatchingInvitation inv) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 起点
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    inv.pickupAddr,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 连线
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(
                width: 2,
                height: 16,
                color: AppColors.divider,
              ),
            ),
            // 终点
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    inv.dropoffAddr,
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            // 订单详情
            Row(
              children: [
                _InfoChip(
                  icon: Icons.route,
                  label: '${inv.distance.toStringAsFixed(1)}km',
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  icon: Icons.access_time,
                  label: '${inv.estDuration}分钟',
                  color: AppColors.warning,
                ),
                const Spacer(),
                Text(
                  '¥${inv.estPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerInfo(MatchingInvitation inv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              inv.passengerName.isNotEmpty ? inv.passengerName[0] : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.passengerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      inv.passengerRating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.verified_user, size: 12, color: AppColors.success),
                    const SizedBox(width: 2),
                    const Text(
                      '已认证',
                      style: TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '订单号: ${inv.orderNo}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferSection(MatchingInvitation inv) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '您的还价',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Text('¥', style: TextStyle(fontSize: 24, color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '0.0',
                    hintStyle: TextStyle(fontSize: 28, color: AppColors.textHint),
                  ),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) _counterPrice = parsed;
                  },
                  controller: TextEditingController(text: _counterPrice.toStringAsFixed(0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '原价 ¥${inv.estPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              // 快捷加价按钮
              ...[1.1, 1.2, 1.5].map((mult) {
                final price = inv.estPrice * mult;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text('+${((mult - 1) * 100).toInt()}%'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    onPressed: () {
                      setState(() => _counterPrice = price);
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : () => setState(() => _showCounterOffer = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('返回'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : () => _submitCounterOffer(inv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('还价 ¥${_counterPrice.toStringAsFixed(0)}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MatchingInvitation inv) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // 拒绝
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => _reject(inv),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('拒绝', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 还价
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () => setState(() => _showCounterOffer = true),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                minimumSize: const Size(0, 48),
              ),
              child: const Text('还价', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 接受
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _accept(inv),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('接受', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(MatchingInvitation inv) async {
    setState(() => _isProcessing = true);
    final ok = await ref.read(agentConfigProvider.notifier).acceptInvitation(inv.id);
    if (!mounted) return;
    Navigator.of(context).pop(MatchingDialogResult(action: MatchingDialogAction.accept));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('接受失败，请重试'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _reject(MatchingInvitation inv) async {
    setState(() => _isProcessing = true);
    final ok = await ref.read(agentConfigProvider.notifier).rejectInvitation(inv.id);
    if (!mounted) return;
    Navigator.of(context).pop(MatchingDialogResult(action: MatchingDialogAction.reject));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('拒绝失败，请重试'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _submitCounterOffer(MatchingInvitation inv) async {
    setState(() => _isProcessing = true);
    final ok = await ref.read(agentConfigProvider.notifier).counterOffer(inv.id, _counterPrice);
    if (!mounted) return;
    Navigator.of(context).pop(
      MatchingDialogResult(action: MatchingDialogAction.counterOffer, counterPrice: _counterPrice),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('还价失败，请重试'), backgroundColor: AppColors.error),
      );
    }
  }
}

/// 信息小标签
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
