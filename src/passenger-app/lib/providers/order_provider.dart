import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/models/order.dart';
import 'package:ride_hermes_passenger/services/api_service.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class OrderState {
  final List<Order> orders;
  final Order? currentOrder;
  final bool isLoading;
  final String? error;

  const OrderState({
    this.orders = const [],
    this.currentOrder,
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    List<Order>? orders,
    Order? currentOrder,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final ApiService _api;

  OrderNotifier(this._api) : super(const OrderState());

  Future<void> fetchOrders({int offset = 0, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.get('/api/v1/passenger/orders',
          params: {'offset': offset, 'limit': limit});

      if (result.isSuccess && result.data != null) {
        final data = result.data!['data'] as Map<String, dynamic>;
        final list = (data['list'] as List)
            .map((o) => Order.fromJson(o as Map<String, dynamic>))
            .toList();
        state = state.copyWith(orders: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<Order?> createOrder({
    required String pickupAddr,
    required double pickupLat,
    required double pickupLng,
    required String dropoffAddr,
    required double dropoffLat,
    required double dropoffLng,
    int carType = 1,
    DateTime? departureTime,
  }) async {
    try {
      final result = await _api.post('/api/v1/passenger/orders', data: {
        'pickup_addr': pickupAddr,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'dropoff_addr': dropoffAddr,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'car_type': carType,
        if (departureTime != null)
          'departure_time': departureTime.toIso8601String(),
      });

      if (result.isSuccess && result.data != null) {
        final order = Order.fromJson(
            result.data!['data'] as Map<String, dynamic>);
        state = state.copyWith(currentOrder: order);
        return order;
      } else {
        state = state.copyWith(error: result.message);
        return null;
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId, {String reason = ''}) async {
    try {
      final result = await _api.post(
          '/api/v1/passenger/orders/$orderId/cancel',
          data: {'reason': reason});

      if (result.isSuccess) {
        state = state.copyWith(currentOrder: null);
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: '$e');
      return false;
    }
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return OrderNotifier(api);
});
