# RideHermes 文档

> 唯一导航入口 | [当前状态](./CURRENT-STATUS.md)

## L1 产品

| 文档 | 说明 |
|------|------|
| [product/vision.md](./product/vision.md) | 产品愿景（A2A、薄/厚层） |
| [product/prd.md](./product/prd.md) | PRD v3 八段式 |
| [product/journey.md](./product/journey.md) | 用户旅程 J1–J3 |
| [product/context.md](./product/context.md) | 背景与不变量 |
| [product/decisions.md](./product/decisions.md) | ADR-001～007 |
| [product/analysis.md](./product/analysis.md) | 方案论证（双轨过渡） |

## L2 架构

| 文档 | 说明 |
|------|------|
| [architecture/c4-context.md](./architecture/c4-context.md) | L1 上下文 |
| [architecture/c4-container.md](./architecture/c4-container.md) | L2 容器 |
| [architecture/c4-component.md](./architecture/c4-component.md) | L3 组件 |

## L3 接口与规格

| 文档 | 说明 |
|------|------|
| [api/overview.md](./api/overview.md) | REST + A2A + MCP（**API SSOT**） |
| [openspec/specs/a2a-protocol.md](./openspec/specs/a2a-protocol.md) | 五报文 + 意图本体 |
| [openspec/specs/agent-roles.md](./openspec/specs/agent-roles.md) | 三类 Agent |
| [openspec/specs/compliance-gates.md](./openspec/specs/compliance-gates.md) | 合规硬闸门 |
| [openspec/specs/trust-facts.md](./openspec/specs/trust-facts.md) | 事实 vs 评分 |
| [openspec/proposal.md](./openspec/proposal.md) | 变更提案 |
| [openspec/tasks.md](./openspec/tasks.md) | 文档任务清单 |

## L4 设计

| 文档 | 说明 |
|------|------|
| [design/DESIGN.md](./design/DESIGN.md) | 视觉规范 + 服务等级 UX |

## L5 工程与运维

| 文档 | 说明 |
|------|------|
| [guides/development.md](./guides/development.md) | 本地开发 |
| [ops/deployment.md](./ops/deployment.md) | 部署 |
| [ops/runbook.md](./ops/runbook.md) | 运维 |

## L6 审计

| 文档 | 说明 |
|------|------|
| [audit/intended-vs-implemented.md](./audit/intended-vs-implemented.md) | 意图 vs 实现 |
| [audit/gates.json](./audit/gates.json) | 文档门禁 |

## 归档

| 文档 | 说明 |
|------|------|
| [archive/vision-full.md](./archive/vision-full.md) | 灵犀技术方案全文 |

---

## 快速开始

```bash
cd src && docker compose up -d mysql redis
cd ride-hermes && go run ./cmd/server --migrate && go run ./cmd/server
cd admin-web && pnpm dev
```

| 服务 | 端口 |
|------|------|
| Go API | 8686 |
| admin-web | 3002 |
| ai-service | 8001 |

---

*对齐日期: 2026-06-26 | docs IA v3.1*
