# RideHermes

> AI 驱动的智能出行平台

[![Go](https://img.shields.io/badge/Go-1.22+-00ADD8?logo=go)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)]()
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react)]()
[![MCP](https://img.shields.io/badge/MCP-Server-orange)]()

## 简介

RideHermes 是一个 **AI-First** 的智能出行平台，支持语音叫车、MCP 协议集成、实时位置追踪。

### 核心特性

- 🎤 **语音 AI 叫车** — 说出目的地即可下单
- 🔌 **MCP Server** — AI 智能体通过标准协议调用
- 🗺️ **高德地图** — 精准定位、POI 搜索、路线规划
- 📍 **实时追踪** — WebSocket 实时位置推送
- 📱 **全端覆盖** — 乘客端、司机端、管理后台

## 项目结构

```
ridehermes/
├── src/
│   ├── ride-hermes/          # Go 后端服务
│   ├── admin-web/            # React 管理后台
│   ├── passenger-app/        # Flutter 乘客端
│   ├── driver-app/           # Flutter 司机端
│   ├── ai-service/           # Python AI 服务
│   └── ride-hermes-mcp/      # MCP Server
├── docs/                     # 📚 项目文档
└── README.md                 # 本文件
```

## 快速开始

```bash
# 1. 启动数据库
cd src && docker compose up -d mysql redis

# 2. 启动后端
cd ride-hermes && go run ./cmd/server

# 3. 启动管理后台
cd admin-web && pnpm dev
```

## 📚 文档

**👉 [完整文档](./docs/README.md)**

| 文档 | 说明 |
|------|------|
| [产品需求](./docs/03-prd.md) | 功能清单、用户故事、路线图 |
| [架构设计](./docs/architecture/) | C4 模型、技术选型 |
| [API 文档](./docs/api/overview.md) | RESTful API 接口 |
| [设计系统](./docs/DESIGN.md) | 色彩、字体、组件规范 |
| [部署指南](./docs/guides/deployment.md) | 生产环境部署 |
| [开发指南](./docs/guides/development.md) | 本地开发环境 |
| [运维手册](./docs/RUNBOOK.md) | 监控、故障排查 |

## MCP Server

让 AI 智能体帮你叫车：

```bash
npx ridehermes-mcp-server setup
```

## 技术栈

| 模块 | 技术 |
|------|------|
| 后端 | Go + Gin + GORM |
| 数据库 | MySQL 8.0 + Redis 7.2 |
| 管理后台 | React 18 + Ant Design + TypeScript |
| 移动端 | Flutter 3.24 + Riverpod |
| MCP | TypeScript + Node.js |
| 地图 | 高德地图 |

## License

MIT
