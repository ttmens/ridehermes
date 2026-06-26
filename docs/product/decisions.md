# 架构决策记录 (ADR)

> Stage 1 Align (G1) | 最后更新: 2026-06-26

## ADR-001：产品命名策略

**决策**：对外技术品牌 **RideHermes**，中文产品名 **灵犀智能**；愿景 SSOT 为 [`product/vision.md`](./vision.md)。

**理由**：仓库与 npm/MCP 包已用 RideHermes；灵犀方案为内部愿景 SSOT。

**状态**：已采纳

---

## ADR-002：场景边界 — R0 双轨过渡

**决策**：R0（当前）保留实时派单 + WebSocket 追踪作为**过渡能力**；文档与 PRD 明确标注；R1 目标态以计划性 A2A 协商为主，裁剪秒级中心派单叙事。

**理由**：代码已完整实现 dispatch；一次性下线会破坏现有路径。选项 B（双轨过渡）见 [`analysis.md`](./analysis.md)。

**状态**：已采纳

---

## ADR-003：A2A 命名 — 文档映射，暂不 rename 代码

**决策**：代码路径保持 `matching/demands|offers|confirm`；文档与 openspec 建立 REST ↔ A2A 语义映射表，不强制本轮 rename API。

**理由**：棕地最小破坏；集成方依赖现有路由。

**状态**：已采纳

---

## ADR-004：信誉分 — 过渡保留，目标态边缘解读

**决策**：admin `trust-scores` 保留为 R0 运维视图；文档标 ⚠️ 过渡实现。目标态：中心只发布签名客观事实（完单数、取消率等），各 Agent 边缘自行解读，中心不算分不排名。

**理由**：违反不变量 #1 的现有 UI 需渐进迁移，非本轮删除。

**状态**：已采纳

---

## ADR-005：PRD 重心 — B 端需求 Agent + 供给协商优先

**决策**：Stage 4 Spec 中 ≤5 US 优先覆盖：企业周期 Intent、司机 Offer/Counter、Commit/Settle、MCP/Agent 互操作、合规硬闸门（未实现标 Elephant）。

**理由**：灵犀方案明确 B 端为架构承重柱；M1–M3 代码已有 enterprise/recurring/subscription。

**状态**：已采纳

---

## ADR-006：MCP 与 Agent REST 双轨

**决策**：MCP Server v2.0（10 工具）与 `/api/v1/agent/*` 并列文档化，均为厚边缘 Agent 对外能力；薄层不持有业务智能。

**状态**：已采纳

---

## ADR-007：合规硬闸门 — 规格先行，实现后续

**决策**：`openspec/specs/compliance-gates.md` 定义疲劳二元硬拒产品规格；代码未实现前 PRD 标 Elephant，禁止标 ✅。

**状态**：已采纳
