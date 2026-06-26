import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class RecurringTrip {
  final int id;
  final String tripType;
  final String pickupAddr;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddr;
  final double dropoffLat;
  final double dropoffLng;
  final String departureTime;
  final String daysOfWeek;
  final int carType;
  final bool isActive;
  final String startDate;
  final String endDate;

  RecurringTrip({
    required this.id,
    required this.tripType,
    required this.pickupAddr,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddr,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.departureTime,
    required this.daysOfWeek,
    required this.carType,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  factory RecurringTrip.fromJson(Map<String, dynamic> json) {
    return RecurringTrip(
      id: json['id'] ?? 0,
      tripType: json['trip_type'] ?? '',
      pickupAddr: json['pickup_addr'] ?? '',
      pickupLat: (json['pickup_lat'] ?? 0).toDouble(),
      pickupLng: (json['pickup_lng'] ?? 0).toDouble(),
      dropoffAddr: json['dropoff_addr'] ?? '',
      dropoffLat: (json['dropoff_lat'] ?? 0).toDouble(),
      dropoffLng: (json['dropoff_lng'] ?? 0).toDouble(),
      departureTime: json['departure_time'] ?? '',
      daysOfWeek: json['days_of_week'] ?? '',
      carType: json['car_type'] ?? 1,
      isActive: json['is_active'] ?? true,
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class RecurringTripState {
  final bool isLoading;
  final String? error;
  final List<RecurringTrip> trips;

  RecurringTripState({
    this.isLoading = false,
    this.error,
    this.trips = const [],
  });

  RecurringTripState copyWith({
    bool? isLoading,
    String? error,
    List<RecurringTrip>? trips,
  }) {
    return RecurringTripState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      trips: trips ?? this.trips,
    );
  }
}

class RecurringTripNotifier extends StateNotifier<RecurringTripState> {
  final ApiService _apiService;

  RecurringTripNotifier(this._apiService) : super(RecurringTripState());

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.get('/passenger/recurring-trips');
      if (response != null && (response['list'] != null || response['trips'] != null)) {
        final rawList = (response['list'] ?? response['trips']) as List;
        final trips = rawList
            .map((json) => RecurringTrip.fromJson(json))
            .toList();
        state = state.copyWith(isLoading: false, trips: trips);
      } else {
        state = state.copyWith(isLoading: false, trips: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTrip(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.post(
        '/passenger/recurring-trips',
        data: data,
      );

      if (response != null && response['id'] != null) {
        await loadTrips();
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: '创建失败');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleTripStatus(int tripId, bool isActive) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.put(
        '/passenger/recurring-trips/$tripId',
        data: {'is_active': isActive},
      );

      if (response != null) {
        await loadTrips();
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: '更新失败');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTrip(int tripId) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiService.delete(
        '/passenger/recurring-trips/$tripId',
      );

      if (response != null) {
        await loadTrips();
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(isLoading: false, error: '删除失败');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final recurringTripProvider =
    StateNotifierProvider<RecurringTripNotifier, RecurringTripState>((ref) {
  return RecurringTripNotifier(ref.watch(apiServiceProvider));
});
