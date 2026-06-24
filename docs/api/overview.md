# RideHermes API 文档

> RESTful API 接口概述

## 基础信息

| 项目 | 值 |
|------|-----|
| **Base URL** | `https://ride.accseal.cn/api/v1` |
| **协议** | HTTPS |
| **数据格式** | JSON |
| **认证方式** | JWT Bearer Token |

---

## 认证

### 获取 Token

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "password123"
}
```

**响应：**
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJhbGc...",
    "refresh_token": "eyJhbGc...",
    "expires_in": 7200,
    "user": { "id": 1, "phone": "13800138000", "role": 2 }
  }
}
```

---

## 公开接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/auth/login` | 登录 |
| POST | `/auth/refresh` | 刷新 Token |
| GET | `/health` | 健康检查 |

---

## 乘客接口

> 需要乘客角色 Token

### 订单

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/passenger/orders` | 创建订单 |
| GET | `/passenger/orders` | 我的订单列表 |
| GET | `/passenger/orders/:id` | 订单详情 |
| POST | `/passenger/orders/:id/cancel` | 取消订单 |
| GET | `/passenger/driver-location/:order_id` | 司机实时位置 |

### AI 对话

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/passenger/ai/chat` | AI 对话（文本） |
| POST | `/passenger/ai/chat/voice` | AI 对话（语音） |
| GET | `/passenger/ai/sessions` | 对话历史 |

### 地图

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/maps/poi/search` | POI 关键词搜索 |
| GET | `/maps/poi/around` | 周边 POI 搜索 |
| GET | `/maps/geocode` | 地址解析 |
| GET | `/maps/regeocode` | 逆地址解析 |
| GET | `/maps/route/driving` | 驾车路线规划 |

---

## 司机接口

> 需要司机角色 Token

| 方法 | 路径 | 说明 |
|------|------|------|
| PUT | `/driver/online` | 上线 |
| PUT | `/driver/offline` | 下线 |
| POST | `/driver/orders/:id/accept` | 接单 |
| POST | `/driver/orders/:id/reject` | 拒单 |
| POST | `/driver/orders/:id/arrive` | 到达上车点 |
| POST | `/driver/orders/:id/start` | 开始行程 |
| POST | `/driver/orders/:id/complete` | 完成订单 |
| GET | `/driver/orders` | 我的订单 |

---

## 管理员接口

> 需要管理员角色 Token

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/admin/users/passenger` | 创建乘客 |
| POST | `/admin/users/driver` | 创建司机 |
| GET | `/admin/users` | 用户列表 |
| GET | `/admin/users/:id` | 用户详情 |
| PUT | `/admin/users/:id/status` | 启用/禁用用户 |
| GET | `/admin/drivers` | 司机列表 |
| GET | `/admin/orders` | 全部订单 |
| GET | `/admin/orders/:id` | 订单详情 |
| GET | `/admin/locations/drivers` | 在线司机位置 |
| GET | `/admin/agents` | 智能体列表 |
| POST | `/admin/agents` | 创建智能体 |

---

## WebSocket

### 连接

```
ws://host/ws/location?token=<jwt_token>
```

### 消息格式

**司机上报位置：**
```json
{
  "type": "location_update",
  "data": { "latitude": 39.9042, "longitude": 116.4074 }
}
```

**服务器推送订单：**
```json
{
  "type": "new_order",
  "data": { "order_id": 123, "pickup": {...}, "dropoff": {...} }
}
```

---

## 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 40001 | 参数错误 |
| 40101 | 未认证 |
| 40102 | Token 过期 |
| 40301 | 无权限 |
| 40401 | 资源不存在 |
| 50001 | 服务器内部错误 |
| 50002 | AI 服务不可用 |

---

## 数据模型

### Order

```json
{
  "id": 123,
  "order_no": "RH20260624001",
  "status": 3,
  "pickup_addr": "北京市朝阳区xxx",
  "dropoff_addr": "北京市西城区xxx",
  "estimated_price": 25.5,
  "created_at": "2026-06-24T10:00:00Z"
}
```

### 订单状态

| 值 | 状态 |
|----|------|
| 1 | 待派单 |
| 2 | 派单中 |
| 3 | 已接单 |
| 4 | 前往接驾 |
| 5 | 已到达上车点 |
| 6 | 行程中 |
| 7 | 已完成 |
| 8 | 已取消 |

---

*文档版本: v1.0 | 最后更新: 2026-06-24*
