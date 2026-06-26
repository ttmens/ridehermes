import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/services/api_service.dart';

/// Provides the global ApiService instance.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
