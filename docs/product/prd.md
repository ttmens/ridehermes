# RideHermes / 灵犀智能 产品需求文档 (PRD)

> 版本: **v3.0 (AI 原生对齐)** | 状态: **R0 过渡态** | 对齐: [`vision.md`](./vision.md) + M1–M3 代码  
> 最后更新: 2026-06-26 | 旅程: [`journey.md`](./journey.md)

---

## 1. Summary

灵犀智能（RideHermes）是 **AI 原生的计划性出行平台**：需求 Agent 与供给 Agent 在边缘完成 Offer/Counter 协商，薄协调层提供 A2A 协议、身份客观事实、硬约束发现与缔约清算。R0 保留实时派单与 WebSocket 追踪作为过渡能力（ADR-002）。

---

## 2. Contacts

| 角色 | 职责 |
|------|------|
| 产品 | PRD、旅程、openspec 维护 |
| 架构 | C4、decisions、不变量 |
| 研发 | Go API / Flutter / ai-service / MCP |

---

## 3. Background

- **为何现在**：M1–M3 已实现 matching、enterprise、subscription、recurring，但 docs 仍描述 v2.0 实时叫车 MVP
- **变化**：吸收 [`archive/vision-full.md`](../archive/vision-full.md) 产品特性，建立 R0/R1 双轨文档 SSOT
- **约束**：本轮以文档对齐为主，合规硬闸门、支付网关代码后续迭代

---

## 4. Objective & Key Results

| KR | 目标 | 验收 |
|----|------|------|
| KR1 | 核心 API 100% 具 A2A 语义映射 | [`api/overview.md`](../api/overview.md) 覆盖 router |
| KR2 | 零条文档将「中心排序/评星」标为目标态 | PRD + C4 + api 审查通过 |
| KR3 | 旅程 ↔ US 可追溯 | 本 PRD US 绑定 J1–J3 |
| KR4 | MCP/Agent 双轨文档化 | 10 工具 + Agent REST 列表 |

---

## 5. Market Segments

| 细分 | 描述 | 优先级 |
|------|------|--------|
| **B 端机构** | 企业/酒店出行政策、批量排程 | P0（承重） |
| **订阅司机** | 供给侧 SaaS、自主报价策略 | P0 |
| **计划乘客** | 周期通勤、预约 Intent | P1 |
| **AI 集成方** | MCP、Agent REST 消费者 | P1 |

---

## 6. Value Propositions

| 价值 | 说明 |
|------|------|
| 计划性批量协商 | 分钟～天级时间窗，非秒级抢单 |
| 边缘自主定价 | Offer/Counter 在供给 Agent，中心不定价 |
| Agent 互操作 | A2A 语义 + MCP 10 工具 + Agent REST |
| 可审计缔约 | Intent/Offer/Commit 链路可追溯 |
| 合规硬闸门（目标） | 疲劳等二元拒/不拒于发现/缔约 |

---

## 7. Solution

### 7.1 用户旅程

见 [`journey.md`](./journey.md) — 路径 J1/J2/J3。

### 7.2 关键功能

| 模块 | R0 状态 | 目标态 |
|------|---------|--------|
| Intent 声明 | ✅ recurring + matching demands | 完整意图本体字段 |
| 硬约束发现 | ✅ matching + dispatch（过渡） | 仅硬约束、无序候选 |
| Offer/Counter | ✅ matching offers | 多轮收敛策略 |
| Commit/Settle | ✅ confirm + order 状态机 | 双签 + 清算 |
| 企业 B2B | ✅ enterprise admin/API | 需求 Agent 政策 |
| 订阅 SaaS | ✅ subscription | 供给 Agent 计费 |
| 信誉/评价 | ⚠️ trust-scores 过渡 | 边缘解读中心事实 |
| 合规闸门 | ❌ 未实现 | 二元硬拒 |
| Robotaxi/ODD | ❌ 未实现 | R2 |

### 7.3 技术

见 [`architecture/c4-context.md`](./architecture/c4-context.md) L1–L3。

### 7.4 假设

- B 端 enterprise 数据可由 admin 维护
- ai-service 可独立部署（`:8001`）
- Redis 可用于 GEO 与限流

---

## 8. Release

| 阶段 | 内容 |
|------|------|
| **R0 过渡态（当前）** | 文档 SSOT 对齐；matching/enterprise/subscription/recurring；实时 dispatch/WS 标注过渡 |
| **R1 目标态** | 裁剪中心排序叙事；trust 改为事实发布；合规闸门 MVP |
| **R2** | Robotaxi 供给 Agent、ODD 人机接力 |

---

## 用户故事（≤5，旅程绑定）

### US-1 · J1 · 企业周期 Intent

**作为**企业出行管理员，**我想要**配置周期模式与企业出行政策并声明 Intent，**以便**批量计划出行可被供给 Agent 报价。

**验收标准：**
- [x] admin 企业 CRUD + 员工管理
- [x] passenger recurring-trips API
- [x] matching demands 创建 Intent
- [ ] 完整意图本体（服务等级、价格上限）字段暴露

### US-2 · J2 · 供给 Offer/Counter

**作为**订阅司机，**我想要**对 Intent 提交 Offer 并参与还价，**以便**自主定价策略生效。

**验收标准：**
- [x] `POST /driver/matching/demands/:order_id/offers`
- [x] 司机订阅 plans（admin/subscription）
- [ ] 文档明确中心不排序候选（R1 代码约束）

### US-3 · J1 · Commit 缔约

**作为**计划乘客，**我想要**确认 Commit 并查看缔约记录，**以便**行程可追溯。

**验收标准：**
- [x] `POST /passenger/matching/demands/:order_id/confirm`
- [x] 订单状态机 1–8（见 api/overview）
- [ ] Settle 资金清算（未实现）

### US-4 · J3 · Agent 互操作

**作为**AI 集成开发者，**我想要**通过 MCP 或 Agent REST 声明 Intent，**以便**我的 Agent 可代用户叫车。

**验收标准：**
- [x] MCP v2.0：5 ride + 5 maps 工具
- [x] `/api/v1/agent/*` + X-API-Key
- [x] admin/passenger agent keys 管理

### US-5 · J1 · 合规硬闸门（Elephant）

**作为**合规官，**我想要**疲劳触达法定上限时在缔约环节二元拒绝，**以便**不满足监管要求。

**验收标准：**
- [ ] 发现/缔约环节二元拒/不拒
- [ ] 不演化为「疲劳评分排序」
- [x] 规格见 `openspec/specs/compliance-gates.md`

---

## 附录 A：Pre-mortem

| 类型 | 风险 | 缓解 |
|------|------|------|
| **Tiger** | docs 继续写中心派单/评星为终态 | 本 PRD 不变量 + [`audit/intended-vs-implemented.md`](../audit/intended-vs-implemented.md) |
| **Elephant** | R0 实时与 R1 计划性长期共存 | ADR-002 里程碑 |
| **Paper Tiger** | 语音叫车为唯一差异化 | 降为 Intent 入口之一 |

## 附录 B：架构不变量

1. 中心永不排序/推荐  
2. A2A 只服务计划性出行（R0 实时标注过渡）  
3. 边缘是责任边界  
4. 硬闸门二元  
5. 中心只摄派生事实  

---

*文档版本: v3.0 | G2 Spec 完成*
