# 灵犀智能 — 产品愿景

> 对外品牌：**RideHermes（灵犀智能）** | R0 过渡态  
> 全文参考：[`archive/vision-full.md`](../archive/vision-full.md)  
> ADR：[`decisions.md`](./decisions.md)

## 一句话

**AI 原生的计划性出行平台**：Agent 在边缘协商报价与缔约，薄协调层提供协议、身份事实与清算。

## 产品架构

```
┌─────────────────────────────────────────────────────────────┐
│                    厚边缘层（Agent 策略）                      │
│  需求Agent(企业/周期)  供给Agent(报价/日历)  MCP/AgentREST   │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    薄协调层（Go API）                        │
│  身份事实 · 硬约束发现 · Commit/Settle · 审计 · 合规闸门(规格) │
└───────────────────────────┬─────────────────────────────────┘
                            │
              MySQL/SQLite · Redis · ai-service(:8001)
```

## 场景边界（架构红线）

| 在范围内 | 范围外 |
|----------|--------|
| 预约、周期通勤、企业批量排程 | 秒级实时派单作为**终态** |
| 时间预算：分钟～天 | 全局实时最优调度 |
| Intent → 发现 → Offer/Counter → Commit → Settle | 中心撮合大脑 |

## 薄协调层（中心只做）

- 身份与能力背书（**客观事实**，不算分不排名）
- A2A 协议与出行意图本体
- 硬约束发现（无序候选集）
- 缔约记录与清算
- 账本、审计、争议（基于签名记录）
- 合规硬闸门（二元拒/不拒）

## 厚边缘层（Agent 做）

- 需求 Agent：企业/酒店政策、预算、周期模式、批量排程
- 供给 Agent：可用日历、定价策略、接单策略、多轮还价
- 渠道/生态 Agent：MCP、Agent REST 集成
- 信誉解读在边缘（各 Agent 自行解读中心发布的事实）

## A2A 报文（目标语义）

| 报文 | 方向 | 语义 |
|------|------|------|
| Intent | 需求 → 中心 → 广播 | 声明计划出行需求 |
| Offer | 供给 → 需求 | 供给应答 |
| Counter | 双向 | 多轮议价 |
| Commit | 双签 → 中心 | 达成并记录合同 |
| Settle | 完单 → 中心 | 走资金、更新事实 |

规格细节：[`openspec/specs/a2a-protocol.md`](../openspec/specs/a2a-protocol.md)

## 与当前代码映射（R0）

| 目标语义 | 当前实现 |
|----------|----------|
| Intent | `POST /passenger/matching/demands`、`POST /passenger/recurring-trips` |
| Offer | `POST /driver/matching/demands/:order_id/offers` |
| Commit | `POST /passenger/matching/demands/:order_id/confirm` |
| 实时派单（过渡） | `dispatch_service.go`、`POST /passenger/orders` |
| Agent 集成 | MCP v2.0（10 工具）、`/api/v1/agent/*` |

API SSOT：[`api/overview.md`](../api/overview.md)

## 模块状态（R0）

| 模块 | 状态 |
|------|------|
| A2A matching / recurring / enterprise | ✅ |
| 订阅 SaaS | ✅ |
| Agent REST + MCP v2.0 | ✅ |
| ai-service LLM+ASR | ✅ |
| 合规硬闸门 | ⏳ 规格先行 |
| 支付 Settle 网关 | ⏳ 未实现 |

---

*文档版本: v3.1 | 合并原 PRODUCT-VISION + 00-brief*
