## Why

WanderChina 后端即将上线公网，安全体检发现 4 项高危 + 7 项中危 + 4 项低危问题。当前状态下：JWT 签名密钥明文写在配置文件里（拿到密钥就能伪造任何人的身份）、Spring Security 对所有请求放行（全靠 Controller 手动校验，漏一个就裸奔）、多个管理接口无需任何鉴权即可调用、验证码被记录到日志。必须在上线前修复，否则面临身份伪造、越权访问、资源耗尽、信息泄露等风险。

## What Changes

**【高危修复】**
- JWT 签名密钥从 `application.yml` 硬编码改为环境变量 `${JWT_SECRET}`，`.env.example` 补充说明
- Spring Security 从 `anyRequest().permitAll()` 改为白名单模式：公开接口显式 `permitAll`，其余请求需通过新增的 `JwtAuthenticationFilter` 统一校验
- 管理/运维接口（`/api/spots/stale`、`/api/spots/enrichment/trigger`、`/api/ai/knowledge/rebuild`）加入认证保护
- 验证码日志级别从 `info` 降为 `debug`，生产环境不再记录

**【中危修复】**
- AI 聊天接口（`/api/ai/chat`、`/api/ai/conversations`）要求登录认证
- Springdoc/OpenAPI 文档可通过环境变量 `SWAGGER_ENABLED` 控制开关，默认关闭
- CORS `allowedOrigins` 从硬编码 `localhost:3000` 改为环境变量 `${CORS_ALLOWED_ORIGINS}`
- 新增 `application-prod.yml` profile，`ddl-auto` 生产设为 `validate`、`data.sql` 设为 `never`
- 验证码存储（`VerificationCodeStore`）和限流计数器（`RateLimitService`）从内存 `ConcurrentHashMap` 迁移到 Redis
- `UserEntity.passwordHash` 字段加 `@JsonIgnore`，确保序列化安全
- `data.sql` 执行模式通过 profile 区分（开发 `always`，生产 `never`）

**【低危修复】**
- 添加 `ForwardedHeaderFilter` 支持反向代理场景下的真实 IP 获取
- 搜索接口 `q` 参数加 `@NotBlank` + `@Size(max=200)` 校验
- 评估 JWT access token 撤回机制（缩短有效期或加入 jti 黑名单）

## Capabilities

### New Capabilities
- `security-config`: Spring Security 白名单规则 + JwtAuthenticationFilter 统一认证拦截 + CORS 环境变量化
- `secret-management`: 所有敏感配置（JWT secret、CORS origins、Swagger 开关）通过环境变量注入，不再硬编码

### Modified Capabilities
- `auth-backend-api`: 验证码日志级别调整；验证码存储和限流计数器迁移到 Redis；access token 撤回机制
- `ai-chat-backend`: AI 聊天接口从可选认证改为强制认证
- `spots-backend-api`: 景点数据增强管理接口加入认证保护
- `http-server`: 新增 ForwardedHeaderFilter；Springdoc 可配置关闭；生产 profile 分离

## Impact

- **代码**：`backend/src/main/java/com/mooc/app/` 下的 `config/`、`filter/`、`service/`、`controller/`、`entity/` 目录均有改动
- **配置**：`application.yml` 敏感值改环境变量占位；新增 `application-prod.yml`；`.env.example` 补充字段
- **依赖**：Redis 已有依赖（`spring-boot-starter-data-redis`），无需新增
- **API**：AI 聊天接口从匿名可用变为需要 Bearer Token（前端需配合调整）；管理接口从匿名变为需要认证
- **部署**：生产环境需设置新环境变量 `JWT_SECRET`、`CORS_ALLOWED_ORIGINS`
