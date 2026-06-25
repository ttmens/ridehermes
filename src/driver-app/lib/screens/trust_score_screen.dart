import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/config/theme.dart';
import 'package:ride_hermes_driver/providers/services_provider.dart';
import 'package:ride_hermes_driver/services/api_service.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class TrustScoreData {
  final int overallScore;
  final int totalOrders;
  final double completionRate;
  final int rank;
  final int totalDrivers;

  // 4 dimensions
  final int orderCompletion; // 完单率维度
  final int serviceQuality; // 服务质量维度
  final int drivingSafety; // 驾驶安全维度
  final int punctuality; // 准时性维度

  // Trend (last 7 days or periods)
  final List<int> trendScores;

  const TrustScoreData({
    this.overallScore = 85,
    this.totalOrders = 0,
    this.completionRate = 0,
    this.rank = 0,
    this.totalDrivers = 0,
    this.orderCompletion = 80,
    this.serviceQuality = 85,
    this.drivingSafety = 90,
    this.punctuality = 75,
    this.trendScores = const [],
  });

  factory TrustScoreData.fromJson(Map<String, dynamic> json) {
    return TrustScoreData(
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 85,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      totalDrivers: (json['total_drivers'] as num?)?.toInt() ?? 0,
      orderCompletion: (json['order_completion'] as num?)?.toInt() ?? 80,
      serviceQuality: (json['service_quality'] as num?)?.toInt() ?? 85,
      drivingSafety: (json['driving_safety'] as num?)?.toInt() ?? 90,
      punctuality: (json['punctuality'] as num?)?.toInt() ?? 75,
      trendScores: (json['trend_scores'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
    );
  }
}

class EvaluationItem {
  final String id;
  final int orderId;
  final int rating;
  final String? comment;
  final List<String> tags;
  final String createdAt;

  const EvaluationItem({
    required this.id,
    required this.orderId,
    required this.rating,
    this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    return EvaluationItem(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class TrustScoreNotifier extends StateNotifier<AsyncValue<TrustScoreData?>> {
  final ApiService _api;

  TrustScoreNotifier(this._api) : super(const AsyncValue.data(null));

  Future<void> loadTrustScore() async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.authGet('/api/v1/driver/trust-score');
      state = AsyncValue.data(TrustScoreData.fromJson(data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final trustScoreProvider =
    StateNotifierProvider<TrustScoreNotifier, AsyncValue<TrustScoreData?>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TrustScoreNotifier(api);
});

final evaluationsProvider = FutureProvider<List<EvaluationItem>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.authGet('/api/v1/driver/evaluations', params: {
    'limit': 20,
    'offset': 0,
  });
  final list = data['items'] as List? ?? [];
  return list.map((e) => EvaluationItem.fromJson(e as Map<String, dynamic>)).toList();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TrustScoreScreen extends ConsumerWidget {
  const TrustScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trustAsync = ref.watch(trustScoreProvider);
    final evalAsync = ref.watch(evaluationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('信誉分详情'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: trustAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败: $err')),
        data: (trustData) {
          if (trustData == null) {
            return const Center(child: Text('暂无信誉分数据'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Overall score card ---
                _OverallScoreCard(data: trustData),
                const SizedBox(height: AppSpacing.base),

                // --- Radar chart: 4 dimensions ---
                _RadarChartCard(data: trustData),
                const SizedBox(height: AppSpacing.base),

                // --- Trend chart ---
                if (trustData.trendScores.isNotEmpty) ...[
                  _TrendChartCard(trendScores: trustData.trendScores),
                  const SizedBox(height: AppSpacing.base),
                ],

                // --- Ranking ---
                _RankingCard(data: trustData),
                const SizedBox(height: AppSpacing.base),

                // --- Recent evaluations ---
                _EvaluationsSection(asyncData: evalAsync),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overall score card
// ---------------------------------------------------------------------------

class _OverallScoreCard extends StatelessWidget {
  final TrustScoreData data;
  const _OverallScoreCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(data.overallScore);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.4), width: 3),
            ),
            child: Center(
              child: Text(
                '${data.overallScore}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '信誉分 · ${_reputationLevel(data.overallScore)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '完单率 ${(data.completionRate * 100).toStringAsFixed(0)}% · 总订单 ${data.totalOrders}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '排名 ${data.rank > 0 ? '第 $data.rank 名 / 共 ${data.totalDrivers} 名司机' : '暂无排名数据'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Radar chart — 4 dimensions via CustomPainter
// ---------------------------------------------------------------------------

class _RadarChartCard extends StatelessWidget {
  final TrustScoreData data;
  const _RadarChartCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '四维评分',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _RadarPainter(
                  values: [
                    data.orderCompletion.toDouble(),
                    data.serviceQuality.toDouble(),
                    data.drivingSafety.toDouble(),
                    data.punctuality.toDouble(),
                  ],
                  labels: ['完单率', '服务质量', '驾驶安全', '准时性'],
                  maxValue: 100,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dimensionLabel('完单率', data.orderCompletion, AppColors.info),
              _dimensionLabel('服务质量', data.serviceQuality, AppColors.success),
              _dimensionLabel('驾驶安全', data.drivingSafety, AppColors.warning),
              _dimensionLabel('准时性', data.punctuality, AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dimensionLabel(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxValue;

  _RadarPainter({
    required this.values,
    required this.labels,
    this.maxValue = 100,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.4;
    final n = values.length;
    final angleStep = 2 * 3.1415927 / n;
    final startAngle = -3.1415927 / 2; // start from top

    // Draw grid
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = startAngle + angleStep * i;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw data polygon
    final dataPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final dataStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * ratio * cos(angle);
      final y = center.dy + radius * ratio * sin(angle);
      if (i == 0) dataPath.moveTo(x, y);
      else dataPath.lineTo(x, y);
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStroke);

    // Draw dots at data points
    for (int i = 0; i < n; i++) {
      final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
      final angle = startAngle + angleStep * i;
      final x = center.dx + radius * ratio * cos(angle);
      final y = center.dy + radius * ratio * sin(angle);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.primary);
    }

    // Draw labels
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final labelR = radius + 20;
      final x = center.dx + labelR * cos(angle);
      final y = center.dy + labelR * sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.values != values;
}

// ---------------------------------------------------------------------------
// Trend chart — simple line chart via CustomPainter
// ---------------------------------------------------------------------------

class _TrendChartCard extends StatelessWidget {
  final List<int> trendScores;
  const _TrendChartCard({required this.trendScores});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '近期趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _TrendPainter(
                scores: trendScores,
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<int> scores;
  final double minY;
  final double maxY;

  _TrendPainter({required this.scores, this.minY = 0, this.maxY = 100});

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 40.0, padR = 20.0, padT = 10.0, padB = 30.0;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;
    if (scores.isEmpty || chartW <= 0 || chartH <= 0) return;

    final range = maxY - minY;
    if (range <= 0) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = padT + chartH * (1 - i / 4);
      canvas.drawLine(Offset(padL, y), Offset(size.width - padR, y), gridPaint);
      // Y-axis label
      final val = (minY + range * i / 4).toInt();
      final tp = TextPainter(
        text: TextSpan(
          text: '$val',
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padL - tp.width - 4, y - tp.height / 2));
    }

    // Data line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(padL, padT, chartW, chartH));

    final stepX = chartW / (scores.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = padL + stepX * i;
      final ratio = ((scores[i] - minY) / range).clamp(0.0, 1.0);
      final y = padT + chartH * (1 - ratio);
      points.add(Offset(x, y));
    }

    // Fill area
    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, padT + chartH);
      for (final pt in points) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(points.last.dx, padT + chartH);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) linePath.moveTo(points[i].dx, points[i].dy);
      else linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, Paint()..color = AppColors.primary);
    }

    // X-axis labels (date or period index)
    for (int i = 0; i < scores.length; i++) {
      final x = padL + stepX * i;
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(fontSize: 9, color: AppColors.textHint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padB + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.scores != scores;
}

// ---------------------------------------------------------------------------
// Ranking card
// ---------------------------------------------------------------------------

class _RankingCard extends StatelessWidget {
  final TrustScoreData data;
  const _RankingCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final rankStr = data.rank > 0 ? '第 $data.rank 名' : '暂无';
    final totalStr = data.totalDrivers > 0 ? '共 $data.totalDrivers 名司机' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.warning, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '司机排名',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$rankStr${totalStr.isNotEmpty ? ' · $totalStr' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (data.rank > 0 && data.totalDrivers > 0)
            Text(
              '超越 ${((1 - data.rank / data.totalDrivers) * 100).toStringAsFixed(0)}% 的司机',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Evaluations section
// ---------------------------------------------------------------------------

class _EvaluationsSection extends StatelessWidget {
  final AsyncValue<List<EvaluationItem>> asyncData;
  const _EvaluationsSection({required this.asyncData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '近期评价',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Text(
                '共 ${asyncData.whenOrNull(data: (list) => list.length) ?? 0} 条',
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          asyncData.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (err, _) => Center(
              child: Text('加载失败', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.reviews_outlined, size: 48, color: AppColors.textHint),
                        SizedBox(height: AppSpacing.sm),
                        Text('暂无评价', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: items.map((e) => _EvaluationCard(item: e)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final EvaluationItem item;
  const _EvaluationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Star rating
              ...List.generate(5, (i) => Icon(
                i < item.rating ? Icons.star : Icons.star_border,
                size: 16,
                color: i < item.rating ? AppColors.warning : AppColors.textHint,
              )),
              const Spacer(),
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          if (item.comment != null && item.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.comment!,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    if (raw.length >= 16) {
      // Extract "2025-03-20 14:30" or similar
      try {
        return raw.substring(0, 16);
      } catch (_) {}
    }
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _scoreColor(int score) {
  if (score >= 90) return AppColors.success;
  if (score >= 70) return AppColors.warning;
  return AppColors.error;
}

String _reputationLevel(int score) {
  if (score >= 90) return '优秀';
  if (score >= 70) return '良好';
  if (score >= 50) return '一般';
  return '待提升';
}
