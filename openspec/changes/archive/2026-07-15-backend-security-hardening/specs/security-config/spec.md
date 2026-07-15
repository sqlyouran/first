## ADDED Requirements

### Requirement: Spring Security 白名单鉴权

`SecurityConfig` SHALL 配置 `SecurityFilterChain`，使用白名单模式。公开接口显式 `permitAll()`，其余所有接口默认需要有效 JWT Bearer Token。

#### Scenario: 公开接口无需认证可访问

- **WHEN** 客户端不带 Authorization header 请求 `GET /api/posts`
- **THEN** HTTP 200，正常返回帖子列表

#### Scenario: 公开接口 POST auth/login 无需认证

- **WHEN** 客户端不带 Authorization header 请求 `POST /api/auth/login`
- **THEN** 正常处理登录逻辑（401 仅因凭据错误，非因鉴权拒绝）

#### Scenario: 需认证接口无 Token 返回 401

- **WHEN** 客户端不带 Authorization header 请求 `POST /api/posts`
- **THEN** HTTP 401，响应 `error_code: "unauthorized"`

#### Scenario: 需认证接口带有效 Token 正常访问

- **GIVEN** 用户已登录，持有有效 access_token
- **WHEN** 客户端携带 `Authorization: Bearer <token>` 请求 `POST /api/posts`
- **THEN** HTTP 201，正常创建帖子

#### Scenario: 需认证接口带过期 Token 返回 401

- **GIVEN** 用户持有一个已过期的 access_token
- **WHEN** 客户端携带该过期 Token 请求 `POST /api/posts`
- **THEN** HTTP 401，响应 `error_code: "unauthorized"`

---

### Requirement: JwtAuthenticationFilter

系统 SHALL 提供 `JwtAuthenticationFilter`（继承 `OncePerRequestFilter`），注册在 SecurityFilterChain 中 `UsernamePasswordAuthenticationFilter` 之前。该 Filter 从 `Authorization: Bearer <token>` 解析 JWT，校验签名和有效期，校验通过则将用户信息设置到 SecurityContext。

#### Scenario: Filter 跳过公开接口

- **WHEN** 请求路径匹配白名单（如 `/api/auth/login`）
- **THEN** Filter 不做 JWT 校验，直接放行

#### Scenario: Filter 校验失败不阻断请求

- **WHEN** 请求路径不在白名单且 Authorization header 缺失或 Token 无效
- **THEN** Filter 设置 `authentication = null`，由 Spring Security 返回 401

#### Scenario: Filter 校验成功设置 SecurityContext

- **GIVEN** 请求携带有效 Bearer Token，subject 为用户 UUID
- **WHEN** Filter 解析 Token
- **THEN** `SecurityContextHolder.getContext().getAuthentication()` 非 null
- **AND** authentication 的 principal 包含用户 UUID

---

### Requirement: CORS 环境变量配置

`WebConfig` 的 `allowedOrigins` SHALL 从环境变量 `CORS_ALLOWED_ORIGINS` 读取（逗号分隔多域名），默认值 `http://localhost:3000`。

#### Scenario: 开发环境使用默认 CORS

- **GIVEN** 未设置 `CORS_ALLOWED_ORIGINS` 环境变量
- **WHEN** 前端 `http://localhost:3000` 发起跨域请求
- **THEN** CORS 预检通过，请求正常处理

#### Scenario: 生产环境配置多域名

- **GIVEN** `CORS_ALLOWED_ORIGINS=https://wanderchina.com,https://www.wanderchina.com`
- **WHEN** 来自 `https://wanderchina.com` 的跨域请求
- **THEN** CORS 预检通过

---

### Requirement: ForwardedHeaderFilter 真实 IP

`SecurityConfig` SHALL 注册 Spring 内置 `ForwardedHeaderFilter`，使其在 `RequestIdFilter` 之后执行。在反向代理（Nginx）环境下，`request.getRemoteAddr()` SHALL 返回 `X-Forwarded-For` 中的客户端真实 IP。

#### Scenario: 反向代理环境获取真实 IP

- **GIVEN** 请求经 Nginx 转发，header 包含 `X-Forwarded-For: 203.0.113.50`
- **WHEN** Controller 调用 `request.getRemoteAddr()`
- **THEN** 返回 `203.0.113.50` 而非 Nginx 的内网 IP

---

### Requirement: 管理接口认证保护

以下接口 SHALL 需要有效 JWT Bearer Token（不在白名单中）：
- `GET /api/spots/stale`
- `POST /api/spots/enrichment/trigger`
- `GET /api/spots/enrichment/report/latest`
- `POST /api/ai/knowledge/rebuild`

#### Scenario: 未认证访问管理接口被拒绝

- **WHEN** 客户端不带 Authorization header 请求 `POST /api/spots/enrichment/trigger`
- **THEN** HTTP 401

#### Scenario: 认证用户访问管理接口正常

- **GIVEN** 用户持有有效 Token
- **WHEN** 请求 `GET /api/spots/stale`
- **THEN** HTTP 200，正常返回过期景点列表
