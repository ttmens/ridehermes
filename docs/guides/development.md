# 开发指南

> 本地开发环境搭建

## 1. 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| Go | 1.22+ | 后端开发 |
| Node.js | 20+ | 管理后台开发 |
| pnpm | 8+ | 包管理 |
| Flutter | 3.24+ | 移动端开发 |
| Docker | 20+ | 数据库 |

---

## 2. 后端开发

```bash
# 启动数据库
cd src && docker compose up -d mysql redis

# 运行后端
cd ride-hermes
go mod tidy
go run ./cmd/server --migrate
go run ./cmd/server

# 或使用 Makefile
make run
```

---

## 3. 管理后台开发

```bash
cd admin-web
pnpm install
pnpm dev        # 启动开发服务器
pnpm lint       # 代码检查
pnpm build      # 构建
```

---

## 4. 移动端开发

```bash
cd passenger-app  # 或 driver-app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## 5. MCP Server 开发

```bash
cd ride-hermes-mcp
npm install
npm run dev     # 开发模式
npm run build   # 构建
```

---

## 6. Git 工作流

### 分支策略

```
main          ← 稳定版本
  └── develop ← 开发分支
       ├── feature/xxx
       └── fix/xxx
```

### 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式
refactor: 重构
```

---

## 7. 常见问题

**Q: 后端启动报数据库连接错误？**  
A: 确保 MySQL 容器已启动，且 `config.yaml` 中的密码正确。

**Q: 管理后台访问空白？**  
A: 检查 `VITE_API_BASE_URL` 是否正确，后端是否运行。

**Q: Flutter 编译失败？**  
A: 运行 `flutter doctor` 检查环境。

---

*文档版本: v1.0 | 最后更新: 2026-06-24*
