import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/providers/services_provider.dart';
import 'package:ride_hermes_driver/services/api_service.dart';

/// Agent 配置状态
class AgentConfigState {
  final bool isLoading;
  final String? error;

  // 接单偏好
  final int maxDistanceKm; // 最大接单距离(km)
  final double minPricePerKm; // 最低每公里价格
  final List<int> acceptedCarTypes; // 接受的车型 (1=经济 2=舒适 3=商务)
  final bool acceptScheduledOrders; // 是否接受预约单
  final bool acceptLongDistance; // 是否接受长途单

  // 定价策略
  final double basePriceMultiplier; // 基础价格倍率 (0.8 ~ 2.0)
  final double peakHourMultiplier; // 高峰时段加价倍率
  final double nightMultiplier; // 夜间加价倍率
  final bool autoCounterOffer; // 自动还价

  // 在线时间
  final AgentTime? workStart; // 上班时间
  final AgentTime? workEnd; // 下班时间
  final List<int> workDays; // 工作日 (1=周一 ... 7=周日)
  final bool autoOnline; // 自动上线

  // 信誉分
  final int reputationScore; // 信誉分 (0-100)
  final int totalOrders; // 总完成订单
  final double completionRate; // 完单率
  final int acceptCount; // 接单数
  final int rejectCount; // 拒单数

  const AgentConfigState({
    this.isLoading = false,
    this.error,
    this.maxDistanceKm = 10,
    this.minPricePerKm = 2.0,
    this.acceptedCarTypes = const [1, 2, 3],
    this.acceptScheduledOrders = true,
    this.acceptLongDistance = true,
    this.basePriceMultiplier = 1.0,
    this.peakHourMultiplier = 1.2,
    this.nightMultiplier = 1.3,
    this.autoCounterOffer = false,
    this.workStart,
    this.workEnd,
    this.workDays = const [1, 2, 3, 4, 5],
    this.autoOnline = false,
    this.reputationScore = 85,
    this.totalOrders = 0,
    this.completionRate = 0.0,
    this.acceptCount = 0,
    this.rejectCount = 0,
  });

  AgentConfigState copyWith({
    bool? isLoading,
    String? error,
    int? maxDistanceKm,
    double? minPricePerKm,
    List<int>? acceptedCarTypes,
    bool? acceptScheduledOrders,
    bool? acceptLongDistance,
    double? basePriceMultiplier,
    double? peakHourMultiplier,
    double? nightMultiplier,
    bool? autoCounterOffer,
    AgentTime? workStart,
    AgentTime? workEnd,
    List<int>? workDays,
    bool? autoOnline,
    int? reputationScore,
    int? totalOrders,
    double? completionRate,
    int? acceptCount,
    int? rejectCount,
    bool clearError = false,
    bool clearWorkStart = false,
    bool clearWorkEnd = false,
  }) {
    return AgentConfigState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minPricePerKm: minPricePerKm ?? this.minPricePerKm,
      acceptedCarTypes: acceptedCarTypes ?? this.acceptedCarTypes,
      acceptScheduledOrders: acceptScheduledOrders ?? this.acceptScheduledOrders,
      acceptLongDistance: acceptLongDistance ?? this.acceptLongDistance,
      basePriceMultiplier: basePriceMultiplier ?? this.basePriceMultiplier,
      peakHourMultiplier: peakHourMultiplier ?? this.peakHourMultiplier,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      autoCounterOffer: autoCounterOffer ?? this.autoCounterOffer,
      workStart: clearWorkStart ? null : (workStart ?? this.workStart),
      workEnd: clearWorkEnd ? null : (workEnd ?? this.workEnd),
      workDays: workDays ?? this.workDays,
      autoOnline: autoOnline ?? this.autoOnline,
      reputationScore: reputationScore ?? this.reputationScore,
      totalOrders: totalOrders ?? this.totalOrders,
      completionRate: completionRate ?? this.completionRate,
      acceptCount: acceptCount ?? this.acceptCount,
      rejectCount: rejectCount ?? this.rejectCount,
    );
  }
}

/// 简单时间表示（避免与 material 的 TimeOfDay 冲突）
class AgentTime {
  final int hour;
  final int minute;
  const AgentTime({required this.hour, required this.minute});

