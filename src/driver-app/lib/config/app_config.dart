class AppConfig {
  static const String appName = 'RideHermes Driver';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ride.accseal.cn',
  );
  static const String apiPrefix = '/api/v1';
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://ride.accseal.cn/ws/location',
  );
  /// Amap API key — set via --dart-define=AMAP_KEY=xxx at build time
  static const String amapApiKey = String.fromEnvironment('AMAP_KEY');
  static const String amapApiKeyIos = String.fromEnvironment('AMAP_KEY_IOS');

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration locationInterval = Duration(seconds: 3);
  static const Duration heartbeatInterval = Duration(seconds: 30);
}
