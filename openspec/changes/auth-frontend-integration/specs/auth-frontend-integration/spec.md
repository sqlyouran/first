## ADDED Requirements

### Requirement: Next.js API Rewrites 代理

系统 SHALL 通过 Next.js rewrites 将前端 `/api/**` 请求代理到后端 Spring Boot 服务，实现同域部署。

#### Scenario: 开发环境代理到本地后端

- **WHEN** 前端发起 `fetch('/api/auth/login')` 请求
- **THEN** Next.js dev server 将请求转发到 `http://localhost:8080/api/auth/login`
- **AND** 后端 Set-Cookie 响应头透传给浏览器

---

### Requirement: authFetch 自动刷新 wrapper

系统 SHALL 提供 `authFetch` 函数，自动附加 Authorization header 并在 access_token 过期时透明刷新。

#### Scenario: 正常请求携带 token

- **WHEN** 调用 `authFetch(url, options)` 且 auth store 中有 accessToken
- **THEN** 请求 header 自动添加 `Authorization: Bearer <accessToken>`

#### Scenario: 401 触发自动刷新

- **WHEN** 请求返回 HTTP 401 且本次调用未重试过
- **THEN** 自动调用 `POST /api/auth/refresh`
- **AND** refresh 成功后用新 token 重试原请求
- **AND** auth store 中 accessToken 更新为新值

#### Scenario: refresh 失败触发登出

- **WHEN** refresh 请求也返回 401
- **THEN** 调用 auth store 的 logout action
- **AND** 页面重定向到 `/login`

#### Scenario: 并发 401 只刷新一次

- **WHEN** 多个请求同时收到 401
- **THEN** 只发起一次 refresh 请求
- **AND** 所有等待中的请求使用同一个新 token 重试

---

### Requirement: AuthProvider 会话恢复

系统 SHALL 在 app 启动时自动尝试恢复登录状态。

#### Scenario: 有 refresh_token Cookie 时恢复成功

- **WHEN** 用户刷新页面且浏览器中有 refresh_token Cookie
- **THEN** AuthProvider 调用 `/api/auth/refresh` 获取新 access_token
- **AND** 调用 `/api/auth/me` 获取用户信息写入 store
- **AND** `isInitialized` 设为 `true`

#### Scenario: 无 Cookie 或恢复失败

- **WHEN** 浏览器无 refresh_token Cookie 或 refresh 请求失败
- **THEN** auth store 保持未认证状态
- **AND** `isInitialized` 设为 `true`（不阻塞页面渲染）

#### Scenario: 初始化期间显示 loading

- **WHEN** AuthProvider 正在执行 initialize 且 `isInitialized` 为 `false`
- **THEN** 受保护页面显示 loading 状态而非内容

---

### Requirement: Next.js Middleware 路由守卫

系统 SHALL 在服务端通过 Next.js Middleware 实现粗粒度路由保护。

#### Scenario: 未登录访问受保护路由

- **WHEN** 请求中无 `refresh_token` Cookie 且路径为受保护路由
- **THEN** 返回 302 重定向到 `/login`

#### Scenario: 已登录访问 auth 页面

- **WHEN** 请求中有 `refresh_token` Cookie 且路径为 `/login` 或 `/register`
- **THEN** 返回 302 重定向到 `/`

#### Scenario: 公开路由不拦截

- **WHEN** 路径为 `/`、`/_next/*`、`/api/*`、或静态资源
- **THEN** 请求正常通过，不做任何重定向

---

### Requirement: Logout 全链路

系统 SHALL 提供完整的登出功能，调用后端 API 并清理前端状态。

#### Scenario: 正常登出

- **WHEN** 用户触发 logout action
- **THEN** 调用 `POST /api/auth/logout`（携带 refresh_token Cookie）
- **AND** 后端清除 refresh_token Cookie（Set-Cookie Max-Age=0）
- **AND** auth store 清空 accessToken 和 user 信息
- **AND** 页面重定向到 `/login`

---

### Requirement: 网络异常与通用错误兜底

系统 SHALL 在所有 auth 相关请求中统一处理网络异常和未预期错误，确保用户不会看到空白或无反馈状态。

#### Scenario: 网络中断

- **WHEN** fetch 抛出 TypeError（网络断开、DNS 解析失败等）
- **THEN** 页面显示「网络连接失败，请检查网络后重试」

#### Scenario: 后端 500 内部错误

- **WHEN** 后端返回 HTTP 500
- **THEN** 页面显示「服务暂时不可用，请稍后重试」

#### Scenario: 未预期的状态码

- **WHEN** 后端返回非预期状态码（如 502、503 等）
- **THEN** 页面显示「服务暂时不可用，请稍后重试」
- **AND** 不暴露技术细节给用户
