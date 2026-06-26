# 用户旅程地图

> Stage 4 Spec (G2) | 旅程 ID 绑定 PRD US | 最后更新: 2026-06-26

## Personas

| ID | 角色 | 目标 | 痛点 |
|----|------|------|------|
| P1 | **企业出行管理员**（需求 Agent 委托方） | 批量排程、政策合规、周期 Intent | 实时平台无法承载计划协商 |
| P2 | **订阅司机**（供给 Agent） | 自主报价、日历管理、Offer/Counter | 中心派单忽略定价策略 |
| P3 | **计划出行乘客** | Intent 声明、确认 Commit、查看缔约 | 临时叫车交互与计划场景混淆 |
| P4 | **AI 集成开发者** | MCP/Agent REST 互操作 | REST 与 A2A 语义不清 |

## 核心旅程

| 旅程ID | Persona | 阶段 | 用户行为 | 系统响应 | Touchpoint | 情绪/痛点 |
|--------|---------|------|----------|----------|------------|-----------|
| J1 | P1/P3 | 声明 | 配置周期/企业政策，提交 Intent | 硬约束发现，返回无序候选 | admin enterprise / passenger recurring | 怕政策违规 |
| J1 | P1/P3 | 协商 | 查看 Offer，Counter（可选） | 边缘 matching 多轮 | matching API | 价格不确定 |
| J1 | P1/P3 | 缔约 | 确认 Commit | 双签记录、订单状态更新 | passenger confirm | 需要可追溯 |
| J1 | P1/P3 | 执行 | 行程进行 | WS 追踪（R0 过渡） | passenger/driver app | 实时 vs 计划混淆 |
| J1 | P1/P3 | 清算 | 完单 Settle | 更新事实、订阅计费 | admin subscription | 财务对账 |
| J2 | P2 | 供给 | 收到 Intent 广播 | matching demand 通知 | driver app | 报价压力 |
| J2 | P2 | 报价 | 提交 Offer | `POST .../offers` | driver API | 策略受限 |
| J3 | P4 | 集成 | MCP/Agent 声明 Intent | 10 工具 / agent REST | MCP npm | 文档 drift |
| J3 | P4 | 确认 | 查询 Commit 状态 | ride_status / GET orders | Agent API | 状态不一致 |

## 屏幕映射

| 屏幕 | 旅程ID | 信息优先级（首屏必见） | 关联 US |
|------|--------|------------------------|---------|
| admin/enterprise | J1 | 企业政策、员工、周期 | US-1 |
| admin/subscription | J1/J2 | 计划分布、续费状态 | US-2 |
| admin/trust-scores | — | ⚠️ 过渡：客观事实摘要 | US-5 |
| passenger/recurring | J1 | 周期模式、时间窗 | US-1 |
| passenger/matching | J1 | Intent 状态、候选 Offer | US-1, US-3 |
| driver/offers | J2 | 待报价 Intent、日历 | US-2 |
| MCP tools | J3 | ride_* + maps_* | US-4 |

## 核心路径（≤3）

### 路径 1 — J1 企业周期出行

```
Intent(周期+政策) → 发现(硬约束) → Offer/Counter(边缘) → Commit → 执行(WS R0) → Settle
```

### 路径 2 — J2 司机订阅协商

```
供给 Agent 收 Intent → Offer → (Counter) → Commit → 行程状态机
```

### 路径 3 — J3 AI Agent 代叫

```
MCP ride_book / Agent POST orders → Intent 映射 → 确认 → Commit 记录
```

## 成功标准

- J1：企业管理员可在 admin 创建 enterprise + recurring，乘客侧产生 Intent
- J2：司机可对 matching demand 提交 Offer，乘客 confirm 完成 Commit
- J3：MCP 10 工具与 Agent REST 文档与 router 一致

---

*下一步：[`product/prd.md`](./prd.md)*
