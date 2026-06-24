# ridehermes-mcp-server

RideHermes MCP Server — 让 AI 智能体帮你叫车。

通过 MCP (Model Context Protocol) 协议，为 Claude Desktop、Claude Code、openclaw、hermes 等 AI 智能体提供 5 个叫车工具。

## 用户安装

```bash
npx ridehermes-mcp-server setup
```

交互式向导会自动检测已安装的 AI 智能体并写入配置。用户只需输入 API Key 和 User ID 即可完成安装。

重启 AI 智能体后，即可通过自然语言叫车。

## 工具列表

| 工具 | 用途 | 参数 |
|------|------|------|
| `ride_estimate` | 预估行程费用和时间 | `pickup_addr`, `dropoff_addr`, `car_type?` |
| `ride_book` | 创建出行订单并自动派单 | `pickup_addr`, `dropoff_addr`, `pickup_lat?`, `pickup_lng?`, `dropoff_lat?`, `dropoff_lng?`, `car_type?`, `departure_time?` |
| `ride_status` | 查询订单状态和司机位置 | `order_id` |
| `ride_cancel` | 取消未开始的订单 | `order_id`, `reason?` |
| `ride_history` | 查询历史订单 | `limit?` |

## 前置条件

需要先获取 API Key 和 User ID。请联系管理员在 RideHermes 管理后台「智能体管理」页面生成。

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `RIDEHERMES_API_KEY` | API Key | - |
| `RIDEHERMES_USER_ID` | 用户 ID | - |
| `RIDEHERMES_API_URL` | 后端地址 | `https://ride.accseal.cn` |

## 数据流

```
AI 智能体 → stdio (JSON-RPC) → MCP Server → HTTPS → RideHermes Go 后端
              tools/call          Node.js        X-API-Key + X-User-ID
```

MCP Server 本身不访问数据库也不调用 AMap API。地址解析由 Go 后端使用平台统一的 AMap Key 完成。

## 开发

```bash
npm install
npm run build
npm run start
```

本地测试（手动发送 JSON-RPC）：

```bash
# 测试 initialize
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | node dist/index.js

# 测试 setup 向导
node dist/index.js setup
```

## 发布

### 1. 发布到 npm

```bash
cd src/ride-hermes-mcp

# 登录 npm（首次需要）
npm login

# 发布（scoped package 默认 private，需显式指定 public）
npm publish --access public
```

包体积约 8 kB 压缩，32 kB 解压，用户通过 npx 直接运行无需安装。

### 2. 版本更新

```bash
npm version patch   # 1.0.0 → 1.0.1
npm run build
npm publish --access public
```

用户端通过 `npx @ridehermes/mcp-server@latest` 自动获取最新版本。

### 3. 包结构

```
发布的 npm 包内容 (files: ["dist", "README.md"]):
├── dist/
│   ├── index.js          # MCP Server 入口 (bin: ride-hermes-mcp)
│   ├── hermes-client.js   # RideHermes API HTTP 客户端
│   └── setup.js           # 交互式安装向导
├── package.json
└── README.md
```

## License

MIT
