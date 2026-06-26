# RideHermes API 文档

> RESTful API · A2A 语义映射 · SSOT: `router.go`  
> 最后更新: 2026-06-26 | 版本: **v3.0 (R0 过渡态)**

## 基础信息

| 项目 | 值 |
|------|-----|
| **Base URL** | `https://ride.accseal.cn/api/v1`（生产）/ `http://localhost:8686/api/v1`（本地） |
| **协议** | HTTPS / JSON |
| **认证** | JWT Bearer（用户）/ X-API-Key + X-User-ID（Agent REST） |

## A2A 语义映射（R0）

| A2A 报文 | REST 端点 |
|----------|-----------|
| Intent | `POST /passenger/matching/demands`, `POST /passenger/recurring-trips` |
| Offer | `POST /driver/matching/demands/:order_id/offers` |
| Commit | `POST /passenger/matching/demands/:order_id/confirm` |
| 实时过渡 | `POST /passenger/orders` + dispatch（非目标态核心） |

详见 [`openspec/specs/a2a-protocol.md`](../openspec/specs/a2a-protocol.md)。

---

## 公开接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查（根路径 `/health`） |
| POST | `/auth/login` | 登录 |
| POST | `/auth/login-or-register` | 登录或注册 |
| POST | `/auth/refresh` | 刷新 Token |
| GET | `/ws/location` | WebSocket 位置与订单推送（R0 过渡） |

---

## 乘客接口

> 角色：Passenger (role=2)

### A2A / 计划性

| 方法 | 路径 | A2A | 说明 |
|------|------|-----|------|
| POST | `/passenger/matching/demands` | Intent | 创建出行需求 |
| GET | `/passenger/matching/demands/:order_id/matches` | — | 查看匹配候选 |
| POST | `/passenger/matching/demands/:order_id/confirm` | Commit | 确认缔约 |
| POST | `/passenger/recurring-trips` | Intent | 周期出行 |
| GET | `/passenger/recurring-trips` | — | 周期列表 |
| DELETE | `/passenger/recurring-trips/:id` | — | 删除周期 |

### 订单（含 R0 实时过渡）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/passenger/orders` | 创建订单（可触发 dispatch） |
| GET | `/passenger/orders` | 订单列表 |
| GET | `/passenger/orders/:id` | 订单详情 |
| POST | `/passenger/orders/:id/cancel` | 取消 |
| GET | `/passenger/driver-location/:order_id` | 司机位置 |

### AI / 个人

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/passenger/ai/chat` | AI 文本对话（代理 ai-service） |
| GET | `/passenger/ai/sessions` | 会话历史 |
| GET | `/passenger/user/profile` | 个人资料 |
| PUT | `/passenger/user/profile` | 更新资料 |

### Agent Key 自助

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/passenger/agent/keys` | 生成 API Key |
| GET | `/passenger/agent/keys` | 列表 |
| DELETE | `/passenger/agent/keys/:id` | 撤销 |

---

## 司机接口

> 角色：Driver (role=3)

| 方法 | 路径 | A2A | 说明 |
|------|------|-----|------|
| PUT | `/driver/online` | — | 上线 |
| PUT | `/driver/offline` | — | 下线 |
| POST | `/driver/matching/demands/:order_id/offers` | Offer | 提交报价 |
| POST | `/driver/orders/:id/accept` | — | 接单 |
| POST | `/driver/orders/:id/reject` | — | 拒单 |
| POST | `/driver/orders/:id/arrive` | — | 到达 |
| POST | `/driver/orders/:id/start` | — | 开始行程 |
| POST | `/driver/orders/:id/complete` | — | 完成 |
| GET | `/driver/orders` | — | 订单列表 |
| GET | `/driver/orders/:id` | — | 详情 |
| POST | `/driver/subscriptions` | — | 创建订阅 |
| GET | `/driver/subscriptions` | — | 当前订阅 |
| GET/PUT | `/driver/user/profile` | — | 资料 |

---

## 管理员接口

