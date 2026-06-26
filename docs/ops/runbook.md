# RideHermes 运维手册

> 多服务拓扑 · R0 | 最后更新: 2026-06-26

## 1. 系统架构

```
生产 / 预发
├── PM2
│   ├── rh-api      Go 薄协调层     :8686
│   ├── rh-web      admin-web       :3002
│   └── rh-ai       ai-service      :8001（可选）
├── Docker
│   ├── mysql:8.0                     :3306
│   └── redis:7.2                     :6379
└── MCP / Agent REST（外部集成，非常驻 PM2）
```

## 2. 服务职责

| 服务 | 层级 | 职责 |
|------|------|------|
| rh-api | 薄协调层 | 身份、发现、matching、缔约、审计 |
| rh-ai | 厚边缘 | LLM 意图、ASR |
| rh-web | 运维 UI | 企业、订阅、Agent、事实监控 |
| redis | 基础设施 | GEO、限流 |
| mysql | 持久化 | 18+ 实体 |

## 3. 健康检查

```bash
curl http://localhost:8686/health
curl http://localhost:8001/health    # ai-service 若部署
curl http://localhost:3002           # admin 静态
```

清单：

- [ ] `/health` OK
- [ ] Redis PING
- [ ] MySQL 连接
- [ ] WebSocket `/ws/location`（R0 过渡）
- [ ] Agent REST 限流正常

## 4. 日志

```bash
pm2 logs rh-api --lines 100
pm2 logs rh-ai --lines 100
docker logs mysql --tail 50
```

## 5. 部署

```bash
git pull
cd src/ride-hermes && go build -o build/ride-hermes ./cmd/server && pm2 restart rh-api
cd src/admin-web && pnpm build && pm2 restart rh-web
```

## 6. 备份

```bash
docker exec mysql mysqldump -uroot -p$DB_PASSWORD ride_hermes > backup.sql
```

## 7. 已知 R0 限制

| 项 | 说明 |
|----|------|
| trust-scores | 过渡 UI，非目标态终局 |
| admin notifications | stub |
| 合规硬闸门 | 未实现，见 compliance-gates spec |
| 实时 dispatch | 过渡能力，见 ADR-002 |

## 8. 故障排查

**API 502**：`pm2 logs rh-api` → Redis/MySQL 连接  
**AI 对话失败**：检查 `ai_service.addr` 与 rh-ai 进程  
**Matching 无候选**：Redis GEO + 司机 online 状态  

---

*文档版本: v3.0*
