import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/providers/services_provider.dart';
import 'package:ride_hermes_passenger/services/api_service.dart';

/// 匹配结果数据模型
class MatchResult {
  final int driverId;
  final String driverName;
  final double trustScore;
  final int carType;
  final String carModel;
  final String plateNo;
  final double price;
  final String message;
  final List<String> recentReviews;

  // 信誉分4维度
  final double safetyScore;       // 驾驶安全
  final double serviceScore;      // 服务质量
  final double punctualityScore;  // 准时率
  final double acceptanceScore;   // 接单率

  MatchResult({
    required this.driverId,
    required this.driverName,
    required this.trustScore,
    required this.carType,
    required this.carModel,
    required this.plateNo,
    required this.price,
    required this.message,
    required this.recentReviews,
    this.safetyScore = 0.0,
    this.serviceScore = 0.0,
    this.punctualityScore = 0.0,
    this.acceptanceScore = 0.0,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      driverId: json['driver_id'] as int? ?? 0,
      driverName: json['driver_name'] as String? ?? '',
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      carType: json['car_type'] as int? ?? 1,
      carModel: json['car_model'] as String? ?? '',
      plateNo: json['plate_no'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      recentReviews: (json['recent_reviews'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      safetyScore: (json['safety_score'] as num?)?.toDouble() ?? 0.0,
      serviceScore: (json['service_score'] as num?)?.toDouble() ?? 0.0,
      punctualityScore: (json['punctuality_score'] as num?)?.toDouble() ?? 0.0,
      acceptanceScore: (json['acceptance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// 匹配状态
class MatchingState {
  final bool isLoading;
  final String? error;
  final int? orderId;
  final String? orderNo;
  final List<MatchResult> matches;
  final bool isPolling;

  const MatchingState({
    this.isLoading = false,
    this.error,
    this.orderId,
    this.orderNo,
    this.matches = const [],
    this.isPolling = false,
  });

  MatchingState copyWith({
    bool? isLoading,
    String? error,
    int? orderId,
    String? orderNo,
    List<MatchResult>? matches,
    bool? isPolling,
  }) {
    return MatchingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      orderId: orderId ?? this.orderId,
      orderNo: orderNo ?? this.orderNo,
      matches: matches ?? this.matches,
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

/// 匹配Provider：管理撮合流程
class MatchingNotifier extends StateNotifier<MatchingState> {
  final ApiService _apiService;
  Timer? _pollingTimer;

  MatchingNotifier(this._apiService) : super(const MatchingState());

  /// 发布出行需求
  Future<void> publishDemand({
    required String pickupAddr,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddr,
    required double dropoffLat,
    required double dropoffLng,
    required String departureTime,
    required int carType,
    required double priceRangeMin,
    required double priceRangeMax,
    required double minTrustScore,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        '/passenger/matching/demands',
        data: {
          'pickup_addr': pickupAddr,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_addr': dropoffAddr,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'departure_time': departureTime,
          'car_type': carType,
          'price_range_min': priceRangeMin,
          'price_range_max': priceRangeMax,
          'min_trust_score': minTrustScore,
        },
      );

      if (response['order_id'] != null) {
        state = state.copyWith(
          isLoading: false,
          orderId: response['order_id'] as int,
          orderNo: response['order_no'] as String?,
        );
      } else {
        throw Exception('Failed to create demand');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 开始轮询匹配结果
  void startPollingMatches() {
    if (state.orderId == null || state.isPolling) return;

    state = state.copyWith(isPolling: true);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchMatches(),
    );

    // 立即获取一次
    _fetchMatches();
  }

  /// 停止轮询
  void stopPollingMatches() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isPolling: false);
  }

  /// 刷新匹配结果
  Future<void> refreshMatches() async {
    await _fetchMatches();
  }

  /// 获取匹配结果
  Future<void> _fetchMatches() async {
    if (state.orderId == null) return;

    try {
      final response = await _apiService.get(
        '/passenger/matching/demands/${state.orderId}/matches',
      );

      final matchesData = response['matches'] as List<dynamic>? ?? [];
      final matches = matchesData
          .map((m) => MatchResult.fromJson(m as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        isLoading: false,
        matches: matches,
      );

      // 如果有匹配结果，停止轮询
      if (matches.isNotEmpty) {
        stopPollingMatches();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 确认选择司机
  Future<bool> confirmMatch(int driverId) async {
    if (state.orderId == null) return false;

    state = state.copyWith(isLoading: true);

    try {
      await _apiService.post(
        '/passenger/matching/demands/${state.orderId}/confirm',
        data: {'driver_id': driverId},
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 重置状态
  void reset() {
    stopPollingMatches();
    state = const MatchingState();
  }

  @override
  void dispose() {
    stopPollingMatches();
    super.dispose();
  }
}

/// MatchingProvider
final matchingProvider =
    StateNotifierProvider<MatchingNotifier, MatchingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MatchingNotifier(apiService);
});