> 角色：Admin (role=1)

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/admin/users/passenger` | 创建乘客 |
| POST | `/admin/users/driver` | 创建司机 |
| GET | `/admin/users` | 用户列表 |
| GET | `/admin/users/:id` | 用户详情 |
| PUT | `/admin/users/:id/status` | 启用/禁用 |
| GET | `/admin/drivers` | 司机列表 |
| GET | `/admin/drivers/:id` | 司机详情 |
| PUT | `/admin/drivers/:id` | 更新司机 |
| GET | `/admin/orders` | 全部订单 |
| GET | `/admin/orders/:id` | 订单详情 |
| GET | `/admin/locations/drivers` | 司机位置 |
| GET | `/admin/locations/passengers` | 乘客位置 |
| GET | `/admin/agents/credentials` | Agent 凭证列表 |
| POST | `/admin/agents/credentials` | 生成凭证 |
| PUT | `/admin/agents/credentials/:id/revoke` | 撤销 |
| GET | `/admin/agents/logs` | Agent 调用日志 |
| GET | `/admin/subscriptions` | 订阅列表 |
| GET | `/admin/subscriptions/stats` | 订阅统计 |
| GET | `/admin/trust-scores` | 信誉（⚠️ R0 过渡） |
| GET | `/admin/enterprises` | 企业列表 |
| POST | `/admin/enterprises` | 创建企业 |
| GET | `/admin/enterprises/:id/employees` | 员工 |
| GET | `/admin/enterprises/:id/bill` | 账单 |
| GET | `/admin/notifications` | 通知（R0 stub） |

---

## Agent REST API

> X-API-Key 认证 · 60 req/min

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/agent/orders/estimate` | 多车型预估 |
| POST | `/agent/orders` | 创建订单 |
| GET | `/agent/orders` | 列表 |
| GET | `/agent/orders/:id` | 详情 |
| POST | `/agent/orders/:id/cancel` | 取消 |

---

## 地图接口

> 任意已认证用户

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/maps/poi/search` | POI 搜索 |
| GET | `/maps/poi/around` | 周边 POI |
| GET | `/maps/place/suggestion` | 输入提示 |
| GET | `/maps/static` | 静态地图 URL |
| GET | `/maps/route` | 路线规划 |

---

## MCP Server v2.0 工具（10）

| 工具 | 类型 |
|------|------|
| ride_estimate, ride_book, ride_status, ride_cancel, ride_history | 出行 |
| maps_poi_search, maps_place_around, maps_place_suggestion, maps_static_map, maps_route_plan | 地图 |

---

## WebSocket

```
ws://host/ws/location?token=<jwt>
```

**司机上报：** `{ "type": "location_update", "data": { "latitude", "longitude" } }`  
**推送订单：** `{ "type": "new_order", "data": { "order_id", "pickup", "dropoff" } }`

---

## 订单状态

| 值 | 状态 |
|----|------|
| 1 | 待派单 |
| 2 | 已派单 |
| 3 | 司机已确认 |
| 5 | 等待上车 |
| 6 | 行程中 |
| 7 | 已完成 |
| 8 | 已取消 |

## 订单状态与过渡 API

订单状态即 A2A 执行阶段在 R0 的映射：

| 值 | 名称 | A2A 阶段 |
|----|------|----------|
| 1 | 待派单 | Intent / 发现 |
| 2 | 已派单 | 发现 |
| 3 | 司机已确认 | Commit 后 |
| 5 | 等待上车 | 执行 |
| 6 | 行程中 | 执行 |
| 7 | 已完成 | Settle |
| 8 | 已取消 | — |

注：status=4 已从代码移除。

**R0 过渡 API（非目标态核心）：**

| API | 说明 |
|-----|------|
| `POST /passenger/orders` + dispatch | 实时派单过渡 |
| `GET /ws/location` | WebSocket 追踪过渡 |

**Agent 双轨：** MCP 10 工具（stdio/HTTP）+ Agent REST `/api/v1/agent/*`（X-API-Key，60 req/min）。

---

## 错误码

| 码 | 说明 |
|----|------|
| 0 | 成功 |
| 40001 | 参数错误 |
| 40101 | 未认证 |
| 40102 | Token 过期 |
| 40301 | 无权限 |
| 40401 | 不存在 |
| 50001 | 服务器错误 |
| 50002 | AI 服务不可用 |

---

*文档版本: v3.1 | 重组后 SSOT*
