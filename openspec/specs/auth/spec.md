## MODIFIED Requirements

### Requirement: 用户注册（验证码方式）

用户通过「发送验证码 → 携带验证码注册」两步完成注册，注册成功后直接进入 `active` 状态。

#### Scenario: 发送验证码

- **GIVEN** 客户端提交 `POST /api/auth/send-code` with body `{ "email": "<valid-email>" }`
- **WHEN** 后端接收到请求
- **THEN** 无论该邮箱是否已注册，均返回 HTTP `200`（反枚举）
- **AND** 若邮箱未注册，后端生成验证码并发送到该邮箱
- **AND** 验证码有效期为 10 分钟
- **AND** 验证码为 6 位纯数字字符串

#### Scenario: 注册成功

- **GIVEN** 客户端提交 `POST /api/auth/register` with body `{ "email": "...", "code": "...", "password": "..." }`
- **WHEN** 验证码正确且未过期，且邮箱未被注册
- **AND** password 满足约束：8-72 字符、≥1 字母(a-zA-Z)、≥1 数字(0-9)
- **THEN** 创建用户，state = `active`，email 存储为 lowercase
- **AND** 返回 HTTP `201 Created`

#### Scenario: 注册失败——验证码错误或过期

- **GIVEN** 客户端提交 `POST /api/auth/register` with 错误/过期的 code
- **WHEN** 后端校验 code 不通过
- **THEN** 返回 HTTP `400 Bad Request`
- **AND** 响应体包含 `error_code` 指示具体原因（`invalid_code` / `expired_code`）

#### Scenario: 注册失败——邮箱已注册

- **GIVEN** 客户端提交 `POST /api/auth/register` with 已注册的 email
- **WHEN** 后端发现邮箱已存在
- **THEN** 返回 HTTP `409 Conflict`
- **AND** 响应体 `error_code: "email_already_registered"`

#### Scenario: 注册失败——字段校验不通过

- **GIVEN** 客户端提交 `POST /api/auth/register` with 不合法的字段
- **WHEN** email 格式无效、或 email 超过 254 字符、或 password 不满足约束、或 code 不是 6 位数字
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"` + `details` 包含具体字段错误

---

### Requirement: 用户登录（JWT 双 Token）

登录成功后颁发 access_token（短命）+ refresh_token（长命 HttpOnly Cookie）。

#### Scenario: 登录成功（active 用户）

- **GIVEN** 用户 state = `active`
- **WHEN** 客户端提交 `POST /api/auth/login` with 正确的 email + password
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `access_token`（JWT，有效期 30 分钟）
- **AND** 响应体包含 `expires_in: 1800`
- **AND** 响应 Set-Cookie 包含 `refresh_token`（HttpOnly, Secure, SameSite=Strict, Path=/api/auth, Max-Age=604800）

#### Scenario: 登录失败——凭据错误

- **GIVEN** 邮箱不存在 或 密码错误
- **WHEN** 客户端提交 `POST /api/auth/login`
- **THEN** 返回 HTTP `401 Unauthorized`
- **AND** 响应体 `error_code: "invalid_credentials"`，不区分"邮箱不存在"与"密码错误"（反枚举）

#### Scenario: 登录失败——账户已删除

- **GIVEN** 用户 state = `deleted`
- **WHEN** 客户端提交 `POST /api/auth/login` with 该邮箱
- **THEN** 返回 HTTP `401 Unauthorized`（与凭据错误同码，不暴露账户存在性）

#### Scenario: 登录失败——账户已锁定

- **GIVEN** 用户 state = `locked`
- **WHEN** 客户端提交 `POST /api/auth/login`
- **THEN** 返回 HTTP `423 Locked`
- **AND** 响应体包含 `error_code: "account_locked"` 和 `locked_until`（ISO 8601 时间戳）

#### Scenario: 登录失败——邮箱未验证

- **GIVEN** 用户 state = `email_unverified`
- **WHEN** 客户端提交 `POST /api/auth/login`
- **THEN** 返回 HTTP `403 Forbidden`
- **AND** 响应体包含 `error_code: "email_unverified"`

#### Scenario: 登录失败——字段校验不通过

- **GIVEN** 客户端提交 `POST /api/auth/login` with email 格式无效或 password 为空
- **WHEN** 后端校验不通过
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"` + `details`

---

### Requirement: Token 刷新

#### Scenario: 刷新成功

- **GIVEN** 请求携带有效的 refresh_token Cookie
- **WHEN** 客户端提交 `POST /api/auth/refresh`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含新的 `access_token` 和 `expires_in: 1800`
- **AND** 原 refresh_token 保持不变（不轮转）

#### Scenario: 刷新失败——refresh_token 无效或已在黑名单

- **GIVEN** refresh_token 过期、被篡改、或已被加入黑名单
- **WHEN** 客户端提交 `POST /api/auth/refresh`
- **THEN** 返回 HTTP `401 Unauthorized`
- **AND** 响应体 `error_code: "invalid_refresh_token"`

---

### Requirement: 获取当前用户信息

系统 SHALL 提供 `GET /api/auth/me` 端点，需 JWT 认证，返回当前用户的基础信息（含 profile 摘要字段）。

#### Scenario: 已登录用户

- **WHEN** 已登录用户 GET `/api/auth/me`（携带有效 JWT）
- **THEN** 返回 HTTP 200，响应体包含 `{ request_id, id, email, state, created_at, nickname, avatar_url, username }`

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 HTTP 401
