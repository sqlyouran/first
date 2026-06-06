## Why

前端登录/注册页面已落地（mock API 驱动），后端仍是空壳（仅 HelloController）。需要实现 Spring Boot auth HTTP API，使 `openspec/specs/auth/spec.md` 中定义的行为场景在后端真正可用。本次只做后端实现，前端 mock → 真实后端的切换留给下一个 change。

## What Changes

- 新增 `AuthController`，暴露 7 个端点：send-code / register / login / refresh / logout / GET me / DELETE me
- 新增 `AuthService` 封装业务逻辑（验证码生成/校验、密码哈希、JWT 签发/验证、黑名单）
- 新增 `UserRepository` + JPA Entity（User 表，含 state 状态机）
- 新增统一错误响应结构（`request_id` + `error_code` + `message` + `details`）+ 全局异常处理器
- 新增 IP 维度限流拦截器（登录 20次/h、send-code 5次/min、注册 3次/h）
- 新增全局 Response Filter 兜底移除敏感字段（password_hash / salt / verification_code）
- 密码策略确认：8-72 字符，≥1 字母 + ≥1 数字（bcrypt 哈希）
- Token 架构：access_token 30min（Bearer header）+ refresh_token 7d（HttpOnly Cookie, SameSite=Strict, Path=/api/auth）

## Capabilities

### New Capabilities

- `auth-backend-api`: 后端 Auth HTTP API 实现合约——统一错误格式、字段约束 schema、HTTP header 约定、JWT payload 结构

### Modified Capabilities

- `auth`: 补充字段约束细节（password 8-72 + ≥1 letter + ≥1 digit；email max 254；code 恰好 6 位数字）和统一错误响应格式（含 request_id）

## Impact

- **后端代码**：`backend/src/main/java/com/mooc/app/` 新增 auth 包（controller / service / repository / entity / dto / exception / config）
- **依赖新增**：spring-boot-starter-data-jpa、spring-boot-starter-security（仅 PasswordEncoder）、jjwt、H2（开发期）/ PostgreSQL（生产）
- **数据库**：新建 `users` 表 + `verification_codes` 表（或内存缓存）
- **前端**：本次不动，mock 层保持现状
