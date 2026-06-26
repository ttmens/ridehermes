# 开发指南

> 本地开发环境 | R0 | 最后更新: 2026-06-26

## 1. 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Go | 1.21+ | 薄协调层 API |
| Node.js | 20+ | admin-web |
| pnpm | 8+ | 包管理 |
| Flutter | 3.24+ | 移动端 |
| Docker | 20+ | MySQL + Redis |
| Python | 3.12+ | ai-service（可选） |

## 2. 数据库模式

| 模式 | 配置 | 说明 |
|------|------|------|
| **SQLite（默认）** | `configs/config.yaml` `database.type: sqlite` | 本地零依赖 |
| **MySQL** | Docker + 改 type 为空/mysql | 生产一致 |

本地默认 **SQLite** + **Redis 必需**（GEO、限流、matching）。

## 3. 后端

```bash
cd src && docker compose up -d redis   # 或 mysql redis
cd ride-hermes
go run ./cmd/server --migrate
go run ./cmd/server                    # :8686
```

## 4. ai-service（边缘 Intent 解析）

```bash
cd src/ai-service
cp .env.example .env                   # LLM_BASE_URL, LLM_API_KEY, AMAP_API_KEY
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

配置 `ai_service.addr: http://localhost:8001` 于 `config.yaml`。

## 5. 管理后台

```bash
cd src/admin-web
pnpm install && pnpm dev               # :3002
```

## 6. MCP Server

```bash
cd src/ride-hermes-mcp
npm install && npm run dev
# 或 npx ridehermes-mcp-server setup
```

10 工具：5 ride + 5 maps。见 [`openspec/specs/a2a-protocol.md`](../openspec/specs/a2a-protocol.md)。

## 7. 移动端

```bash
cd src/passenger-app   # 或 driver-app
flutter pub get && flutter run
```

## 8. 文档 SSOT

修改 API 时同步 [`api/overview.md`](../api/overview.md) 与 [`audit/intended-vs-implemented.md`](../audit/intended-vs-implemented.md)。

---

*文档版本: v3.0*
