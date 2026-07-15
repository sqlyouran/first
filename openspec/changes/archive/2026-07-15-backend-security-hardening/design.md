## Context

WanderChina 后端是基于 Spring Boot 3.3.x + Java 17 的 HTTP API 服务，使用 JWT 做用户认证（access_token + refresh_token Cookie），Redis 做缓存，MySQL 做持久化。当前安全机制依赖各 Controller 手动调用 `AuthUtil.requireUserId()` 做认证，Spring Security 配置为 `anyRequest().permitAll()`，敏感配置（JWT secret）硬编码在 `application.yml`。安全体检发现多个高危问题需要上线前修复。

## Goals / Non-Goals

**Goals:**
- 所有安全配置（密钥、CORS、Swagger 开关）通过环境变量注入，零硬编码
- Spring Security 层实现白名单鉴权，不再依赖每个 Controller 手动校验
- 管理/运维接口受认证保护
- 验证码和限流数据持久化到 Redis（服务重启不丢失）
- 生产环境 profile 隔离（DDL 策略、种子数据、Swagger）
- 敏感字段序列化防护双保险（全局 Filter + 字段级 @JsonIgnore）

**Non-Goals:**
- 不引入 RBAC 角色体系（当前只需"登录/未登录"两级，YAGNI）
- 不引入 WAF / DDoS 防护（属于部署层，不在代码层处理）
- 不重构认证流程（现有 JWT + Cookie 架构不变，只加固配置和过滤链）
- 不修改前端代码（AI 聊天接口认证变更需前端配合，但本次只做后端）

## Decisions

### D1: Spring Security 白名单 + JwtAuthenticationFilter

**选择**: 新增 `JwtAuthenticationFilter`（继承 `OncePerRequestFilter`），在 SecurityFilterChain 中注册。SecurityConfig 配置白名单：

```
permitAll:
  GET  /api/hello
  POST /api/auth/send-code
  POST /api/auth/register
  POST /api/auth/login
  POST /api/auth/refresh
  GET  /api/posts/**
  GET  /api/spots/** (含 /ranking, /{id}/posts, /{id}/comments)
  GET  /api/cities/**
  GET  /api/search/**
  GET  /api/users/{username}
  GET  /api/services/**
  POST /api/ai/** (暂保留 permitAll 给前端适配时间，后续收紧)

需认证 (default):
  所有其它请求
```

**备选方案**: 用 Spring Security `@PreAuthorize` 注解。**放弃理由**: 项目现有模式是 Filter + AuthUtil，切换到注解需要改所有 Controller，违反 YAGNI。

### D2: 敏感字段双保险（@JsonIgnore + SensitiveFieldFilter）

**选择**: 在 `UserEntity.passwordHash` 字段加 `@JsonIgnore`，保留现有 `SensitiveFieldFilter` 作为兜底。双保险比单一机制更可靠。

**备选方案**: 只用 `@JsonFilter("sensitiveFilter")` 注解。**放弃理由**: 需要给每个 Entity 加注解，且依赖 Filter 初始化顺序，不如 `@JsonIgnore` 直接。

### D3: 验证码和限流迁移到 Redis

**选择**: `VerificationCodeStore` 改为注入 `StringRedisTemplate`，用 `opsForValue().set(key, code, Duration)` 存取。`RateLimitService` 同理，用 Redis sorted set（`ZADD key timestamp member`）实现滑动窗口。

**备选方案**: 用 Redisson 分布式锁。**放弃理由**: 验证码和限流不需要分布式锁语义，原生 `StringRedisTemplate` 够用。

### D4: 生产 profile 分离

**选择**: 新建 `application-prod.yml`，通过 `spring.profiles.active=prod` 激活。生产 profile 覆盖：`ddl-auto: validate`、`sql.init.mode: never`、`springdoc.api-docs.enabled: false`。

**备选方案**: 用 Spring Cloud Config / Vault。**放弃理由**: 当前单实例部署，引入配置中心过重。

### D5: CORS 通过环境变量配置

**选择**: `WebConfig` 中 `allowedOrigins` 从 `@Value("${cors.allowed-origins}")` 读取，默认值 `http://localhost:3000`。支持逗号分隔多个域名。

### D6: ForwardedHeaderFilter 获取真实 IP

**选择**: 在 `SecurityConfig` 的 filter chain 中注册 Spring 内置的 `ForwardedHeaderFilter`，使 `getRemoteAddr()` 返回 `X-Forwarded-For` 中的真实 IP。

## Risks / Trade-offs

| 风险 | 缓解措施 |
|---|---|
| AI 接口改为强制认证后前端报错 | 第一阶段 AI 接口保持 permitAll（加入白名单），同时在 AI Controller 层加匿名限流（每 IP 每天 20 次）；后续前端适配后再收紧 |
| 验证码迁移 Redis 后 Redis 宕机导致无法注册 | Redis 操作 try-catch 降级：写入失败时 fallback 到内存 Map + warn 日志 |
| Security 白名单遗漏某个公开接口导致前端 401 | 逐接口核对 + 集成测试覆盖所有公开端点 |
| JWT secret 改为环境变量后开发环境启动失败 | `.env` 文件保留开发用默认值，`@Value` 设 fallback `dev-secret-...` |
| 生产 profile 配错导致线上用 dev 配置 | 部署脚本强制 `SPRING_PROFILES_ACTIVE=prod` + 启动日志打印当前 profile |
