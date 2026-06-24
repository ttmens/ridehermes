class ApiPaths {
  static const base = '/api/v1';

  // Auth
  static const login = '$base/auth/login';
  static const refresh = '$base/auth/refresh';

  // Passenger
  static const passengerOrders = '$base/passenger/orders';
  static const passengerAiChat = '$base/passenger/ai/chat';
  static const passengerSessions = '$base/passenger/ai/sessions';
  static const passengerProfile = '$base/passenger/user/profile';
  static const passengerDriverLocation = '$base/passenger/driver-location';

  // Driver
  static const driverOnline = '$base/driver/online';
  static const driverOffline = '$base/driver/offline';
  static const driverOrders = '$base/driver/orders';
  static const driverProfile = '$base/driver/user/profile';

  // Admin
  static const adminUsers = '$base/admin/users';
  static const adminDrivers = '$base/admin/drivers';
  static const adminOrders = '$base/admin/orders';
  static const adminLocationsDrivers = '$base/admin/locations/drivers';
  static const adminLocationsPassengers = '$base/admin/locations/passengers';
}
