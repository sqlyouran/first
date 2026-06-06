## Context

后端当前仅有 `AppApplication` + `HelloController`（Spring Boot 3.3.5 骨架）。前端 auth 页面已通过 mock API 实现完整交互（login / register / send-code），mock 层定义了前端期望的 status code 与 data shape。

本次需在后端落地 7 个 auth 端点，使其与 `openspec/specs/auth/spec.md` 的行为场景一一对应，同时满足 explore 阶段确认的 API Contract（字段约束、统一错误格式、Cookie 策略等）。

约束：
- Spring Boot 3.3.5 + JDK 17 + Maven 单模块
- 同域部署（前端 Next.js rewrites 代理 /api → 后端 8080）
- 本期不动前端代码

## Goals / Non-Goals

**Goals:**

- 实现 7 个 auth HTTP 端点，行为与 `auth/spec.md` 完全一致
- 统一错误响应格式（request_id + error_code + message + details）
- JWT 双 Token 架构（access 30min + refresh 7d HttpOnly Cookie）
- 密码 bcrypt 哈希 + 字段校验（password 8-72, ≥1 letter + ≥1 digit）
- IP 维度限流（内存计数器，开发期够用）
- 全局 Response Filter 兜底移除敏感字段
- 单元测试 + WebMvcTest 切片测试覆盖所有场景

**Non-Goals:**

- 前端 mock → 真实后端切换（下一个 change）
- OAuth2 社交登录
- 密码重置 / 忘记密码
- RBAC 权限体系
- 生产级限流（Redis 滑动窗口）—— 本期用内存 Map 即可
- 邮件实际发送 —— 本期 send-code 仅日志输出验证码

## Decisions

### D1: 分层架构

```
controller/          ← HTTP 层：参数校验、调用 service、构造 response
  AuthController
service/             ← 业务逻辑：密码校验、token 签发、状态机
  AuthService
  JwtService
  RateLimitService
repository/          ← 数据访问
  UserRepository
  VerificationCodeRepository (或内存 Map)
entity/              ← JPA 实体
  UserEntity
dto/                 ← Request/Response DTO
  LoginRequest / RegisterRequest / SendCodeRequest
  TokenResponse / UserResponse / ErrorResponse
exception/           ← 自定义异常 + 全局异常处理器
  AuthException / GlobalExceptionHandler
config/              ← 安全 & Filter 配置
  SecurityConfig / RequestIdFilter / SensitiveFieldFilter
```

**理由**：标准 Spring Boot 分层，团队经验充足，与 AGENTS.md 约定一致。

### D2: 密码哈希 — BCrypt

选用 Spring Security 的 `BCryptPasswordEncoder`（默认 strength=10）。

- ✅ 业界标准，内置 salt，Spring Security 原生支持
- ❌ 备选 Argon2id 更现代，但 Spring Security 已内置 BCrypt 且够安全

仅引入 `spring-boot-starter-security` 用 PasswordEncoder，**不启用 Spring Security filter chain**（通过 `SecurityFilterChain` bean 全部 permitAll，手动在 Controller 层校验 token）。

**理由**：项目简单，手动 JWT 校验比 Spring Security 全套 filter 更透明、调试更方便。后续如需 RBAC 再引入 full Security。

### D3: JWT 库 — jjwt (io.jsonwebtoken)

选用 `jjwt-api` + `jjwt-impl` + `jjwt-jackson` (0.12.x)。

- ✅ 社区最活跃、API 简洁、支持 JDK 17
- ❌ 备选 `nimbus-jose-jwt`：更底层，API 繁琐
- ❌ 备选 `spring-security-oauth2-jose`：过重

签名算法：HS256（对称密钥），密钥从 `application.yml` 注入（开发期硬编码，生产用环境变量）。

### D4: 数据存储 — H2 开发期 + JPA

开发期用 H2 内存数据库，生产切 PostgreSQL（仅换 datasource 配置）。

- `users` 表：id(UUID), email(unique), password_hash, state(enum), failed_attempts, locked_until, created_at, updated_at
- `verification_codes` 表：id, email, code, expires_at, created_at

**理由**：JPA Entity 一次写好，H2/PG 无缝切换；开发期零配置启动。

### D5: 限流实现 — ConcurrentHashMap + 滑动窗口

本期不引入 Redis，用 `ConcurrentHashMap<String, List<Instant>>` 做内存滑动窗口。

- 优点：零依赖，开发期启动快
- 缺点：重启丢失计数、单实例有效
- 后续 scale out 时切 Redis（独立 change）

### D6: refresh_token 黑名单 — 内存 Set

`Set<String>` 存 jti（JWT ID），登出 / 删除账户时加入。

- 同 D5，开发期够用，后续切 Redis。

### D7: 验证码策略 — 6 位随机数字 + 10min TTL

`SecureRandom` 生成，存入 `verification_codes` 表（或内存 Map），TTL 10 分钟。本期不实际发邮件，仅 `log.info("Verification code for {}: {}", email, code)`。

### D8: request_id 注入 — Servlet Filter

`RequestIdFilter` 在每个请求入口生成 UUID v4，存入 `HttpServletRequest` attribute + MDC（日志追踪）。`GlobalExceptionHandler` 和正常响应都从中取值写入响应体。

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| 内存限流重启丢失 | 可接受——开发期风险极低，生产前必须切 Redis |
| 内存黑名单同上 | 同上 |
| H2 与 PG 的 SQL 方言差异 | 仅用 JPA 标准 API，不写原生 SQL |
| Spring Security 全局 filter 干扰 | SecurityConfig 配置 `http.authorizeHttpRequests(a -> a.anyRequest().permitAll())` + 禁用 CSRF |
| 验证码不实际发送 | 开发/测试期通过日志获取；生产前需集成邮件服务（独立 change） |
| BCrypt 10 轮在高并发下可能慢 | 旅游平台注册量有限，10 轮足够；极端情况可降到 8 轮 |
