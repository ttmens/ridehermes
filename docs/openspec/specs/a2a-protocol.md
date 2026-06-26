# A2A 协议规格

> ADDED | 目标态语义 | R0 通过 REST 映射实现

## 五报文

| 报文 | HTTP 映射 (R0) | 说明 |
|------|----------------|------|
| **Intent** | `POST /passenger/matching/demands`, `POST /passenger/recurring-trips` | 声明计划需求 |
| **Offer** | `POST /driver/matching/demands/:order_id/offers` | 供给应答 |
| **Counter** | 多轮 matching（R0 简化） | 还价 |
| **Commit** | `POST /passenger/matching/demands/:order_id/confirm` | 双签缔约 |
| **Settle** | 订单完成 + 订阅计费 | 清算（资金未接网关） |

## 出行意图本体（字段）

| 字段 | 必填 | R0 实现 |
|------|------|---------|
| 时间窗 earliest/latest | 推荐 | departure_time（部分） |
| 起讫点 | 是 | pickup/dropoff |
| 车型 car_type | 是 | 1/2/3 |
| 服务等级 | 否 | 未暴露 API |
| 价格上限 | 否 | estimated_price |
| 周期模式 | 否 | recurring_trips |

## 不变量

- 发现返回**无序**候选；排序在边缘 Agent 策略内完成
- 中心不参与 Offer/Counter 定价逻辑
