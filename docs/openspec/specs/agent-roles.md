# Agent 角色规格

> ADDED

## 三类 Agent

| 角色 | 委托方 | 职责 | 代码/文档 |
|------|--------|------|-----------|
| **需求 Agent** | 企业/酒店/乘客 | 政策、预算、周期 Intent、批量排程 | enterprise, recurring, matching demands |
| **供给 Agent** | 司机/车队/Robotaxi | 日历、定价、Offer/Counter、接单策略 | matching offers, subscription |
| **渠道 Agent** | AI 开发者 | MCP/REST 封装 Intent | ride-hermes-mcp, `/api/v1/agent/*` |

## 责任边界

- 智能在边缘：匹配优劣由 Agent 策略决定
- 薄层不持有：排序、推荐、统一定价

## R2 扩展

- Robotaxi 供给 Agent + ODD adapter
- 人机接力：路径驶出 ODD 回落人类供给
