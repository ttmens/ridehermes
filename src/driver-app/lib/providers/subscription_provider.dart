import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'services_provider.dart';

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
      // 从API获取套餐列表（公开接口，无需认证）
      final response = await _apiService.authGet('/api/v1/subscriptions/plans');
      
      if (response != null && response['plans'] != null) {
        final plansData = List<Map<String, dynamic>>.from(response['plans']);
        
        // 为每个套餐添加benefits（因为后端没有存储benefits）
        final plans = plansData.map((plan) {
          final type = plan['type'] ?? 0;
          List<String> benefits;
          
          // 根据套餐类型添加对应的benefits
          switch (type) {
            case 1: // Basic
              benefits = [
                '基础撮合服务',
                '标准订单匹配',
                '基础数据分析',
              ];
              break;
            case 2: // Pro
              benefits = [
                '优先撮合服务',
                '智能订单推荐',
                '详细数据分析',
                '专属客服支持',
              ];
              break;
            case 3: // Premium
              benefits = [
                '最高优先级撮合',
                'AI智能调度',
                '全维度数据分析',
                '专属客户经理',
                '定制化服务',
              ];
              break;
            default:
              benefits = ['基础服务'];
          }
          
          return SubscriptionPlan(
            type: type,
            name: plan['name'] ?? '',
            monthlyFee: (plan['monthly_fee'] ?? 0).toDouble(),
            revenueRate: (plan['revenue_rate'] ?? 0).toDouble(),
            benefits: benefits,
          );
        }).toList();

        state = state.copyWith(isLoading: false, plans: plans);
      } else {
        state = state.copyWith(isLoading: false, error: '无法获取套餐列表');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      final response = await _apiService.authGet('/driver/subscriptions');
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
      final response = await _apiService.authPost(
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
      final response = await _apiService.authPost(
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
