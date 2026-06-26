# 文档当前状态

> docs-hygiene SSOT | 最后更新: 2026-06-26

## 版本

| 项 | 值 |
|----|-----|
| 文档 IA | v3.1（product/ ops/ audit/ 分层） |
| 产品阶段 | **R0 过渡态** |
| 代码分支 | `feature/v2-maps-upgrade` |
| PRD | [`product/prd.md`](./product/prd.md) v3.0 |

## 读者入口

| 角色 | 首读 |
|------|------|
| 产品/PM | [`product/vision.md`](./product/vision.md) → [`product/prd.md`](./product/prd.md) |
| 集成开发 | [`api/overview.md`](./api/overview.md) |
| 架构 | [`product/decisions.md`](./product/decisions.md) → [`architecture/`](./architecture/) |
| 运维 | [`ops/runbook.md`](./ops/runbook.md) |

## 未闭合 GAP（代码）

| ID | 主题 | 状态 |
|----|------|------|
| GAP-7 | 合规硬闸门 | 规格已有，代码未实现 |
| GAP-8 | Settle 支付网关 | 未实现 |
| GAP-3 | trust-scores 过渡 | 待 R1 重构为事实发布 |

详见 [`audit/intended-vs-implemented.md`](./audit/intended-vs-implemented.md)。

## 根目录说明

- 根 [`gates.json`](../gates.json)：Hermes 流水线 harness，**非**产品文档门禁
- 产品文档门禁：[`audit/gates.json`](./audit/gates.json)

---

*文档 IA v3.1 — 产品文档见 `product/`、`ops/`、`audit/` 子目录*
