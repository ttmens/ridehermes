# C4 组件图 - 模块划分

> Go 后端 API 内部组件划分

## 后端组件总览

```
┌─────────────────────────────────────────────────────────────────┐
│                        HTTP 层                                   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  Auth   │ │Passenger│ │ Driver  │ │  Admin  │ │  Map    │  │
│  │ Handler │ │ Handler │ │ Handler │ │ Handler │ │ Handler │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘  │
│       │           │           │           │           │         │
│  ┌────┴────┐ ┌────┴────┐                                 │
│  │WebSocket│ │ Agent   │                                 │
│  │ Handler │ │ Handler │                                 │
│  └────┬────┘ └────┬────┘                                 │
└───────┼───────────┼───────────────────────────────────────────┘
        │           │
┌───────┼───────────┼───────────────────────────────────────────┐
│       │      业务层                                            │
│  ┌────▼────────────▼──────────────────────────────────────┐  │
│  │  UserService  │ OrderService │ DispatchService         │  │
│  │  LocationService │ PriceService │ AmapService          │  │
│  │  AIService    │ AgentService │ DriverService          │  │
│  └────┬────────────┬──────────────────────────────────────┘  │
│       │            │                                            │
└───────┼────────────┼────────────────────────────────────────────┘
        │            │
┌───────┼────────────┼────────────────────────────────────────────┐
│       │       数据层                                              │
│  ┌────▼────┐ ┌────▼────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │UserRepo │ │OrderRepo│ │DriverRepo│ │LocRepo  │ │VehRepo  │ │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ │
│       │           │           │           │           │         │
│  ┌────▼───────────▼───────────▼───────────▼───────────▼────┐ │
│  │                    MySQL / Redis                         │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Handler 层 (HTTP 处理器)

| 组件 | 文件 | 职责 |
|------|------|------|
| **Auth Handler** | `auth_handler.go` | 登录、Token 刷新 |
| **Passenger Handler** | `passenger_handler.go` | 乘客叫车、订单查询 |
| **Driver Handler** | `driver_handler.go` | 司机接单、行程状态 |
| **Admin Handler** | `admin_handler.go` | 用户管理、订单管理 |
| **Map Handler** | `map_handler.go` | POI 搜索、路线规划 |
| **Agent Handler** | `agent_handler.go` | MCP 智能体认证 |
| **WS Handler** | `ws_handler.go` | WebSocket 连接管理 |

## Service 层 (业务逻辑)

| 组件 | 文件 | 职责 |
|------|------|------|
| **User Service** | `user_service.go` | 用户 CRUD、认证 |
| **Order Service** | `order_service.go` | 订单生命周期 |
| **Dispatch Service** | `dispatch_service.go` | 派单算法 |
| **Location Service** | `location_service.go` | 位置处理 |
| **Price Service** | `price_service.go` | 价格计算 |
| **Amap Service** | `amap_service.go` | 高德地图 API 封装 |
| **AI Service** | `ai_service.go` | AI 服务调用 |
| **Agent Service** | `agent_service.go` | 智能体管理 |

## Repository 层 (数据访问)

| 组件 | 文件 | 职责 |
|------|------|------|
| **User Repository** | `user_repo.go` | 用户数据访问 |
| **Order Repository** | `order_repo.go` | 订单数据访问 |
| **Driver Repository** | `driver_repo.go` | 司机数据访问 |
| **Location Repository** | `location_repo.go` | 位置数据访问 |
| **Vehicle Repository** | `vehicle_repo.go` | 车辆数据访问 |

---

## 管理后台组件

| 页面 | 路由 | 功能 |
|------|------|------|
| LoginPage | `/login` | 管理员登录 |
| DashboardPage | `/` | 数据概览 |
| PassengerList | `/passengers` | 乘客列表 |
| PassengerCreate | `/passengers/create` | 创建乘客 |
| DriverList | `/drivers` | 司机列表 |
| DriverCreate | `/drivers/create` | 创建司机 |
| DriverDetail | `/drivers/:id` | 司机详情 |
| OrderList | `/orders` | 订单列表 |
| OrderDetail | `/orders/:id` | 订单详情 |
| AgentManagement | `/agents` | 智能体管理 |
| MonitorPage | `/monitor` | 地图监控 |

---

*文档版本: v1.0 | 最后更新: 2026-06-24*
