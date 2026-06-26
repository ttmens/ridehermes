# Proposal: RideHermes 产品文档 AI 原生对齐

> openspec | Stage 3 | 最后更新: 2026-06-26

## Why

- docs 与 [`product/vision.md`](../product/vision.md)、M1–M3 代码三方脱节
- PRD v2.0 仍为「实时叫车 + 语音」叙事，违反 A2A 计划性产品命题
- 集成方无法从文档理解 Intent/Offer/Commit 语义

## What changes

| 产物 | 变更 |
|------|------|
| `product/vision.md` | 愿景 SSOT（合并 brief + PRODUCT-VISION） |
| `product/journey.md` | ≥3 Persona、≤3 核心路径 |
| `product/prd.md` | v3 八段式 + ≤5 US |
| `architecture/c4-*.md` | 薄/厚分层 |
| `api/overview.md` | A2A 语义映射 |
| `openspec/specs/*` | A2A、Agent 角色、合规、API 语义 |
| `api/overview.md` | REST↔A2A 映射 + 全路由 |

## Impact

- 影响 `docs/*` 全部产品文档
- **本轮不改代码**；代码差距登记于 [`audit/intended-vs-implemented.md`](../audit/intended-vs-implemented.md)
- 运维 guides 最小更新（多服务拓扑）

## Acceptance scenarios

1. 任意开发者可读 PRD + journey 理解 R0/R1 边界
2. MCP 集成方找到 10 工具与 Agent REST 对照表
3. 无文档将「中心排序/评星」描述为目标态终局
4. GAP-1～10 均有处置说明

## Out of scope

- 支付网关实现
- 合规硬闸门代码
- Robotaxi Apollo 集成代码
