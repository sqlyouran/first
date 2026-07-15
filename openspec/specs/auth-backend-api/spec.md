## ADDED Requirements

### Requirement: 统一错误响应格式

所有 auth 端点的非 2xx 响应 SHALL 使用统一 JSON 格式，包含 `request_id`（UUID v4）、`error_code`（snake_case 机器可读标识）、`message`（英文人可读描述）、`details`（字段级错误对象，无字段错误时为 `{}`）。

#### Scenario: 校验失败返回统一错误体

- **WHEN** 客户端提交 `POST /api/auth/login` with body `{ "email": "", "password": "" }`
- **THEN** 返回 HTTP 422
- **AND** 响应体包含 `request_id`（UUID v4 格式）
- **AND** 响应体包含 `error_code: "validation_error"`
- **AND** 响应体包含 `message`（非空字符串）
- **AND** 响应体 `details` 对象包含 `email` 和 `password` 字段的错误描述

#### Scenario: 业务错误返回统一错误体

- **WHEN** 客户端提交 `POST /api/auth/login` with 错误凭据
- **THEN** 返回 HTTP 401
- **AND** 响应体包含 `request_id`（UUID v4 格式）
- **AND** 响应体包含 `error_code: "invalid_credentials"`
- **AND** 响应体包含 `message: "Email or password is incorrect"`
- **AND** 响应体 `details` 为 `{}`

#### Scenario: 成功响应也包含 request_id

- **WHEN** 客户端提交任意成功请求（如 `POST /api/auth/send-code` with 有效 email）
- **THEN** 返回的 JSON 响应体包含 `request_id`（UUID v4 格式）

---

### Requirement: request_id 生成与传播

每个 HTTP 请求在入口 Filter 层生成唯一 `request_id`（UUID v4），贯穿请求生命周期（日志 MDC + 响应体）。

#### Scenario: 每个请求获得唯一 request_id

- **WHEN** 两个请求先后到达任意 auth 端点
- **THEN** 各自响应体中的 `request_id` 值不同

#### Scenario: request_id 出现在日志中

- **WHEN** 请求处理过程中产生日志
- **THEN** 日志行包含该请求的 `request_id`（通过 MDC）

---

### Requirement: error_code 枚举

auth 模块 SHALL 使用以下 `error_code` 值，不允许出现枚举外的值：

| error_code | HTTP Status | 含义 |
|---|---|---|
| validation_error | 422 | 请求体字段格式不合法 |
| invalid_code | 400 | 注册验证码错误 |
| expired_code | 400 | 注册验证码已过期 |
| email_already_registered | 409 | 邮箱已被注册 |
| invalid_credentials | 401 | 登录凭据错误（含已删除账户） |
| email_unverified | 403 | 账户邮箱未验证 |
| account_locked | 423 | 账户被锁定 |
| invalid_refresh_token | 401 | refresh_token 无效/过期/黑名单 |
| rate_limited | 429 | IP 维度限流触发 |

#### Scenario: 未知错误不暴露内部信息

- **WHEN** 后端发生未预期异常（如 NullPointerException）
- **THEN** 返回 HTTP 500
- **AND** 响应体 `error_code` 为 `"internal_error"`
- **AND** `message` 为通用描述，不包含堆栈或内部细节

---

### Requirement: 字段约束 — email

`email` 字段 SHALL 满足：RFC 5322 格式、长度 1-254 字符、存储时转为 lowercase。

#### Scenario: email 超长被拒绝

- **WHEN** 客户端提交 email 长度为 255 字符
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.email` 包含错误描述

#### Scenario: email 大小写归一化

- **WHEN** 客户端使用 `User@Example.COM` 注册
- **THEN** 数据库存储的 email 为 `user@example.com`

---

### Requirement: 字段约束 — password

`password` 字段 SHALL 满足：8-72 字符、至少包含 1 个字母（a-zA-Z）和 1 个数字（0-9）。上限 72 是 BCrypt 输入截断边界。

#### Scenario: 密码过短被拒绝

- **WHEN** 客户端提交 password 为 `"abc123"` (6 字符)
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.password` 包含错误描述

#### Scenario: 密码无数字被拒绝

- **WHEN** 客户端提交 password 为 `"abcdefgh"` (无数字)
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.password` 包含错误描述

#### Scenario: 密码无字母被拒绝

- **WHEN** 客户端提交 password 为 `"12345678"` (无字母)
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.password` 包含错误描述

#### Scenario: 密码超过 72 字符被拒绝

- **WHEN** 客户端提交 password 长度为 73 字符
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`

---

### Requirement: 字段约束 — verification code

`code` 字段 SHALL 为恰好 6 位数字字符串（`/^\d{6}$/`）。

#### Scenario: 非 6 位数字被拒绝

- **WHEN** 客户端提交 code 为 `"12345"` (5 位)
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.code` 包含错误描述

#### Scenario: 含非数字字符被拒绝

