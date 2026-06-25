import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/matching_provider.dart';
import 'package:ride_hermes_passenger/features/order_detail/order_detail_screen.dart';

/// 司机选择页面：展示撮合结果，乘客选择司机
class DriverSelectScreen extends ConsumerStatefulWidget {
  const DriverSelectScreen({super.key});

  @override
  ConsumerState<DriverSelectScreen> createState() => _DriverSelectScreenState();
}

class _DriverSelectScreenState extends ConsumerState<DriverSelectScreen> {
  @override
  void initState() {
    super.initState();
    // 开始轮询匹配结果
    Future.microtask(() {
      ref.read(matchingProvider.notifier).startPollingMatches();
    });
  }

  @override
  void dispose() {
    ref.read(matchingProvider.notifier).stopPollingMatches();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('选择司机'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(matchingProvider.notifier).refreshMatches();
            },
          ),
        ],
      ),
      body: state.isLoading && state.matches.isEmpty
          ? _buildLoadingView()
          : state.matches.isEmpty
              ? _buildEmptyView()
              : _buildMatchesList(state),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '正在匹配司机...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '已收到 ${ref.watch(matchingProvider).matches.length} 位司机响应',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          _buildMatchingTips(),
        ],
      ),
    );
  }

  Widget _buildMatchingTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              const Text(
                '温馨提示',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• 司机将根据您的偏好自主报价\n• 您可以查看司机信誉分和评价\n• 选择后司机将收到确认通知',
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无司机响应',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '请稍后刷新或调整出行偏好',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(matchingProvider.notifier).refreshMatches();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('刷新'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(MatchingState state) {
    return Column(
      children: [
        // 顶部状态栏
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 24),
              const SizedBox(width: 12),
              Text(
                '已为您匹配 ${state.matches.length} 位司机',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (state.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
        // 司机列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.matches.length,
            itemBuilder: (context, index) {
              final match = state.matches[index];
              return _buildDriverCard(match);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(MatchResult match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 司机基本信息
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    match.driverName.isNotEmpty
                        ? match.driverName[0]
                        : '司',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            match.driverName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTrustScoreBadge(match),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        match.carModel,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '¥${match.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '预估费用',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // 评价摘要
            if (match.recentReviews.isNotEmpty) ...[
              const Text(
                '近期评价',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.recentReviews.take(3).map((review) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      review,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // 留言
            if (match.message.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // 选择按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _confirmDriver(match),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '选择此司机',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 信誉分徽章（可点击，弹出信誉分详情）
  Widget _buildTrustScoreBadge(MatchResult match) {
    final score = match.trustScore;
    Color bgColor;
    Color textColor;

    if (score >= 4.5) {
      bgColor = AppColors.success.withOpacity(0.2);
      textColor = AppColors.success;
    } else if (score >= 4.0) {
      bgColor = AppColors.warning.withOpacity(0.2);
      textColor = AppColors.warning;
    } else {
      bgColor = AppColors.error.withOpacity(0.2);
      textColor = AppColors.error;
    }

    return GestureDetector(
      onTap: () => _showTrustScoreDetail(match),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出信誉分详情弹窗（4维度+评价摘要）
  void _showTrustScoreDetail(MatchResult match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  // 拖拽指示条
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 标题 + 总分
                  Row(
                    children: [
                      const Icon(Icons.shield, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text(
                        '信誉分详情',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 20, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              match.trustScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4维度评分
                  const Text(
                    '评分维度',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDimensionRow('驾驶安全', match.safetyScore, Icons.directions_car),
                  _buildDimensionRow('服务质量', match.serviceScore, Icons.headset_mic),
                  _buildDimensionRow('准时率', match.punctualityScore, Icons.schedule),
                  _buildDimensionRow('接单率', match.acceptanceScore, Icons.trending_up),

                  const SizedBox(height: 24),

                  // 评价摘要
                  if (match.recentReviews.isNotEmpty) ...[
                    const Text(
                      '评价摘要',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...match.recentReviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.format_quote,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                review,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '评价摘要',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无评价',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 单个维度行（图标 + 标签 + 进度条 + 分数）
  Widget _buildDimensionRow(String label, double score, IconData icon) {
    final clampedScore = score.clamp(0.0, 5.0);
    final progress = clampedScore / 5.0;

    Color barColor;
    if (clampedScore >= 4.0) {
      barColor = AppColors.success;
    } else if (clampedScore >= 3.0) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              clampedScore.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDriver(MatchResult match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认选择'),
        content: Text(
          '确定选择 ${match.driverName} 吗？\n\n'
          '费用：¥${match.price.toStringAsFixed(0)}\n'
          '车型：${match.carModel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(matchingProvider.notifier)
          .confirmMatch(match.driverId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已确认司机，正在创建订单...'),
            backgroundColor: AppColors.success,
          ),
        );

        // 跳转到订单详情页
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              orderId: ref.read(matchingProvider).orderId ?? 0,
            ),
          ),
        );
      }
    }
  }
}
