# RideHermes 项目文档

> AI 驱动的智能出行平台

## 📚 文档导航

### 产品文档
| 文档 | 说明 |
|------|------|
| [00-brief.md](./00-brief.md) | 项目简介与愿景 |
| [CONTEXT.md](./CONTEXT.md) | 项目背景与关键决策 |
| [03-prd.md](./03-prd.md) | 产品需求文档 |
| [DESIGN.md](./DESIGN.md) | 设计系统规范 |

### 架构文档
| 文档 | 说明 |
|------|------|
| [architecture/c4-context.md](./architecture/c4-context.md) | C4 上下文图 - 系统边界 |
| [architecture/c4-container.md](./architecture/c4-container.md) | C4 容器图 - 技术选型 |
| [architecture/c4-component.md](./architecture/c4-component.md) | C4 组件图 - 模块划分 |

### 技术文档
| 文档 | 说明 |
|------|------|
| [api/overview.md](./api/overview.md) | API 接口概述 |
| [guides/deployment.md](./guides/deployment.md) | 部署指南 |
| [guides/development.md](./guides/development.md) | 开发指南 |

### 运维文档
| 文档 | 说明 |
|------|------|
| [RUNBOOK.md](./RUNBOOK.md) | 运维手册 |

---

## 🏗️ 项目结构

```
ridehermes/
├── src/
│   ├── ride-hermes/          # Go 后端服务
│   ├── admin-web/            # React 管理后台
│   ├── passenger-app/        # Flutter 乘客端
│   ├── driver-app/           # Flutter 司机端
│   ├── ai-service/           # Python AI 服务
│   └── ride-hermes-mcp/      # TypeScript MCP Server
├── docs/                     # 本文档目录
├── docker-compose.yml        # Docker 编排
└── README.md                 # 项目根文档
```

## 🚀 快速开始

```bash
# 1. 启动基础设施
cd src && docker compose up -d

# 2. 启动后端
cd ride-hermes && go run ./cmd/server

# 3. 启动管理后台
cd admin-web && pnpm dev

# 4. 访问
# 管理后台: http://localhost:3002
# API: http://localhost:8686
```

---

*最后更新: 2026-06-24*
