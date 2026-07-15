## ADDED Requirements

### Requirement: AI 聊天请求走 BFF 代理

AI 聊天的所有 HTTP 请求 SHALL 通过 Next.js `/api/*` 代理路径发送，使用 `authFetch` 携带认证 Token，不得直接访问后端地址。

#### Scenario: AI 聊天请求走代理路径

- **GIVEN** 用户已登录，Access Token 存在于 Zustand store
- **WHEN** 用户发送 AI 聊天消息
- **THEN** 请求 SHALL 发往 `/api/ai/chat`（相对路径），Authorization header SHALL 包含 `Bearer <access_token>`
- **AND** 请求 SHALL NOT 包含 `NEXT_PUBLIC_BACKEND_URL` 或直连后端地址

#### Scenario: AI 创建会话走代理路径

- **GIVEN** 用户已登录
- **WHEN** 创建新的 AI 会话
- **THEN** 请求 SHALL 发往 `/api/ai/conversations`（相对路径），使用 `authFetch`
- **AND** 网络错误时 SHALL 返回可控结果，不裸抛异常

#### Scenario: 后端地址不暴露给客户端

- **WHEN** 检查客户端 bundle 或运行时变量
- **THEN** SHALL NOT 存在 `NEXT_PUBLIC_BACKEND_URL` 变量的引用

### Requirement: 安全响应头

所有页面响应 SHALL 包含以下安全响应头。

#### Scenario: CSP 头存在

- **WHEN** 访问任意页面
- **THEN** 响应头 SHALL 包含 `Content-Security-Policy`，值至少包含 `default-src 'self'` 和 `frame-ancestors 'none'`

#### Scenario: X-Frame-Options 头存在

- **WHEN** 访问任意页面
- **THEN** 响应头 SHALL 包含 `X-Frame-Options: DENY`

#### Scenario: X-Content-Type-Options 头存在

- **WHEN** 访问任意页面
- **THEN** 响应头 SHALL 包含 `X-Content-Type-Options: nosniff`

#### Scenario: Referrer-Policy 头存在

- **WHEN** 访问任意页面
- **THEN** 响应头 SHALL 包含 `Referrer-Policy: strict-origin-when-cross-origin`

### Requirement: cover_image URL 协议白名单

`createPost` API 函数 SHALL 对 `cover_image` 字段做 URL 协议校验，拒绝非 `http`/`https` 协议的 URL。

#### Scenario: 拒绝 javascript 协议

- **WHEN** 调用 `createPost({ cover_image: "javascript:alert(1)", ... })`
- **THEN** SHALL 返回 `error.error_code === "validation_error"`，不发出网络请求

#### Scenario: 拒绝 data 协议

- **WHEN** 调用 `createPost({ cover_image: "data:text/html,<script>alert(1)</script>", ... })`
- **THEN** SHALL 返回 `error.error_code === "validation_error"`

#### Scenario: 允许合法 https URL

- **WHEN** 调用 `createPost({ cover_image: "https://example.com/img.jpg", ... })`
- **THEN** SHALL 正常发出请求，不拦截

#### Scenario: 允许 null cover_image

- **WHEN** 调用 `createPost({ cover_image: null, ... })`
- **THEN** SHALL 正常发出请求，不触发校验

### Requirement: 中间件设计限制文档化

`middleware.ts` SHALL 包含注释说明：中间件仅检查 cookie 存在性不验证有效性，安全兜底由 `authFetch` 的 401 自动重定向保证。

#### Scenario: 中间件注释存在

- **WHEN** 检查 `middleware.ts` 源码
- **THEN** SHALL 包含注释说明 cookie 存在性检查的设计决策和兜底机制
