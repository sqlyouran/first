## 1. 敏感配置环境变量化

- [x] 1.1 `application.yml` 中 `app.jwt.secret` 改为 `${JWT_SECRET:dev-secret-key-change-in-production-min-32-chars!!}`
- [x] 1.2 `.env` 和 `.env.example` 补充 `JWT_SECRET`、`CORS_ALLOWED_ORIGINS` 字段及说明
- [x] 1.3 `WebConfig` 中 CORS `allowedOrigins` 改为从 `@Value("${cors.allowed-origins:http://localhost:3000}")` 读取，支持逗号分隔多域名
- [x] 1.4 验证开发环境（不设环境变量）启动正常，CORS 默认 localhost:3000 生效

## 2. Spring Security 白名单 + JwtAuthenticationFilter

- [x] 2.1 新建 `JwtAuthenticationFilter`（继承 `OncePerRequestFilter`），从 Authorization header 解析 JWT 并设置 SecurityContext
- [x] 2.2 修改 `SecurityConfig`：注册 `ForwardedHeaderFilter`（@Order Highest）+ `JwtAuthenticationFilter`（在 UsernamePasswordAuthenticationFilter 之前）
- [x] 2.3 修改 `SecurityConfig`：配置白名单（GET /api/posts/**, GET /api/spots/**, GET /api/cities/**, GET /api/search/**, GET /api/users/{username}, GET /api/services/**, POST /api/auth/send-code|register|login|refresh, GET /api/hello, POST /api/ai/**）
- [x] 2.4 `SecurityConfig` 中 `anyRequest().authenticated()` 替代 `anyRequest().permitAll()`，移除 `formLogin().disable()` 和 `httpBasic().disable()` 的冗余配置
- [x] 2.5 编写集成测试：验证公开接口（GET /api/posts）无 Token 可访问
- [x] 2.6 编写集成测试：验证需认证接口（POST /api/posts）无 Token 返回 401
- [x] 2.7 编写集成测试：验证有效 Token 可正常访问需认证接口
- [x] 2.8 验证现有所有 Controller 测试通过（SecurityFilterChain 不阻断已有测试）

## 3. 验证码日志修复

- [x] 3.1 `AuthService.sendCode()` 中将 `log.info("Verification code for {}: {}", email, code)` 改为 `log.debug("Verification code generated")`（不包含邮箱和验证码值）
- [x] 3.2 编写测试：验证 info 级别日志不包含验证码

## 4. 验证码存储迁移到 Redis

- [x] 4.1 `VerificationCodeStore` 注入 `StringRedisTemplate`，`save` 改用 Redis `opsForValue().set(key, code, Duration)`，key 前缀 `verify:`
- [x] 4.2 `VerificationCodeStore` 的 `getCode` 改用 Redis `opsForValue().get(key)`，`remove` 改用 `opsForValue.delete(key)`
- [x] 4.3 Redis 操作 try-catch 降级：写入/读取失败时 fallback 到内存 `ConcurrentHashMap` + warn 日志
- [x] 4.4 编写测试：验证验证码存入 Redis 并可读取
- [x] 4.5 编写测试：验证 Redis 不可用时降级到内存

## 5. 限流计数器迁移到 Redis

- [x] 5.1 `RateLimitService` 注入 `StringRedisTemplate`，`isRateLimited` 改用 Redis sorted set 实现滑动窗口（ZADD + ZRANGEBYSCORE + ZREMRANGEBYSCORE + ZCARD）
- [x] 5.2 Redis 操作 try-catch 降级：失败时 fallback 到内存 `ConcurrentHashMap` + warn 日志
- [x] 5.3 编写测试：验证限流计数持久化到 Redis
- [x] 5.4 编写测试：验证 Redis 不可用时降级到内存

## 6. 敏感字段双保险

- [x] 6.1 `UserEntity.passwordHash` 字段添加 `@JsonIgnore` 注解
- [x] 6.2 编写测试：验证 Jackson 序列化 `UserEntity` 时不包含 `passwordHash`
- [x] 6.3 编写测试：验证 `SensitiveFieldFilter` 仍然正常工作（双保险共存）

## 7. 管理接口认证保护

- [x] 7.1 确认 `SpotEnrichmentController`（/api/spots/stale, /api/spots/enrichment/trigger, /api/spots/enrichment/report/latest）不在 Security 白名单中
- [x] 7.2 确认 `KnowledgeController`（/api/ai/knowledge/rebuild）不在 Security 白名单中
- [x] 7.3 编写测试：验证未认证请求上述接口返回 401

## 8. AI 聊天接口匿名限流

- [x] 8.1 `RateLimitService` 新增 `isAiChatIpRateLimited(String ip)` 方法（每 IP 每天 20 次）
- [x] 8.2 `AiChatController.chat()` 和 `createConversation()` 中添加限流逻辑：未登录用户触发限流时返回 429
- [x] 8.3 编写测试：验证匿名用户超过每日限额返回 429
- [x] 8.4 编写测试：验证已登录用户不受匿名限流限制

## 9. 生产 profile 分离

- [x] 9.1 新建 `application-prod.yml`：`ddl-auto: validate`、`sql.init.mode: never`、`springdoc.api-docs.enabled: false`
- [x] 9.2 验证 `SPRING_PROFILES_ACTIVE=prod` 启动时 Swagger 文档不可访问
- [x] 9.3 验证无 profile 启动时（开发环境）行为不变

## 10. 搜索接口输入校验

- [x] 10.1 `SearchController.search()` 的 `q` 参数添加 `@NotBlank @Size(max=200)` 校验
- [x] 10.2 `SearchController.suggest()` 的 `q` 参数添加 `@NotBlank @Size(max=200)` 校验
- [x] 10.3 编写测试：验证空搜索词返回 422
- [x] 10.4 编写测试：验证超长搜索词返回 422

## 11. 全量验证

- [x] 11.1 运行 `mvn -f backend/pom.xml test` 全量测试通过
- [x] 11.2 手动验证开发环境启动正常（无环境变量 + 默认 profile）
- [x] 11.3 检查所有 Controller 的公开/认证端点与白名单配置一致
