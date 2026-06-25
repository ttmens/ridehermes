import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class SubscriptionPlan {
  final int type;
  final String name;
  final double monthlyFee;
  final double revenueRate;
  final List<String> benefits;

  SubscriptionPlan({
    required this.type,
    required this.name,
    required this.monthlyFee,
    required this.revenueRate,
    required this.benefits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      type: json['type'] ?? 0,
      name: json['name'] ?? '',
      monthlyFee: (json['monthly_fee'] ?? 0).toDouble(),
      revenueRate: (json['revenue_rate'] ?? 0).toDouble(),
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }
}

class SubscriptionState {
  final bool isLoading;
  final String? error;
  final List<SubscriptionPlan> plans;
  final Map<String, dynamic>? currentSubscription;

  SubscriptionState({
    this.isLoading = false,
    this.error,
    this.plans = const [],
    this.currentSubscription,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    String? error,
    List<SubscriptionPlan>? plans,
    Map<String, dynamic>? currentSubscription,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      plans: plans ?? this.plans,
      currentSubscription: currentSubscription ?? this.currentSubscription,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final ApiService _apiService;

  SubscriptionNotifier(this._apiService) : super(SubscriptionState());

  Future<void> loadPlans() async {
    state = state.copyWith(isLoading: true);

    try {
      // 模拟套餐数据（实际应从API获取）
      final plans = [
        SubscriptionPlan(
          type: 1,
          name: '基础版',
          monthlyFee: 299,
          revenueRate: 0.03,
          benefits: [
            '基础撮合服务',
            '标准订单匹配',
            '基础数据分析',
          ],
        ),
        SubscriptionPlan(
          type: 2,
          name: '专业版',
          monthlyFee: 499,
          revenueRate: 0.05,
          benefits: [
            '优先撮合服务',
            '智能订单推荐',
            '详细数据分析',
            '专属客服支持',
          ],
        ),
        SubscriptionPlan(
          type: 3,
          name: '旗舰版',
          monthlyFee: 799,
          revenueRate: 0.06,
          benefits: [
            '最高优先级撮合',
            'AI智能调度',
            '全维度数据分析',
            '专属客户经理',
            '定制化服务',
          ],
        ),
      ];

      state = state.copyWith(isLoading: false, plans: plans);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      final response = await _apiService.get('/driver/subscriptions');
      if (response != null) {
        state = state.copyWith(currentSubscription: response);
      }
    } catch (e) {
      // 忽略错误，可能没有订阅
    }
  }

  Future<bool> subscribe(int planType) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.post(
        '/driver/subscriptions',
        data: {'plan_type': planType},
      );

      if (response != null && response['id'] != null) {
        await loadCurrentSubscription();
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: '订阅失败');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.post(
        '/driver/subscriptions/cancel',
        data: {},
      );

      if (response != null) {
        state = state.copyWith(isLoading: false, currentSubscription: null);
        return true;
      }

      state = state.copyWith(isLoading: false, error: '取消失败');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier(ref.watch(apiServiceProvider));
});
