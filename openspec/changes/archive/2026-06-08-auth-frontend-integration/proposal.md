## Why

前端 Auth 页面（登录/注册）目前通过 mock API 驱动，后端 Auth API 已实现完毕（7 个端点全部就绪）。需要完成前后端联通，使用户能走通真实的注册→登录→会话保持→登出全链路。同时补齐 token 自动刷新、路由守卫等生产必备能力。

## What Changes

- **API 代理层**：`next.config.ts` 配置 rewrites，将 `/api/**` 代理到后端 `http://localhost:8080`
- **API 客户端替换**：`lib/api/auth.ts` 从调用 mock 改为真实 `fetch('/api/auth/...')`，响应类型对齐后端统一格式 `{request_id, error_code, message, details}`
- **authFetch wrapper**：封装带 token 自动刷新的 fetch 工具函数（401 → 尝试 /refresh → retry / logout）
- **Auth Store 扩展**：增加 user info（id, email, state）、fetchMe()、logout() 调真实 API
- **Login 页面适配**：对齐新 AuthResponse 结构
- **Register 页面适配**：对齐新 AuthResponse 结构 + 增加 409 `email_already_registered` 友好提示
- **路由守卫（Middleware + Client）**：Next.js Middleware 粗粒度拦截（检查 refresh_token Cookie 存在性）；客户端 AuthProvider 细粒度验证（启动时 /refresh → /me 恢复状态）
- **已登录重定向**：已登录用户访问 /login 或 /register 自动跳转到 /

## Capabilities

### New Capabilities
- `auth-frontend-integration`: 前端 Auth 联通层——API 代理、authFetch wrapper、token 自动刷新、路由守卫、AuthProvider 会话恢复

### Modified Capabilities
- `auth-frontend`: 增加 409 邮箱已注册处理、Auth Store 扩展（user info + fetchMe + logout API）、已登录重定向逻辑

## Impact

- **前端文件**：`next.config.ts`、`lib/api/auth.ts`、`lib/stores/auth.ts`、`app/(auth)/login/page.tsx`、`app/(auth)/register/page.tsx`、新增 `lib/api/authFetch.ts`、新增 `middleware.ts`、新增 AuthProvider 组件
- **测试**：现有 mock 相关测试需更新为 mock fetch；新增 authFetch / middleware / AuthProvider 单元测试
- **依赖**：无新增 npm 依赖（纯 fetch + Next.js 内置 middleware）
- **后端**：无改动
