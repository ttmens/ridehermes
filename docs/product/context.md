# 项目背景

> 对齐 [`vision.md`](./vision.md) 与 [`decisions.md`](./decisions.md)  
> 最后更新: 2026-06-26

## 问题陈述

1. **计划性出行无法协商**：中心化实时派单无法承载企业批量排程、周期通勤、多轮报价/还价
2. **AI 集成语义不清**：需要 A2A / MCP / Agent REST，而非仅 REST 订单 CRUD
3. **中心过度智能**：排序、评分、撮合集中在中心，与边缘协商方向相悖
4. **合规无单一真相**：疲劳、法定时长等需薄层硬闸门 + 派生事实

## 解决方案摘要

**灵犀智能 / RideHermes** = AI 原生计划性出行平台（详见 [`vision.md`](./vision.md)）。

R0 过渡态仍保留实时派单与 WebSocket 追踪（ADR-002，见 [`decisions.md`](./decisions.md)）。

## 技术栈

| 模块 | 技术 |
|------|------|
| 薄层 API | Go + Gin + GORM |
| 数据 | MySQL / SQLite + Redis |
| 移动端 | Flutter |
| 管理后台 | React + Ant Design |
| 边缘 AI | Python FastAPI |
| Agent | MCP v2.0 + Agent REST |

## 架构不变量

1. 中心永不排序/推荐  
2. A2A 只服务计划性出行（R0 实时为过渡）  
3. 边缘是责任边界  
4. 硬闸门必须二元  
5. 中心只摄派生事实  

## 假设与风险

| 假设 | 风险 | 缓解 |
|------|------|------|
| 文档与代码对齐 | drift | [`audit/intended-vs-implemented.md`](../audit/intended-vs-implemented.md) |
| 实时能力长期共存 | 薄中心坍塌 | ADR-002 R1 计划 |
| trust-scores | 误导集成方 | ADR-004 |
| 合规硬闸门未实现 | 监管缺口 | `openspec/specs/compliance-gates.md` |

## 约束

- 地图：高德（国内）
- 部署：Docker + PM2；本地 SQLite 可选

## 成功指标

- [x] product/ 文档 SSOT 分层
- [x] PRD v3 + journey + C4
- [ ] 合规硬闸门代码（R1+）

---

*架构决策全文见 [`decisions.md`](./decisions.md)*
