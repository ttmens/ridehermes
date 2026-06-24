# RideHermes 后端服务 — 编译运行指南

## 一、前置条件

| 依赖 | 版本 | 作用 | 必须 |
|------|------|------|------|
| Go | ≥1.22 | 编译后端代码 | ✅ |
| MySQL | 8.0 | 业务数据存储 | ✅ |
| Redis | 7.2+ | 在线状态/位置缓存/派单 | ✅ |
| Docker + Compose | 任意 | 一键启动开发环境 | 推荐 |
| Python AI Service | 3.12+ | 语音识别+意图解析 | `--profile ai` |

---

## 二、快速启动（Docker Compose，推荐）

一条命令启动全部基础设施：

```bash
# 启动 MySQL + Redis + 后端
cd v0.1/src
docker compose up -d

# 如需 AI 服务
docker compose --profile ai up -d

# 运行数据库迁移
docker compose exec backend /server --migrate

# 查看日志
docker compose logs -f backend

# 停止
docker compose down
```

启动后访问：
- 后端 API: `http://localhost:8080`
- 健康检查: `http://localhost:8080/health`
- 管理员账号: `00000000000` / `admin123`

---

## 三、本地编译运行

### 3.1 准备 MySQL 和 Redis

先用 Docker 起基础设施：

```bash
docker compose up -d mysql redis
```

或手动安装并启动 MySQL 8.0、Redis 7.2。

创建数据库：

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ride_hermes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3.2 编译

```bash
cd v0.1/src/ride-hermes

# 下载依赖
go mod tidy

# 编译
make build
# 或: go build -o ./build/ride-hermes ./cmd/server

# 运行数据库迁移
go run ./cmd/server --migrate
# 或: make migrate
```

### 3.3 配置

编辑 `configs/config.yaml`，确保连接信息正确：

```yaml
database:
  host: localhost      # Docker 内改为 mysql
  port: 3306
  user: root
  password: ""         # 设为你的 MySQL 密码

redis:
  addr: localhost:6379 # Docker 内改为 redis:6379
```

### 3.4 运行

```bash
# 直接运行
go run ./cmd/server

# 或编译后运行
make build && ./build/ride-hermes
```

---

## 四、配置文件说明

### `configs/config.yaml` 全部字段

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `server.port` | HTTP 监听端口 | `8080` |
| `server.mode` | debug / release | `debug` |
| `database.host` | MySQL 地址 | `localhost` |
| `database.port` | MySQL 端口 | `3306` |
| `database.user` | 数据库用户 | `root` |
| `database.password` | 数据库密码 | `""` |
| `database.dbname` | 数据库名 | `ride_hermes` |
| `database.max_idle_conns` | 空闲连接池 | `10` |
| `database.max_open_conns` | 最大连接数 | `100` |
| `redis.addr` | Redis 地址 | `localhost:6379` |
| `redis.password` | Redis 密码 | `""` |
| `redis.db` | Redis 数据库编号 | `0` |
| `jwt.secret` | JWT 签名密钥 | 生产务必修改 |
| `jwt.access_expire` | Access Token 有效期(秒) | `7200` (2h) |
| `jwt.refresh_expire` | Refresh Token 有效期(秒) | `604800` (7d) |
| `ai_service.addr` | AI 服务地址 | `http://localhost:8001` |
| `ai_service.timeout` | AI 请求超时(秒) | `30` |
| `dispatch.response_timeout` | 派单响应超时(秒) | `15` |
| `dispatch.heartbeat_interval` | 心跳间隔(秒) | `30` |
| `dispatch.location_save_interval` | 位置持久化间隔(秒) | `10` |
| `log.level` | 日志级别 | `info` |
| `log.format` | 日志格式 (json/text) | `json` |

### 数据库表结构

迁移脚本位于 `migrations/001_init_tables.up.sql`，包含 7 张表：

| 表 | 说明 |
|----|------|
| `users` | 用户（管理员/乘客/司机） |
| `drivers` | 司机档案（证件、评分、余额） |
| `vehicles` | 车辆（车牌、品牌、车型） |
| `orders` | 订单（起终点、费用、状态） |
| `locations` | GPS 位置记录 |
| `dispatch_logs` | 派单记录（轮询历史） |
| `ai_conversations` | AI 对话记录 |

### 默认管理员

迁移脚本会插入初始管理员：

```
手机号: 00000000000
密码:   admin123
角色:   管理员 (role=1)
```

---

## 五、API 速查

### 公开接口

