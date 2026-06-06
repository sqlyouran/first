## Context

auth spec (`openspec/specs/auth/spec.md`) 已完整定义后端 API 契约（注册、登录、Token 管理、状态机、风控），但后端尚未实现。前端首页骨架已落地（Next.js 16 App Router + Tailwind + shadcn/ui），需要并行推进 auth 前端页面，用 mock API 解耦后端依赖。

当前前端无状态管理库，无 auth 相关路由。

## Goals / Non-Goals

**Goals:**

- 落地 `/login` 和 `/register` 两个独立页面，覆盖 auth spec 中定义的所有前端可感知场景
- 建立 Zustand auth store 管理 access_token 和用户状态
- 提供 mock API 层，模拟后端响应（含各种错误态）
- 表单前端校验 + 后端错误态展示

**Non-Goals:**

- 不实现真实后端 API 对接（等后端落地后替换 mock）
- 不实现 OAuth 社交登录、密码重置
- 不修改首页导航（登录态入口为后续变更 scope）
- 不实现 token 自动刷新拦截器（后续变更）
- 不实现注册/登录页面之间的路由守卫

## Decisions

### 1. 路由结构：独立页面

**选择**：`/login` 和 `/register` 为独立路由页面（`app/(auth)/login/page.tsx`、`app/(auth)/register/page.tsx`）

**替代方案**：同一页面 tab 切换

**理由**：
- Next.js 文件路由天然支持，零额外成本
- 注册是多步流程（发码 → 填码+密码），塞进 tab 会让单页过重
- URL 语义清晰，可分享直达链接
- 行业惯例（GitHub / Google / Vercel 均为独立页面）

### 2. 状态管理：Zustand

**选择**：Zustand 管理 auth state（token + user info + actions）

**替代方案**：React Context / 模块闭包变量

**理由**：
- 精确订阅，避免 Context 全树重渲染
- 极小体积（~2KB），几乎无成本
- slice 模式天然适合后续扩展（user profile、权限）
- 任意位置 import 即可访问，不受 Provider 树约束

### 3. Mock 策略：模块级 mock 函数

**选择**：`lib/mock/auth.ts` 导出与真实 API 同签名的函数，通过环境变量或条件 import 切换

**替代方案**：MSW (Mock Service Worker) / Next.js Route Handlers 做 mock server

**理由**：
- 最简方案，YAGNI 原则——当前只有 auth 一组 API
- 函数签名与未来真实 API client 一致，替换时只需改 import 路径
- 无额外依赖

### 4. 注册流程：两步式（同页内状态切换）

**选择**：`/register` 页面内部分两步——Step 1: 输入邮箱发送验证码 → Step 2: 输入验证码 + 密码完成注册

**理由**：
- 符合 auth spec 的两步契约（send-code → register）
- 同一页面内切换 step，UX 连贯
- 避免多余路由

### 5. UI 组件：shadcn/ui

**选择**：复用项目已有的 shadcn/ui 组件（Button、Input、Card）

**理由**：技术栈已锁定，一致性

## Risks / Trade-offs

- **[Mock 与真实 API 行为偏差]** → Mock 严格按 auth spec 的 HTTP 状态码和响应结构实现；替换时有 spec 做验收基准
- **[Zustand 新依赖]** → 体积极小（2KB gzip），且长期项目必然需要客户端状态管理，引入时机合理
- **[Token 存内存刷新即丢]** → 符合 spec 设计（refresh_token 在 Cookie 中），刷新页面后靠 refresh 接口恢复（后续变更实现）
