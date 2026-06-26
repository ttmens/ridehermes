# 02-analysis.md — 方案论证

> Stage 3 Analysis | 最后更新: 2026-06-26

## 背景

docs 与 [`product/vision.md`](./vision.md)、M1–M3 代码三方脱节。需选定文档演进策略，而非仅补 API 字段。

## 方案选项

### 选项 A：愿景完整收敛

**描述**：文档与代码同步向 A2A 计划性目标态收敛；实时派单、中心 matching 下线或边缘化。

| 维度 | 评估 |
|------|------|
| 优点 | 与灵犀方案 100% 一致；架构清晰 |
| 缺点 | 工程量大；现有乘客/司机实时路径断裂 |
| 适用 | 有专门重构 sprint |

### 选项 B：双轨过渡（**推荐，已采纳**）

**描述**：PRD 明确 R0 过渡态 / R1 目标态；文档建立 REST ↔ A2A 映射；保留 dispatch/WS 但标过渡。

| 维度 | 评估 |
|------|------|
| 优点 | 可执行；可审计；不破坏现有集成 |
| 缺点 | 需 discipline 防止文档再 drift |
| 适用 | 当前棕地 Refine |

### 选项 C：仅 factual drift 修补

**描述**：只更新路由表、模块数量、MCP 工具数。

| 维度 | 评估 |
|------|------|
| 优点 | 最快 |
| 缺点 | **不解决产品命题错误**；禁止作为终态 |
| 适用 | 临时 hotfix only |

## 推荐结论

采用 **选项 B**，配合：

- [`decisions.md`](./decisions.md) ADR-001～007
- [`audit/intended-vs-implemented.md`](../audit/intended-vs-implemented.md) 差距表
- [`openspec/`](./openspec/) 增量规格

## 架构分层（摘要）

```
薄协调层: 身份事实 | 发现(硬约束) | 缔约/清算 | 审计 | 合规闸门
厚边缘层: 需求Agent | 供给Agent | MCP/AgentREST | ai-service协商策略
```

## 风险（Pre-mortem 摘要）

| 类型 | 描述 | 处置 |
|------|------|------|
| Tiger | docs 继续写「中心派单/信誉评分」为终态 | PRD 不变量 + openspec |
| Elephant | R0 实时与 R1 计划性长期共存 | ADR-002 里程碑 |
| Paper Tiger | 「语音叫车」作为唯一差异化 | 降为 Intent 入口之一 |

## 下一步

→ Stage 4：`product/journey.md` → `product/prd.md` → openspec specs
