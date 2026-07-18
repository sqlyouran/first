## Context

WanderChina 是一个全栈旅游平台：前端 Next.js 16 SSR + 后端 Spring Boot 3.3.5 fat jar + MySQL 8 + Redis + Chroma 向量库。当前所有功能已开发完毕并在本地运行，数据库已迁移至阿里云 RDS（表结构最新）。项目需要上线到阿里云 ECS 单机环境，通过 Docker Compose 编排所有服务，Nginx 反向代理 + HTTPS 对外暴露。

**约束：**
- 单人运维，月预算 ~100 元
- 日活几十到几百，无需高可用
- 域名已购买
- 阿里云 RDS 已配置且表结构最新

## Goals / Non-Goals

**Goals:**
- 用户可通过 `https://域名` 访问完整应用（前端页面 + 后端 API）
- 所有服务容器化，`docker compose up -d` 一键启动
- Nginx 实现 SSL 终止 + 路由分流（`/api/*` → 后端，其余 → 前端）
- 生产环境安全：JWT 密钥随机化、CORS 限定域名、Cookie Secure
- 部署脚本化，后续更新可重复执行

**Non-Goals:**
- 不做 CI/CD 自动化流水线（手动 SSH 部署即可）
- 不做负载均衡 / 多节点
- 不做监控告警（后续独立变更）
- 不做数据库备份方案（RDS 自带自动备份）
- 不做 CDN / 静态资源加速

## Decisions

### D1: 部署架构选型 — Docker Compose 单机

**选择：** Docker Compose 编排 5 个容器（nginx / backend / frontend / redis / chroma）

**排除：**
- Kubernetes：单人项目运维成本过高，概念过多
- Serverless：Spring Boot fat jar 无法跑在 Serverless 函数上
- 纯 PaaS：预算受限且 Spring Boot 支持有限

### D2: 路由策略 — Nginx 分流（路线 B）

**选择：** Nginx 同时承担两条路径的分流：
- 浏览器请求 `/api/*` → proxy_pass 到 backend:8080
- 浏览器请求其它路径 → proxy_pass 到 frontend:3000
- Server Component SSR 预取 → frontend 容器内通过 `BACKEND_URL=http://backend:8080` 直连后端

**排除路线 A（仅 Next.js rewrite 代理）：** 会导致所有 API 请求都经过 frontend 容器转发，增加不必要跳数。Nginx 直接分流更清晰、性能更好。

### D3: 前端构建模式 — Next.js standalone output

**选择：** `next.config.ts` 添加 `output: 'standalone'`，构建产物包含独立 `server.js`，Docker 运行阶段只需 Node 运行时 + standalone 产物，无需 `node_modules`。

**理由：** 镜像体积从 ~1.5GB（含 node_modules）缩小到 ~200MB，启动更快。

### D4: 后端构建 — Maven 多阶段构建

**选择：** Dockerfile 两阶段：
- Stage 1 (build)：`maven:3.9-eclipse-temurin-17-jammy` 执行 `mvn package -DskipTests`
- Stage 2 (run)：`eclipse-temurin:17-jre-jammy` 仅运行 `java -jar app.jar`

**理由：** 运行镜像只需 JRE（~200MB vs 构建镜像 ~800MB），且构建产物为单一 fat jar。

### D5: Redis 容器内运行

**选择：** Redis 作为 Docker Compose 服务运行，通过 Docker 内网服务名 `redis` 被 backend 访问。

**理由：** 符合"Redis 本地化运行"约束（不迁移到云端 Redis 实例），容器化后仍为本地进程级别。Volume 持久化数据防丢失。

### D6: Chroma 容器内运行

**选择：** Chroma 作为 Docker Compose 服务运行，Volume 持久化向量数据。

**理由：** AI RAG 功能需要向量库，容器化统一管理。

### D7: 生产 Profile 配置策略

**选择：** 通过 `SPRING_PROFILES_ACTIVE=prod` 环境变量激活 `application-prod.yml`，叠加在 `application.yml` 之上。

**关键覆盖项：**
- `ddl-auto: validate`（不修改表结构）
- `sql.init.mode: never`（不加载种子数据）
- `springdoc.api-docs.enabled: false`（关闭 API 文档）
- `MCP_CLIENT_ENABLED=false`（关闭 MCP Client，生产容器无 Node/npx）

### D8: SSL 证书 — Let's Encrypt + certbot

**选择：** 使用 Let's Encrypt 免费证书 + certbot 申请/续期。

**理由：** 免费、自动续期、业界标准。

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| ECS 单机宕机 = 全站不可用 | 可接受（单人项目，短暂停机 OK）；RDS 数据不丢 |
| Docker 镜像构建慢（首次 Maven 下载依赖） | 多阶段构建 + Docker layer caching；后续增量构建快 |
| SSL 证书过期 | certbot 自动续期（cron）；部署脚本包含续期命令 |
| Next.js standalone 模式可能有 SSR 兼容问题 | 构建后本地验证；若失败回退到标准模式 |
| Redis 容器重启丢失数据 | Docker Volume 持久化 `/data` |
| Chroma 容器重启丢失向量数据 | Docker Volume 持久化 `/chroma/chroma` |
| 生产环境 JWT Secret 忘记更换 | `.env.production` 文件中强制使用随机值；deploy.sh 脚本包含生成步骤 |
