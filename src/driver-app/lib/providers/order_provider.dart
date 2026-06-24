import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_driver/models/order.dart';
import 'package:ride_hermes_driver/providers/auth_provider.dart';
import 'package:ride_hermes_driver/services/api_service.dart';

class DriverOrderState {
  final List<Order> orders;
  final Order? currentOrder;
  final List<Order> pendingOrders;
  final bool isOnline;
  final bool isLoading;
  final String? error;

  const DriverOrderState({
    this.orders = const [],
    this.currentOrder,
    this.pendingOrders = const [],
    this.isOnline = false,
    this.isLoading = false,
    this.error,
  });

  DriverOrderState copyWith({
    List<Order>? orders,
    Order? currentOrder,
    List<Order>? pendingOrders,
    bool? isOnline,
    bool? isLoading,
    String? error,
    bool clearCurrentOrder = false,
  }) {
    return DriverOrderState(
      orders: orders ?? this.orders,
      currentOrder: clearCurrentOrder ? null : (currentOrder ?? this.currentOrder),
      pendingOrders: pendingOrders ?? this.pendingOrders,
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DriverOrderNotifier extends StateNotifier<DriverOrderState> {
  final ApiService _api;

  DriverOrderNotifier(this._api) : super(const DriverOrderState());

  Future<void> goOnline({double lat = 0, double lng = 0, int carType = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPut('/api/v1/driver/online', data: {
        'latitude': lat,
        'longitude': lng,
        'car_type': carType,
      });
      state = state.copyWith(isOnline: true, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> goOffline() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPut('/api/v1/driver/offline');
      state = state.copyWith(isOnline: false, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  /// Confirm an assigned order (ASSIGNED -> ACCEPTED).
  Future<void> acceptOrder(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPost('/api/v1/driver/orders/$orderId/accept');
      state = state.copyWith(isLoading: false);
      await fetchOrders();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '确认失败: $e');
    }
  }

  /// Reject an assigned order (ASSIGNED -> PENDING, driver cleared).
  Future<void> rejectOrder(int orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPost('/api/v1/driver/orders/$orderId/reject',
          data: {'reason': '不接受此订单'});
      state = state.copyWith(isLoading: false);
      await fetchOrders();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '拒绝失败: $e');
    }
  }

  Future<void> arrive() async {
    final order = state.currentOrder;
    if (order == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPost('/api/v1/driver/orders/${order.id}/arrive');
      state = state.copyWith(isLoading: false);
      await fetchOrders();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> startTrip() async {
    final order = state.currentOrder;
    if (order == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPost('/api/v1/driver/orders/${order.id}/start');
      state = state.copyWith(isLoading: false);
      await fetchOrders();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> completeOrder() async {
    final order = state.currentOrder;
    if (order == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.authPost('/api/v1/driver/orders/${order.id}/complete');
      state = state.copyWith(clearCurrentOrder: true, isLoading: false);
      await fetchOrders();
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> fetchOrders({int offset = 0, int limit = 20}) async {
    try {
      final data = await _api.authGet('/api/v1/driver/orders',
          params: {'offset': offset, 'limit': limit});
      final rawList = data['list'] as List? ?? [];
      final list = rawList
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList();
      // Orders with status 2 are pending confirmation
      final pending = list.where((o) => o.status == 2).toList();
      // Active order: status 2-6 (first one found)
      final active =
          list.where((o) => o.status >= 2 && o.status <= 6).firstOrNull;
      state = state.copyWith(
        orders: list,
        pendingOrders: pending,
        currentOrder: active ?? state.currentOrder,
        error: null,
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    } catch (e) {
      state = state.copyWith(error: '$e');
    }
  }
}

final driverOrderProvider =
    StateNotifierProvider<DriverOrderNotifier, DriverOrderState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DriverOrderNotifier(api);
});
