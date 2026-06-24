# RideHermes 乘客端 Flutter 应用

## 项目概述

RideHermes 乘客端是 RideHermes 打车平台的移动应用，基于 Flutter 开发，支持语音 AI 叫车。

## 技术栈

- **Flutter**: 3.24+
- **Dart**: 3.5+
- **状态管理**: flutter_riverpod 2.x
- **路由**: go_router
- **网络**: dio + web_socket_channel
- **地图**: 高德地图 (amap_flutter_map)
- **存储**: shared_preferences + flutter_secure_storage
- **代码生成**: freezed + json_serializable + riverpod_generator

## 项目结构

```
lib/
├── config/           # 配置（AppConfig, 主题常量）
├── theme/            # 主题（AppTheme）
├── core/
│   ├── network/      # 网络层（Dio, 拦截器, ApiResult）
│   ├── storage/      # 存储（TokenStorage）
│   ├── ws/           # WebSocket（WsClient, WsMessage, 重连策略）
│   └── location/     # 定位服务（LocationService）
├── models/           # 数据模型（User, Order, Location, AIChat）
├── providers/        # 状态管理（Auth, Order）
├── services/         # 服务层（ApiService）
├── router/           # 路由配置（app_router.dart）
├── screens/          # 页面（登录, 首页, 订单确认, 行程追踪, AI对话）
├── features/         # 功能模块
│   ├── login/        # 登录
│   ├── home/         # 首页
│   ├── order_list/   # 订单列表
│   ├── order_detail/ # 订单详情
│   ├── profile/      # 个人中心
│   ├── manual_booking/ # 手动叫车
│   └── ...
├── shared/           # 共享组件和工具
│   ├── widgets/      # 通用组件
│   └── utils/        # 工具类
├── main.dart         # 入口
└── app.dart          # 根组件
```

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 生成代码

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 配置高德地图 API Key

编辑 `lib/config/app_config.dart`：

```dart
static const String amapApiKey = 'YOUR_AMAP_API_KEY';
static const String amapApiKeyIos = 'YOUR_AMAP_IOS_KEY';
```

### 4. 运行应用

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (调试用)
flutter run -d chrome
```

## 功能模块

### 1. 登录页 (`/login`)
- 手机号 + 密码登录
- JWT Token 管理（Access + Refresh）
- 自动 Token 刷新

### 2. 首页 (`/home`)
- 地图显示（高德地图）
- 语音 AI 对话入口
- 快捷指令
- 底部导航（首页/订单/我的）

### 3. AI 对话页 (`/ai-chat`)
- 语音录制
- 实时语音识别（ASR）
- AI 意图理解
- 订单预览

### 4. 订单确认页 (`/order-confirm`)
- 地图选点
- 上下车地址确认
- 费用预估
- 车型选择

### 5. 行程追踪页 (`/trip/:orderId`)
- 实时地图显示
- 司机位置追踪
- 行程状态更新
- WebSocket 实时通信

### 6. 订单列表页 (`/orders`)
- 历史订单列表
- 订单状态筛选
- 下拉刷新

### 7. 订单详情页 (`/order/:orderId`)
- 订单完整信息
- 司机信息
- 行程轨迹
- 取消订单

### 8. 个人中心 (`/profile`)
- 用户信息显示
- 设置
- 退出登录

### 9. 手动叫车页 (`/manual-booking`)
- 手动输入地址
- 地图选点
- 预约叫车

## API 接口

基础 URL: `http://10.0.2.2:8080` (Android 模拟器)

### 认证
- `POST /api/v1/auth/login` - 登录
- `POST /api/v1/auth/refresh` - 刷新 Token

### 订单
- `GET /api/v1/passenger/orders` - 订单列表
- `POST /api/v1/passenger/orders` - 创建订单
- `POST /api/v1/passenger/orders/:id/cancel` - 取消订单

### AI 对话
- `POST /api/v1/ai/chat` - AI 对话（文本）
- `POST /api/v1/ai/chat/voice` - AI 对话（语音）

### WebSocket
- `ws://10.0.2.2:8080/ws/location` - 位置更新、订单状态推送

## 数据模型

### User
```dart
class User {
  final int id;
  final String phone;
  final String? nickname;
  final String? avatar;
}
```

### Order
```dart
class Order {
  final int id;
  final String orderNo;
  final int status;  // 1-8 (待派单/派单中/已接单/前往接驾/已到达/行程中/已完成/已取消)
  final String pickupAddr;
  final String dropoffAddr;
  final double estPrice;
  final Driver? driver;
}
```

### AIChatResponse
```dart
@freezed
class AIChatResponse with _$AIChatResponse {
  const factory AIChatResponse({
    required String sessionId,
    required String responseText,
    RideIntent? intent,
    String? asrText,
    OrderPreview? orderPreview,
  }) = _AIChatResponse;
}
```

## 状态管理

### AuthState
- `isLoggedIn`: 登录状态
- `user`: 用户信息
- `tokens`: JWT Tokens

### OrderState
- `orders`: 订单列表
- `currentOrder`: 当前订单
- `isLoading`: 加载状态
- `error`: 错误信息

## 网络层

### DioClient
- 统一 Base URL 配置
- 超时设置
- 日志拦截器

### ApiInterceptor
- 自动附加 JWT Token
- Token 过期自动刷新
- 401 错误处理

### ApiResult<T>
- 统一 API 响应封装
- `isSuccess`: 是否成功
- `data`: 响应数据
- `message`: 错误信息

## WebSocket

### WsClient
- 自动重连（指数退避）
- 心跳保活
- 消息广播（Stream）
- 位置更新发送

## 注意事项

1. **Freezed 代码生成**: 修改 `@freezed` 注解的类后需要重新生成代码
2. **高德地图配置**: Android 需要配置 `AndroidManifest.xml`，iOS 需要配置 `Info.plist`
3. **权限申请**: 定位、录音、相机等权限需要在运行时申请
4. **后端连接**: 确保后端服务运行在 `http://10.0.2.2:8080`（Android 模拟器）

## 开发状态

✅ 所有核心代码文件已创建完成
✅ 代码架构符合设计文档要求
⏳ Flutter SDK 安装（当前环境受限）
⏳ 代码生成（freezed, json_serializable）
⏳ 编译验证
⏳ 功能测试

## 后续步骤

1. 安装 Flutter SDK
2. 运行 `flutter pub get`
3. 运行 `flutter pub run build_runner build --delete-conflicting-outputs`
4. 配置高德地图 API Key
5. 启动后端服务
6. 运行应用并测试

## 相关文档

- [总体架构设计](../docs/RideHermes-v0.1-总体架构设计.md)
- [后端服务详细设计](../docs/RideHermes-v0.1-后端服务详细设计.md)
- [移动端详细设计](../docs/RideHermes-v0.1-移动端详细设计.md)
- [AI 智能体服务详细设计](../docs/RideHermes-v0.1-AI智能体服务详细设计.md)
- [运营管理后台详细设计](../docs/RideHermes-v0.1-运营管理后台详细设计.md)
