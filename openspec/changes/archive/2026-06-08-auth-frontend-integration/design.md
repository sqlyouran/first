## Context

前端 Auth 页面（login/register）已实现完毕，通过 `lib/mock/auth.ts` 驱动。后端 Spring Boot Auth API 7 个端点已上线（send-code、register、login、refresh、logout、me、delete-me）。当前缺口：前端仍调用 mock 而非真实后端。

现状架构：
- 前端 `lib/api/auth.ts` → 调用 `lib/mock/auth.ts`
- Auth Store（Zustand）仅管理 `accessToken` + `isAuthenticated`
- `next.config.ts` 无 rewrites 配置
- `.env.local` 已有 `BACKEND_URL=http://localhost:8080`
- 后端 refresh_token 通过 HttpOnly Cookie（SameSite=Strict, Path=/api/auth）下发

## Goals / Non-Goals

**Goals:**
- 前端 login/register 页面走通真实后端 API
- Token 自动刷新（access_token 过期时透明续期）
- 页面刷新后会话恢复（基于 refresh_token Cookie）
- 路由守卫：未登录不可访问受保护页，已登录不看 auth 页
- Auth Store 持有完整用户信息
- Logout 调用真实后端 API 并清除 Cookie

**Non-Goals:**
- Token 存储持久化到 localStorage（内存即可，靠 refresh_token Cookie 恢复）
- 邮箱验证重发流程（属于后续 scope）
- 用户资料编辑 / 修改密码
- 删除账户功能联通
- SSR 鉴权（Server Component 读 token）

## Decisions

### D1: API 代理方式——Next.js rewrites

**选择**: `next.config.ts` 的 `rewrites` 配置  
**替代方案**: Route Handlers (`app/api/**/route.ts`) 作为代理  
**理由**: rewrites 是纯配置零代码，且项目约束禁止在 Route Handlers 中写业务逻辑。同域代理使浏览器自动携带 HttpOnly Cookie，无需手动管理。

```ts
rewrites: () => [{ source: '/api/:path*', destination: 'http://localhost:8080/api/:path*' }]
```

### D2: authFetch wrapper 设计

**选择**: 独立 `lib/api/authFetch.ts` 模块，包装 fetch 添加 Authorization header + 401 自动刷新  
**策略**:
1. 请求前从 auth store 读取 accessToken，添加 `Authorization: Bearer <token>` header
2. 如果响应 401 且本次未重试过 → 调 `POST /api/auth/refresh` → 更新 store token → 重试原请求
3. 如果 refresh 也失败（401）→ 调用 store.logout() + redirect to /login
4. 使用 Promise 锁防止并发刷新

### D3: Auth Store 扩展

**选择**: 在现有 Zustand store 上扩展  
**新增状态**: `user: { id, email, state, created_at } | null`、`isInitialized: boolean`  
**新增 actions**: `fetchMe()`、`logout()`、`initialize()`  
**`initialize()`**: app 启动时调用，尝试 refresh → me，设 `isInitialized = true`（无论成功失败）

### D4: 路由守卫——Middleware + AuthProvider 双层

**层级 1 (Middleware)**: 
- 读取 `refresh_token` Cookie 是否存在（不验证有效性）
- 无 Cookie + 访问受保护路由 → redirect to `/login`
- 有 Cookie + 访问 `/login` 或 `/register` → redirect to `/`
- 受保护路由 matcher: 除 `/login`、`/register`、`/`、`/_next`、`/api` 外的所有路径

**层级 2 (AuthProvider)**:
- 包裹在 `layout.tsx` 中
- 挂载时调用 `store.initialize()` → refresh → me
- 提供 `isInitialized` 状态供子组件判断是否显示 loading

### D5: AuthResponse 类型对齐

**选择**: 前端 `AuthResponse` 直接映射后端统一格式  
**结构**:
```ts
interface ApiResponse<T = unknown> {
  status: number;
  data?: T;
  error?: { request_id: string; error_code: string; message: string; details?: Record<string, string> };
}
```
页面通过 `res.error?.error_code` 分支处理错误场景。

### D6: Mock 文件处理

**选择**: 保留 `lib/mock/auth.ts` 不删除  
**理由**: 单元测试仍可 import mock 函数做集成场景验证；`lib/api/auth.ts` 不再 import 它，仅测试文件引用。

## Risks / Trade-offs

- **[风险] refresh_token Cookie 过期后无感知** → Mitigation: refresh 失败时 redirect 到 /login，用户重新登录
- **[风险] 并发请求同时 401 触发多次 refresh** → Mitigation: authFetch 内部用 Promise 锁确保单次刷新
- **[风险] Middleware 只检查 Cookie 存在性不验证有效性** → Mitigation: 这是有意设计，粗粒度快速拦截；真正验证在客户端 AuthProvider
- **[权衡] accessToken 只存内存** → 刷新页面需要重新走 refresh 链路，多一次 API 调用但安全性更高
- **[权衡] 首页 `/` 不纳入保护路由** → 首页是公开页面，未登录也能访问
