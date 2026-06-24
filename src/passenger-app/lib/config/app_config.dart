class AppConfig {
  static const String appName = 'RideHermes';

  // Backend API address — override via --dart-define=API_BASE_URL=xxx
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ride.accseal.cn',
  );
  static const String apiPrefix = '/api/v1';

  // WebSocket address — override via --dart-define=WS_URL=xxx
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://ride.accseal.cn/ws/location',
  );

  // 高德地图 Key — set via --dart-define at build time, never hardcode in source
  // Web服务 Key（REST 接口专用）
  static const String amapWebKey = String.fromEnvironment('AMAP_WEB_KEY');
  // Android 平台 Key（绑定 包名 com.ridehermes.passenger + 签名SHA1）
  static const String amapAndroidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
  // iOS 平台 Key（绑定 Bundle ID）
  static const String amapIosKey = String.fromEnvironment('AMAP_IOS_KEY');

  // Timeout config
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration locationInterval = Duration(seconds: 3);
  static const Duration heartbeatInterval = Duration(seconds: 30);
}
