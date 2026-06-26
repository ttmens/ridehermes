# 意图 vs 实现 — 三方差距审计

> Phase 0 产物 | 最后更新: 2026-06-26  
> SSOT：**愿景** [`product/vision.md`](../product/vision.md) · **文档** `docs/*` · **代码** `src/ride-hermes/`

## 审计方法

每条记录对比：**灵犀方案目标态** | **docs 声明** | **代码证据** | **处置**

| ID | 主题 | 方案目标 | docs 声明（旧） | 代码现实 | 处置 |
|----|------|----------|-----------------|----------|------|
| GAP-1 | 场景边界 | 仅计划性出行（分钟～天） | 实时派单/追踪 P0 ✅ | `dispatch_service.go` + WS 完整 | **过渡态**；PRD R0 标注；R1 裁剪秒级调度 |
| GAP-2 | 撮合位置 | 边缘 A2A 协商 | 中心派单 | `matching_service.go` + `router.go` matching 路由 | 文档映射 Intent/Offer/Commit；代码待 R1 边缘化 |
| GAP-3 | 中心排序 | 禁止排序/评分 | admin 信誉分 | `trust_score_handler.go` + admin 页 | ⚠️ **过渡实现**；目标改为边缘解读客观事实 |
| GAP-4 | 身份背书 | 中心只签名客观事实 | 无 | TrustScore/Evaluation 模型 | Spec `trust-facts.md`；中心发布事实、边缘解读 |
| GAP-5 | MCP 工具 | 边缘 Agent 接口 | 「5 工具」 | MCP v2.0 **10 工具** | [`api/overview.md`](../api/overview.md) |
| GAP-6 | B 端承重 | 需求 Agent 政策/批量 | 无 | enterprise + recurring API | Journey P1 + US-1 |
| GAP-7 | 合规闸门 | 疲劳二元硬拒 | 无 | 未实现 | PRD Elephant；勿标已实现 |
| GAP-8 | 缔约清算 | Commit/Settle 双签 | 传统订单 | matching confirm 部分存在 | 状态机 + A2A 语义映射 |
| GAP-9 | 语音 AI | 边缘协商辅助 | 语音叫车 P0 | ai-service LLM+ASR | 定位为 Intent 声明入口，非核心差异化 |
| GAP-10 | Admin stub | 完整运营能力 | 部分功能 ✅ | `missing_handlers.go` 返回空/stub | PRD 标 ⏳ 或过渡；不标 ✅ |

## 架构不变量（产品护栏）

1. **中心永不排序/推荐**
2. **A2A 只服务计划性出行**（实时能力为 R0 过渡）
3. **边缘是责任边界**
4. **硬闸门必须二元**（拒/不拒）
5. **中心只摄派生事实**

## 复审记录

| 日期 | 阶段 | 结果 |
|------|------|------|
| 2026-06-26 | Phase 0 初建 | 10 条 GAP 已登记 |
| 2026-06-26 | Stage 6 Ship | 全量 docs v3 对齐完成；合规闸门/支付仍 R1+ |

## OpenAPI（可选，R1）

未在本轮生成；API SSOT 为 [`api/overview.md`](./api/overview.md) + `router.go`。R1 可考虑 swaggo 或手写 openapi.yaml。
