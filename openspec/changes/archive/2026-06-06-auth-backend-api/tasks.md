## 1. 项目基础设施

- [x] 1.1 pom.xml 新增依赖：spring-boot-starter-data-jpa、spring-boot-starter-security、spring-boot-starter-validation、jjwt-api/impl/jackson (0.12.x)、H2 (runtime scope)
- [x] 1.2 application.yml 配置：H2 datasource、JPA ddl-auto=create-drop、JWT secret key（开发期硬编码）、token 有效期参数
- [x] 1.3 SecurityConfig：禁用 CSRF、全部 permitAll、注册 BCryptPasswordEncoder bean

## 2. 横切关注点 (Cross-Cutting)

- [x] 2.1 RequestIdFilter：Servlet Filter 生成 UUID v4 → request attribute + MDC，请求结束时清理 MDC
- [x] 2.2 ErrorResponse DTO + GlobalExceptionHandler：统一错误格式（request_id + error_code + message + details），处理 MethodArgumentNotValid / 自定义 AuthException / 未知 500
- [x] 2.3 SensitiveFieldFilter：Jackson ResponseBodyAdvice 或 Servlet Filter，移除响应 JSON 中的 password_hash / salt / verification_code 字段

## 3. 数据层

- [x] 3.1 UserEntity：JPA Entity（id UUID, email unique, password_hash, state enum, failed_attempts, locked_until, created_at, updated_at）
- [x] 3.2 UserRepository：Spring Data JPA interface，findByEmail
- [x] 3.3 VerificationCodeEntity + Repository：(email, code, expires_at, created_at)，或使用 ConcurrentHashMap 内存实现

## 4. JWT 服务

- [x] 4.1 JwtService：generateAccessToken(user) / generateRefreshToken(user) / parseToken(token) / validateToken(token)
- [x] 4.2 TokenBlacklistService：内存 Set<String> 存 jti，add(jti) / isBlacklisted(jti)

## 5. 限流服务

- [x] 5.1 RateLimitService：内存滑动窗口实现，支持 checkAndIncrement(key, limit, windowSeconds) → boolean
- [x] 5.2 限流规则：login IP 20/h、send-code IP 5/min、send-code email 5/day、register IP 3/h

## 6. Auth 业务服务

- [x] 6.1 AuthService.sendCode(email)：校验 email 格式 → 限流检查 → 生成 6 位随机数字 → 存储(TTL 10min) → 日志输出验证码
- [x] 6.2 AuthService.register(email, code, password)：限流检查 → 校验 code → 检查邮箱唯一 → bcrypt hash → 创建 user(active) → 返回 201
- [x] 6.3 AuthService.login(email, password)：限流检查 → 查 user → 状态机校验(deleted→401 / locked→423 / unverified→403) → 密码比对 → 失败计数/锁定 → 签发双 token
- [x] 6.4 AuthService.refresh(refreshTokenCookie)：解析 token → 黑名单检查 → 签发新 access_token
- [x] 6.5 AuthService.logout(refreshTokenCookie)：解析 jti → 加入黑名单 → 清除 Cookie
- [x] 6.6 AuthService.getMe(accessToken)：解析 token → 查 user → 返回 UserResponse(id, email, state, created_at)
- [x] 6.7 AuthService.deleteMe(accessToken)：解析 token → user.state=deleted → 黑名单所有 refresh_token

## 7. Controller 层

- [x] 7.1 AuthController：POST /api/auth/send-code — RequestBody validation + 调用 service
- [x] 7.2 AuthController：POST /api/auth/register — RequestBody validation + 调用 service
- [x] 7.3 AuthController：POST /api/auth/login — 调用 service + Set-Cookie refresh_token
- [x] 7.4 AuthController：POST /api/auth/refresh — @CookieValue refresh_token + 调用 service
- [x] 7.5 AuthController：POST /api/auth/logout — @CookieValue + 调用 service + 清 Cookie
- [x] 7.6 AuthController：GET /api/auth/me — @RequestHeader Authorization + 调用 service
- [x] 7.7 AuthController：DELETE /api/auth/me — @RequestHeader Authorization + 调用 service

## 8. 集成测试 (@WebMvcTest)

- [x] 8.1 send-code 测试：正常 200 / 校验失败 422 / IP 限流 429
- [x] 8.2 register 测试：成功 201 / invalid_code 400 / expired_code 400 / email_already_registered 409 / validation 422 / IP 限流 429
- [x] 8.3 login 测试：成功 200(含 access_token + Cookie) / invalid_credentials 401 / locked 423 / unverified 403 / validation 422 / IP 限流 429
- [x] 8.4 refresh 测试：成功 200 / invalid_refresh_token 401
- [x] 8.5 logout 测试：成功 204 + Cookie 清除 / 无 Cookie 401
- [x] 8.6 GET /me 测试：成功 200(含 user info, 无敏感字段) / 无 token 401
- [x] 8.7 DELETE /me 测试：成功 204 / 无 token 401

## 9. 验收确认

- [x] 9.1 mvn test 全绿
- [x] 9.2 mvn spring-boot:run 启动无报错，手动 curl 验证 send-code → register → login → refresh → me → logout 全链路
- [x] 9.3 确认所有响应都包含 request_id
- [x] 9.4 确认敏感字段 Filter 生效（手动测试或专用测试用例）
