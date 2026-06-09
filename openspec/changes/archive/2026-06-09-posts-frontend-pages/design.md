## Context

- 帖子后端 API（`posts-backend-api`）已完成，提供 CRUD + 分页端点
- 前端已有 `lib/api/auth.ts` + `lib/api/authFetch.ts` 作为 API 封装参考
- `next.config.ts` 通过 rewrites 将 `/api/*` 代理到 `localhost:8080`
- `lib/backend.ts` 提供 `fetchFromBackend()` 供 Server Component 直连后端
- `middleware.ts` 当前对所有非首页路由做认证守卫
- 样式栈：Tailwind CSS 4 + shadcn/ui + lucide-react

## Goals / Non-Goals

**Goals:**
- 实现帖子列表、详情、发帖三个页面
- 提取通用 API 工具到 `lib/api/client.ts`
- 更新 middleware 路由守卫，仅保护 `/posts/create`
- 引入 Markdown 编辑器/渲染库
- 遵循 frontend-conventions + styling-conventions

**Non-Goals:**
- 不做帖子编辑页面（后续 change）
- 不做帖子删除 UI（后续 change）
- 不做帖子搜索/筛选（后续 change）
- 不做用户帖子列表独立页面（后续 change）

## Decisions

### D1: API 通用工具提取到 `lib/api/client.ts`

**决策**: 将 `parseResponse` / `networkError` / `serverError` / `ApiError` / `ApiResponse` 从 `auth.ts` 提取到 `client.ts`。`auth.ts` 改为从 `client.ts` 导入。

**理由**: posts API 是第二个模块，通用工具出现在第三处（DRY 原则）。后续每个 API 模块都会复用。

**替代方案**: 在 `posts.ts` 中重新定义 → 违反 DRY，且每次新增模块都要复制。

### D2: 详情页 Server Component，列表/表单 Client Component

**决策**:
- `app/posts/[id]/page.tsx` → Server Component，使用 `fetchFromBackend()` SSR 预取
- `app/posts/page.tsx` → Client Component（`"use client"`），需要分页交互
- `app/posts/create/page.tsx` → Client Component（`"use client"`），表单交互

**理由**: 遵循 frontend-conventions「默认 Server Component，仅在需要交互时加 `"use client"`」。详情页是只读展示；列表需要分页按钮；表单需要输入。

### D3: Markdown 编辑器选型 `@uiw/react-md-editor`

**决策**: 发帖页使用 `@uiw/react-md-editor`，详情页渲染使用 `react-markdown` + `remark-gfm`。

**理由**: 开箱即用带工具栏 + 实时预览，开发量最小。`react-markdown` 是详情页标准渲染方案。

**替代方案**:
- `react-markdown-editor-lite` → 太轻量，需自己搭配渲染
- 纯 textarea → 开发量大，用户体验差

### D4: Middleware 路由守卫策略

**决策**: 反转逻辑为白名单保护。定义 `PROTECTED_PAGES = ["/posts/create"]`，仅对这些路径做认证守卫。其余路径全部放行。

**理由**: 未来新增公开页面（如 `/posts/[id]`）无需改 middleware。比黑名单更安全。

**替代方案**: 黑名单豁免 → 每次新增公开页面都要更新 middleware，容易遗漏。

### D5: 列表页分页 — 客户端状态管理

**决策**: 列表页使用 `useState` 管理 `page` + `size`，点击分页按钮时重新 `fetch`。不引入 Zustand store。

**理由**: 分页是页面级局部状态，不需要跨组件共享。YAGNI 原则。

### D6: 共享组件放 `_components/` 目录

**决策**: `PostCard` / `TagInput` / `PostForm` 放 `app/posts/_components/`。

**理由**: 遵循 frontend-conventions 路由组内部复用组件模式。当前仅 posts 路由使用，不放全局 `components/`。

### D7: authFetch 复用

**决策**: 写操作（POST/PUT/DELETE）使用 `authFetch()`（自动附加 Bearer token + 401 自动 refresh）。GET 操作使用普通 `fetch`（公开端点无需认证）。

**理由**: 已有的 `authFetch` 处理了 token 刷新 + 并发锁，无需重写。

## Risks / Trade-offs

- **`@uiw/react-md-editor` 样式冲突** → 通过 CSS 覆盖 shadcn 主题变量对齐；如冲突严重可在 `_components/PostForm.tsx` 中 scoped 覆盖
- **Server Component 直连后端需要 `BACKEND_URL`** → 部署时确保环境变量配置；本地开发已有
- **rewrites 代理硬编码 `localhost:8080`** → 当前开发阶段可接受；生产环境需改为环境变量（后续 change）
