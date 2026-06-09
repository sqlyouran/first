## Why

帖子后端 API 已完成（`posts-backend-api` change），但前端尚无对应页面。需要实现帖子列表、详情、发帖三个页面，让用户能真正使用 posts 功能。同时更新 middleware 路由守卫和 API 封装层。

## What Changes

- 新增 `app/posts/` 路由目录：列表页（`/posts`）、发帖页（`/posts/create`）、详情页（`/posts/[id]`）
- 新增 `lib/api/posts.ts` API 封装，复用 `ApiResponse<T>` + `parseResponse` 模式
- 提取 `lib/api/client.ts` 通用工具（`parseResponse` / `networkError` / `serverError`），消除与 `auth.ts` 的重复
- 更新 `middleware.ts` 路由守卫：公开 `/posts` 和 `/posts/[id]`，仅保护 `/posts/create`
- 引入 `@uiw/react-md-editor` + `react-markdown` + `remark-gfm` 依赖
- 详情页使用 Server Component（SSR），列表和表单使用 Client Component

## Capabilities

### New Capabilities
- `posts-frontend`: 帖子前端页面（列表、详情、发帖）、API 封装、共享组件、middleware 路由守卫更新

### Modified Capabilities

（无）

## Impact

- **代码**: `frontend/app/posts/`（新增 3 个页面 + `_components/`）、`frontend/lib/api/`（新增 + 重构）、`frontend/middleware.ts`（更新）
- **依赖**: `@uiw/react-md-editor`、`react-markdown`、`remark-gfm`
- **API**: 调用已完成的 `POST/PUT/DELETE/GET /api/posts` 和 `GET /api/users/{id}/posts`
- **配置**: `middleware.ts` matcher 逻辑更新