- **WHEN** 客户端提交 code 为 `"12345a"`
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`

---

### Requirement: Token 响应格式

登录和刷新成功时 SHALL 返回 `access_token`（JWT 字符串）和 `expires_in`（秒数，值为 1800）。

#### Scenario: 登录成功的响应结构

- **WHEN** 登录成功
- **THEN** 响应体包含 `request_id`（UUID v4）
- **AND** 响应体包含 `access_token`（非空 JWT 字符串）
- **AND** 响应体包含 `expires_in: 1800`
- **AND** 响应体不包含 `refresh_token`（它通过 Cookie 传输）

#### Scenario: refresh_token Cookie 属性

- **WHEN** 登录成功
- **THEN** 响应 Set-Cookie header 包含 `refresh_token=<jwt>`
- **AND** Cookie 属性包含 `HttpOnly`
- **AND** Cookie 属性包含 `Secure`
- **AND** Cookie 属性包含 `SameSite=Strict`
- **AND** Cookie 属性包含 `Path=/api/auth`
- **AND** Cookie 属性包含 `Max-Age=604800`

---

### Requirement: JWT access_token payload 结构

access_token payload SHALL 包含：`sub`（用户 UUID）、`email`、`state`、`iat`、`exp`。签名算法为 HS256。

#### Scenario: access_token 可解码并包含必要 claims

- **WHEN** 后端签发 access_token
- **THEN** JWT payload 包含 `sub`（UUID 格式）
- **AND** 包含 `email`（用户邮箱）
- **AND** 包含 `state`（如 `"active"`）
- **AND** `exp - iat` = 1800（30 分钟）

---

### Requirement: 敏感字段全局过滤

全局 Response Filter SHALL 确保任何 JSON 响应中不出现 `password_hash`、`salt`、`verification_code` 字段，即使 DTO 映射遗漏。

此外，`UserEntity.passwordHash` 字段 SHALL 标注 `@JsonIgnore`，作为字段级双保险防护。

#### Scenario: 即使 DTO 意外包含敏感字段也被过滤

- **WHEN** 某个端点的响应 DTO 意外包含 `password_hash` 字段
- **THEN** 最终 HTTP 响应的 JSON 中不存在 `password_hash` 键

#### Scenario: 正常字段不受影响

- **WHEN** 响应包含 `email`、`state`、`created_at` 等正常字段
- **THEN** 这些字段正常出现在最终响应中

#### Scenario: UserEntity 序列化时 passwordHash 被忽略

- **WHEN** Jackson 序列化 `UserEntity` 对象
- **THEN** 输出 JSON 不包含 `passwordHash` 或 `password_hash` 字段

---

### Requirement: 验证码存储迁移到 Redis

`VerificationCodeStore` SHALL 使用 Redis 替代内存 `ConcurrentHashMap` 存储验证码。验证码的 key 为邮箱（lowercase），value 为验证码字符串，TTL 为配置值（默认 600 秒）。Redis 不可用时 SHALL 降级到内存存储并记录 warn 日志。

#### Scenario: 验证码存入 Redis

- **WHEN** `sendCode` 生成验证码并调用 `codeStore.save(email, code, 600)`
- **THEN** Redis 中存储该 key-value 对，TTL 为 600 秒

#### Scenario: 服务重启后验证码仍有效

- **GIVEN** 验证码已存入 Redis
- **WHEN** 应用重启
- **THEN** 重启后 `codeStore.getCode(email)` 仍返回之前存储的验证码（Redis 未过期）

#### Scenario: Redis 不可用时降级到内存

- **GIVEN** Redis 连接失败
- **WHEN** `codeStore.save(email, code, 600)` 被调用
- **THEN** 验证码存入内存 Map，应用不崩溃，记录 warn 日志

---

### Requirement: 限流计数器迁移到 Redis

`RateLimitService` SHALL 使用 Redis sorted set 实现滑动窗口限流。每个限流 key 对应一个 sorted set，score 为请求时间戳。Redis 不可用时 SHALL 降级到内存存储。

#### Scenario: 限流计数持久化到 Redis

- **WHEN** `isRateLimited("login:ip:1.2.3.4", 20, 3600)` 被调用
- **THEN** Redis 中 `login:ip:1.2.3.4` sorted set 新增一条记录

#### Scenario: 服务重启后限流计数保留

- **GIVEN** 某 IP 已触发 15 次登录请求（限制 20 次）
- **WHEN** 应用重启
- **THEN** 重启后该 IP 的限流计数仍为 15，再请求 5 次后被限流

#### Scenario: Redis 不可用时降级到内存

- **GIVEN** Redis 连接失败
- **WHEN** `isRateLimited` 被调用
- **THEN** 使用内存 `ConcurrentHashMap` 计数，应用不崩溃，记录 warn 日志

---

### Requirement: 验证码不写入 info 日志

`AuthService.sendCode()` SHALL 不再在 info 级别记录验证码明文。验证码仅在 debug 级别记录，且不包含邮箱地址。

#### Scenario: info 日志不包含验证码

- **GIVEN** 日志级别为 INFO
- **WHEN** `sendCode` 被调用
- **THEN** 日志中不出现验证码值

#### Scenario: debug 日志可记录验证码（不含邮箱）

- **GIVEN** 日志级别为 DEBUG
- **WHEN** `sendCode` 被调用
- **THEN** 日志记录验证码已生成，但不包含邮箱地址和验证码值的组合
