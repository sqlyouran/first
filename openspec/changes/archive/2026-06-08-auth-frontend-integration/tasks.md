## 1. API 代理配置

- [x] 1.1 `next.config.ts` 添加 rewrites 规则：`/api/:path*` → `http://localhost:8080/api/:path*`
- [x] 1.2 验证：启动前后端，`curl http://localhost:3000/api/auth/send-code` 能代理到后端

## 2. API 客户端重写

- [x] 2.1 定义 `ApiResponse<T>` 类型（对齐后端统一格式：status + data + error）
- [x] 2.2 重写 `lib/api/auth.ts`：login / sendCode / register 改为真实 fetch，返回 `ApiResponse`
- [x] 2.3 新增 `lib/api/auth.ts` 中 `refreshToken()` 和 `fetchMe()` 和 `logout()` 函数

## 3. authFetch wrapper

- [x] 3.1 创建 `lib/api/authFetch.ts`：自动附加 Authorization header
- [x] 3.2 实现 401 自动刷新逻辑（单次重试 + Promise 锁防并发）
- [x] 3.3 refresh 失败时调用 store.logout() + redirect to /login
- [x] 3.4 编写 authFetch 单元测试（正常 / 401 刷新 / refresh 失败）

## 4. Auth Store 扩展

- [x] 4.1 扩展 Zustand store：新增 `user`、`isInitialized` 状态
- [x] 4.2 实现 `initialize()` action：refresh → fetchMe → set isInitialized
- [x] 4.3 实现 `logout()` action：调用后端 /logout + 清状态
- [x] 4.4 实现 `fetchMe()` action：调用 /me 写入 user
- [x] 4.5 编写 auth store 单元测试

## 5. AuthProvider 组件

- [x] 5.1 创建 `components/AuthProvider.tsx`（client component）：挂载时调用 store.initialize()
- [x] 5.2 在 `app/layout.tsx` 中包裹 AuthProvider
- [x] 5.3 编写 AuthProvider 单元测试

## 6. Login 页面适配

- [x] 6.1 修改 `app/(auth)/login/page.tsx`：使用新 ApiResponse 结构，通过 `res.error?.error_code` 处理错误
- [x] 6.2 更新 login 页面测试（mock fetch 而非 mock module）

## 7. Register 页面适配

- [x] 7.1 修改 `app/(auth)/register/page.tsx`：使用新 ApiResponse 结构
- [x] 7.2 新增 409 `email_already_registered` 处理：显示「该邮箱已注册，请直接登录」+ 「去登录」链接
- [x] 7.3 更新 register 页面测试

## 8. Next.js Middleware 路由守卫

- [x] 8.1 创建 `frontend/middleware.ts`：检查 refresh_token Cookie + 路由重定向逻辑
- [x] 8.2 配置 matcher：排除 `/`、`/_next`、`/api`、静态资源
- [x] 8.3 编写 middleware 单元测试

## 9. 网络异常兜底

- [x] 9.1 在 `lib/api/auth.ts` 中统一 try-catch：网络错误返回特定 error_code（`network_error`），500/502/503 返回 `server_error`
- [x] 9.2 login/register 页面增加通用错误分支：显示「网络连接失败」或「服务暂时不可用」
- [x] 9.3 编写网络异常场景单元测试

## 10. 端到端验收

- [x] 10.1 启动前后端，手动验证：注册 → 登录 → 刷新页面恢复状态 → 登出
- [x] 10.2 验证路由守卫：未登录访问受保护路由跳转 /login；已登录访问 /login 跳转 /
- [x] 10.3 `npm test` 全绿
