## Why

WanderChina 项目已完成全部功能开发（认证、帖子、景点、AI 聊天、消息等），但尚无线上运行环境。需要将前后端服务容器化，部署到阿里云 ECS，通过 Nginx 反向代理 + HTTPS 对外提供服务，让真实用户可以访问使用。

## What Changes

- 新增 `backend/Dockerfile`：多阶段构建 Spring Boot fat jar 镜像（Maven build → JRE 17 运行）
- 新增 `frontend/Dockerfile`：多阶段构建 Next.js standalone 镜像（npm build → Node 20 运行）
- 新增 `docker-compose.yml`：编排 5 个服务（Nginx、backend、frontend、Redis、Chroma）
- 新增 `nginx/nginx.conf` + `nginx/conf.d/default.conf`：反向代理 + SSL 终止 + 路由分流
- 新增 `scripts/deploy.sh`：一键部署脚本
- 新增 `scripts/init-ssl.sh`：Let's Encrypt 证书申请脚本
- 修改 `frontend/next.config.ts`：rewrite destination 改用环境变量；添加 `output: 'standalone'`
- 修改 `backend/application.yml`：Redis host 从硬编码 `localhost` 改为 `${REDIS_HOST:localhost}`
- 修改 `backend/application-prod.yml`：补全生产环境配置（MCP Client 关闭、日志等）

## Capabilities

### New Capabilities
- `docker-containerization`：前后端 Dockerfile 与容器化构建配置
- `service-orchestration`：Docker Compose 编排多服务（Nginx、backend、frontend、Redis、Chroma）
- `nginx-reverse-proxy`：Nginx 反向代理配置，含 SSL 终止、路由分流（`/api/*` → 后端，其余 → 前端）、安全头
- `deployment-scripts`：一键部署脚本与 Let's Encrypt 证书初始化脚本

### Modified Capabilities
- 无（现有功能规格不变，仅补充生产环境运行配置）

## Impact

- **backend/**：`application.yml` Redis 配置改动（向后兼容，默认值仍为 `localhost`）；`application-prod.yml` 补全配置项
- **frontend/**：`next.config.ts` 改动（rewrite + standalone output）；需确认 Next.js standalone 构建产物兼容性
- **父仓根目录**：新增 `docker-compose.yml`、`nginx/`、`scripts/` 目录
- **外部依赖**：阿里云 ECS 服务器需预装 Docker + Docker Compose；域名 DNS 需指向 ECS 公网 IP
- **安全**：生产环境 JWT Secret 必须替换为随机密钥；CORS 需配置为真实域名；SSL 证书需定期续期