  String get formatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class AgentConfigNotifier extends StateNotifier<AgentConfigState> {
  final ApiService _api;

  AgentConfigNotifier(this._api) : super(const AgentConfigState());

  /// 从后端加载 Agent 配置
  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _api.authGet('/api/v1/driver/agent/config');
      state = _parseConfig(data).copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载配置失败: $e');
    }
  }

  /// 保存接单偏好
  Future<bool> savePreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.authPost('/api/v1/driver/agent/preferences', data: {
        'max_distance_km': state.maxDistanceKm,
        'min_price_per_km': state.minPricePerKm,
        'accepted_car_types': state.acceptedCarTypes,
        'accept_scheduled_orders': state.acceptScheduledOrders,
        'accept_long_distance': state.acceptLongDistance,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '保存失败: $e');
      return false;
    }
  }

  /// 保存定价策略
  Future<bool> savePricing() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.authPost('/api/v1/driver/agent/pricing', data: {
        'base_price_multiplier': state.basePriceMultiplier,
        'peak_hour_multiplier': state.peakHourMultiplier,
        'night_multiplier': state.nightMultiplier,
        'auto_counter_offer': state.autoCounterOffer,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '保存失败: $e');
      return false;
    }
  }

  /// 保存在线时间
  Future<bool> saveSchedule() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.authPost('/api/v1/driver/agent/schedule', data: {
        'work_start': state.workStart?.formatted,
        'work_end': state.workEnd?.formatted,
        'work_days': state.workDays,
        'auto_online': state.autoOnline,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '保存失败: $e');
      return false;
    }
  }

  /// 接受撮合邀请
  Future<bool> acceptInvitation(int invitationId) async {
    try {
      await _api.authPost('/api/v1/driver/agent/invitations/$invitationId/accept');
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: '操作失败: $e');
      return false;
    }
  }

  /// 拒绝撮合邀请
  Future<bool> rejectInvitation(int invitationId, {String? reason}) async {
    try {
      await _api.authPost(
        '/api/v1/driver/agent/invitations/$invitationId/reject',
        data: {'reason': reason ?? '不接受此订单'},
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: '操作失败: $e');
      return false;
    }
  }

  /// 对撮合邀请还价
  Future<bool> counterOffer(int invitationId, double counterPrice) async {
    try {
      await _api.authPost(
        '/api/v1/driver/agent/invitations/$invitationId/counter',
        data: {'counter_price': counterPrice},
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: '还价失败: $e');
      return false;
    }
  }

  AgentConfigState _parseConfig(Map<String, dynamic> data) {
    final prefs = data['preferences'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final schedule = data['schedule'] as Map<String, dynamic>? ?? {};
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    AgentTime? parseTime(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      final parts = raw.split(':');
      if (parts.length < 2) return null;
      return AgentTime(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }

    return AgentConfigState(
      maxDistanceKm: (prefs['max_distance_km'] as num?)?.toInt() ?? 10,
      minPricePerKm: (prefs['min_price_per_km'] as num?)?.toDouble() ?? 2.0,
      acceptedCarTypes: (prefs['accepted_car_types'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 2, 3],
      acceptScheduledOrders: prefs['accept_scheduled_orders'] as bool? ?? true,
      acceptLongDistance: prefs['accept_long_distance'] as bool? ?? true,
      basePriceMultiplier:
          (pricing['base_price_multiplier'] as num?)?.toDouble() ?? 1.0,
      peakHourMultiplier:
          (pricing['peak_hour_multiplier'] as num?)?.toDouble() ?? 1.2,
      nightMultiplier:
          (pricing['night_multiplier'] as num?)?.toDouble() ?? 1.3,
      autoCounterOffer: pricing['auto_counter_offer'] as bool? ?? false,
      workStart: parseTime(schedule['work_start'] as String?),
      workEnd: parseTime(schedule['work_end'] as String?),
      workDays: (schedule['work_days'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [1, 2, 3, 4, 5],
      autoOnline: schedule['auto_online'] as bool? ?? false,
      reputationScore: (stats['reputation_score'] as num?)?.toInt() ?? 85,
      totalOrders: (stats['total_orders'] as num?)?.toInt() ?? 0,
      completionRate:
          (stats['completion_rate'] as num?)?.toDouble() ?? 0.0,
      acceptCount: (stats['accept_count'] as num?)?.toInt() ?? 0,
      rejectCount: (stats['reject_count'] as num?)?.toInt() ?? 0,
    );
  }
}

final agentConfigProvider =
    StateNotifierProvider<AgentConfigNotifier, AgentConfigState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AgentConfigNotifier(api);
});
