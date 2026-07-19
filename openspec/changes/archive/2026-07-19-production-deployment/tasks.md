## 1. 代码改动（现有文件修改）

- [x] 1.1 修改 `frontend/next.config.ts`：添加 `output: 'standalone'`；将 rewrite destination 从硬编码 `http://localhost:8080` 改为 `process.env.BACKEND_URL || "http://localhost:8080"`
- [x] 1.2 修改 `backend/src/main/resources/application.yml`：将 Redis `host: localhost` 改为 `host: ${REDIS_HOST:localhost}`
- [x] 1.3 修改 `backend/src/main/resources/application-prod.yml`：添加 Redis 生产配置（`REDIS_HOST` 默认值）、MCP Client 关闭确认、日志配置为 stdout

## 2. Docker 容器化

- [x] 2.1 创建 `backend/Dockerfile`：多阶段构建（maven:3.9-eclipse-temurin-17-focal build → eclipse-temurin:17-jre-jammy run），暴露 8080
- [x] 2.2 创建 `frontend/Dockerfile`：多阶段构建（node:20-alpine build → node:20-alpine run standalone），暴露 3000
- [x] 2.3 验证：镜像构建成功（在 ECS 上通过 `docker compose up -d --build` 验证，`first-backend`/`first-frontend` 均 Built）

## 3. Nginx 反向代理配置

- [x] 3.1 创建 `nginx/nginx.conf`：worker 配置、日志格式、gzip 压缩
- [x] 3.2 创建 `nginx/conf.d/default.conf`：HTTP→HTTPS 301 重定向、SSL 终止、路由分流（`/api/*` → backend:8080，其余 → frontend:3000）、代理头设置
- [x] 3.3 创建 `nginx/ssl/.gitkeep`：SSL 证书目录占位（证书不入 git）

## 4. Docker Compose 编排

- [x] 4.1 创建 `docker-compose.yml`：定义 5 个服务（nginx/backend/frontend/redis/chroma）、依赖关系、端口暴露策略、Docker volumes
- [x] 4.2 创建 `.env.production.example`：生产环境变量模板，包含所有必需变量及注释说明

## 5. 部署脚本

- [x] 5.1 创建 `scripts/deploy.sh`：环境校验 + `docker compose up -d --build` 一键部署
- [x] 5.2 创建 `scripts/init-ssl.sh`：Let's Encrypt 证书申请 + 自动续期配置

## 6. 验证与收尾

- [x] 6.1 完整验证：在 ECS 上 `docker compose up` 启动全部 5 个服务（nginx/backend/frontend/redis/chroma）均 Up，Nginx 分流生效（`https://mediachina.app` 可访问、`/api/*` 走后端）
- [x] 6.2 更新 `.gitignore`：添加 `.env.production`（生产密钥不入库）、`nginx/ssl/*.pem`（证书不入库）
