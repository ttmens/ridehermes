# 部署指南

> RideHermes 平台部署流程

## 1. 环境要求

| 项目 | 最低要求 | 推荐配置 |
|------|----------|----------|
| CPU | 2 核 | 4 核 |
| 内存 | 4GB | 8GB |
| 磁盘 | 40GB | 100GB SSD |
| 系统 | Ubuntu 20.04+ | Ubuntu 22.04 |

### 软件依赖

| 软件 | 版本 | 用途 |
|------|------|------|
| Docker | 20.10+ | 容器运行 |
| Go | 1.22+ | 后端编译 |
| Node.js | 20+ | 管理后台构建 |
| PM2 | 5.x | 进程管理 |

---

## 2. 快速部署

### 2.1 克隆代码

```bash
git clone https://github.com/ttmens/ridehermes.git
cd ridehermes
```

### 2.2 启动基础设施

```bash
cd src
docker compose up -d mysql redis
```

### 2.3 初始化数据库

```bash
docker exec mysql mysql -uroot -prisehermes123 \
  -e "CREATE DATABASE IF NOT EXISTS ride_hermes CHARACTER SET utf8mb4;"

cd ride-hermes
go run ./cmd/server --migrate
```

### 2.4 启动后端

```bash
cd ride-hermes
go build -o build/ride-hermes ./cmd/server
pm2 start build/ride-hermes --name rh-api
```

### 2.5 启动管理后台

```bash
cd admin-web
pnpm install && pnpm build
pm2 serve dist 3002 --name rh-web --spa
```

### 2.6 启动 ai-service（可选）

```bash
cd src/ai-service
cp .env.example .env
uvicorn app.main:app --host 0.0.0.0 --port 8001
pm2 start "uvicorn app.main:app --host 0.0.0.0 --port 8001" --name rh-ai --cwd src/ai-service
```

### 2.7 验证

```bash
pm2 status
curl http://localhost:8686/health
curl http://localhost:3002
curl http://localhost:8001/health   # 若部署 ai-service
```

### Agent / MCP 集成

- MCP：`ridehermes-mcp-server`（10 工具）
- Agent REST：`/api/v1/agent/*`

见 [`product/vision.md`](../product/vision.md)。

---

## 3. 配置说明

### 后端配置

编辑 `src/ride-hermes/configs/config.yaml`：

```yaml
server:
  port: 8686
  mode: release

database:
  host: localhost
  port: 3306
  user: root
  password: "your_password"
  dbname: ride_hermes

redis:
  addr: localhost:6379

jwt:
  secret: "change_this_in_production"

amap:
  web_key: "your_amap_key"
  web_service_key: "your_amap_service_key"
```

---

## 4. Nginx 反向代理

```nginx
server {
    listen 80;
    server_name ride.example.com;

    location / {
        proxy_pass http://127.0.0.1:3002;
    }

    location /api {
        proxy_pass http://127.0.0.1:8686;
    }

    location /ws {
        proxy_pass http://127.0.0.1:8686;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 5. 部署后检查清单

- [ ] API 健康检查通过
- [ ] 管理后台可以登录
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] WebSocket 可以连接
- [ ] HTTPS 证书有效

---

*文档版本: v3.0 | 最后更新: 2026-06-26*