```
POST /api/v1/auth/login     # 登录，返回 JWT Token
POST /api/v1/auth/refresh   # 刷新 Token
GET  /health                 # 健康检查
WS   /ws/location?token=     # WebSocket 位置/派单
```

### 管理员接口 (需要管理员 Token)

```
POST   /api/v1/admin/users/passenger     # 创建乘客
POST   /api/v1/admin/users/driver        # 创建司机(含车辆)
GET    /api/v1/admin/users               # 用户列表 ?role=2&offset=0&limit=20
GET    /api/v1/admin/users/:id           # 用户详情
PUT    /api/v1/admin/users/:id/status    # 启用/禁用 {status:1|2}
GET    /api/v1/admin/drivers             # 司机列表
GET    /api/v1/admin/drivers/:id         # 司机详情(含车辆)
GET    /api/v1/admin/orders              # 全部订单 ?status=1&offset=0&limit=20
GET    /api/v1/admin/orders/:id          # 订单详情
GET    /api/v1/admin/locations/drivers   # 在线司机位置
GET    /api/v1/admin/locations/passengers # 在线乘客位置
```

### 乘客接口

```
POST /api/v1/passenger/orders            # 创建订单
GET  /api/v1/passenger/orders            # 我的订单 ?offset=0&limit=20
GET  /api/v1/passenger/orders/:id        # 订单详情
POST /api/v1/passenger/orders/:id/cancel # 取消订单
GET  /api/v1/passenger/driver-location/:order_id  # 司机位置
POST /api/v1/passenger/ai/chat           # AI 对话
GET  /api/v1/passenger/ai/sessions       # 对话历史
GET  /api/v1/passenger/user/profile      # 个人资料
PUT  /api/v1/passenger/user/profile      # 更新资料
```

### 司机接口

```
PUT  /api/v1/driver/online               # 上线 {latitude,longitude,car_type}
PUT  /api/v1/driver/offline              # 下线
POST /api/v1/driver/orders/:id/accept    # 接单
POST /api/v1/driver/orders/:id/reject    # 拒绝
POST /api/v1/driver/orders/:id/arrive    # 到达上车点
POST /api/v1/driver/orders/:id/start     # 开始行程
POST /api/v1/driver/orders/:id/complete  # 完成订单
GET  /api/v1/driver/orders               # 我的订单
GET  /api/v1/driver/orders/:id           # 订单详情
GET  /api/v1/driver/user/profile         # 个人资料
PUT  /api/v1/driver/user/profile         # 更新资料
```

---

## 六、Makefile 命令

```bash
make build        # 编译到 ./build/ride-hermes
make run          # go run ./cmd/server
make test         # 运行测试
make lint         # 代码检查
make migrate      # 运行数据库迁移
make clean        # 清理构建产物
make docker-build # 构建 Docker 镜像
make docker-run   # Docker 运行（需 .env 文件）
```

---

## 七、项目结构

```
ride-hermes/
├── cmd/server/main.go         # 程序入口 & 依��初始化
├── configs/config.yaml         # 配置文件
├── internal/
│   ├── common/                 # 统一响应/错误码
│   ├── config/                 # 配置加载 (YAML→Struct)
│   ├── middleware/             # auth / cors / logger / role
│   ├── model/                  # GORM 数据模型 × 7
│   ├── repository/             # 数据访问层 × 7
│   ├── service/                # 业务逻辑层 × 8
│   ├── handler/                # HTTP/WS 处理器 × 6
│   ├── ws/                     # WebSocket Hub + Client
│   └── router/                 # 路由注册 & 依赖注入
├── migrations/                 # SQL 迁移脚本
├── Dockerfile
├── Makefile
├── go.mod / go.sum
└── README.md
```

---

## 八、故障排查

### 数据库连接失败

```bash
# 确认 MySQL 运行
docker compose ps mysql
# 测试连接
mysql -h localhost -P 3306 -u root -p ride_hermes
```

### Redis 连接失败

```bash
docker compose ps redis
redis-cli -h localhost -p 6379 ping
```

### 迁移失败

```bash
# 先确保数据库存在
docker compose exec mysql mysql -u root -prisehermes123 -e "CREATE DATABASE IF NOT EXISTS ride_hermes;"
# 再运行迁移
go run ./cmd/server --migrate
```

### WebSocket 连接失败

确认 Nginx 配置了 WebSocket 升级（仅生产环境需要）。开发环境直接连 `ws://localhost:8080/ws/location`。

### AI 服务不可用

后端启动不依赖 AI 服务。不要 AI 服务时，对话接口返回 `50002` 错误码，不影响其他功能。
