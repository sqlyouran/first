## ADDED Requirements

### Requirement: 获取当前用户信息

系统 SHALL 提供 `GET /api/auth/me` 端点，需 JWT 认证，返回当前用户的基础信息（含 profile 摘要字段）。

#### Scenario: 已登录用户

- **WHEN** 已登录用户 GET `/api/auth/me`（携带有效 JWT）
- **THEN** 返回 HTTP 200，响应体包含 `{ request_id, id, email, state, created_at, nickname, avatar_url, username }`

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 HTTP 401
