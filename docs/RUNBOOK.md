# RideHermes 运维手册

> 部署、监控、故障排查

## 1. 系统架构

```
服务器 (dc1-priority)
├── PM2 进程
│   ├── rh-api    (Go 后端)        端口 8686
│   └── rh-web    (管理后台)       端口 3002
└── Docker 容器
    ├── mysql:8.0                  端口 3306
    └── redis:7.2                  端口 6379
```

---

## 2. 日常运维命令

### 服务状态检查

```bash
pm2 status                    # PM2 进程
docker ps                     # Docker 容器
ss -tlnp | grep -E '868|300'  # 端口
```

### 日志查看

```bash
pm2 logs rh-api --lines 100   # 后端日志
pm2 logs rh-web --lines 100   # 管理后台日志
docker logs mysql --tail 100  # MySQL 日志
```

### 服务重启

```bash
pm2 restart rh-api            # 重启后端
pm2 restart rh-web            # 重启管理后台
docker restart mysql redis    # 重启数据库
```

---

## 3. 部署流程

### 后端部署

```bash
cd ~/ridehermes && git pull
cd src/ride-hermes
go build -o build/ride-hermes ./cmd/server
pm2 restart rh-api
curl http://localhost:8686/health  # 验证
```

### 管理后台部署

```bash
cd ~/ridehermes/src/admin-web
pnpm install && pnpm build
pm2 restart rh-web
curl http://localhost:3002  # 验证
```

---

## 4. 故障排查

### API 无响应

```bash
pm2 status | grep rh-api
ss -tlnp | grep 8686
pm2 logs rh-api --err --lines 50
docker exec mysql mysqladmin ping -uroot -prisehermes123
pm2 restart rh-api
```

### 数据库连接失败

```bash
docker ps | grep mysql
docker logs mysql --tail 50
docker restart mysql
```

### Redis 内存不足

```bash
docker exec redis redis-cli info memory
docker exec redis redis-cli dbsize
docker restart redis
```

---

## 5. 备份恢复

```bash
# 数据库备份
docker exec mysql mysqldump -uroot -prisehermes123 ride_hermes > backup_$(date +%Y%m%d).sql

# 数据库恢复
docker exec -i mysql mysql -uroot -prisehermes123 ride_hermes < backup.sql
```

---

## 6. 健康检查清单

- [ ] API 健康检查通过 (`/health`)
- [ ] 管理后台可以登录
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] WebSocket 可以连接
- [ ] 日志输出正常

---

*文档版本: v1.0 | 最后更新: 2026-06-24*
