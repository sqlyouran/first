## Why

帖子详情页当前只展示静态内容（标题、封面、Markdown 正文、标签）。后端已完成评论、投票、收藏三个互动模块的 API（`post-interactions-backend` change），但前端尚无对应交互组件。用户无法在帖子页面进行投票、收藏或评论，产品缺乏社区互动能力。

## What Changes

- 新增 **投票按钮组**（VoteButtons）：👍/👎 按钮 + 计数显示，登录用户点击乐观更新，未登录跳登录页
- 新增 **收藏按钮**（BookmarkButton）：书签图标切换填充/空心状态，乐观更新，未登录跳登录页
- 新增 **评论区**（CommentSection）：评论输入框 + 评论列表（顶层 + 回复），展示 2 层嵌套 + "查看更多"加载更深回复，未登录隐藏输入框
- 新增 **互动 API 客户端层**（`lib/api/interactions.ts`）：封装投票/收藏/评论所有 API 调用，使用 `authFetch` + `ApiResponse<T>`
- 新增 **后端 bookmark-status 端点**：`GET /api/posts/{id}/bookmark-status` 用于 SSR 预取收藏初始状态
- 引入 **sonner** 作为 toast 通知库（shadcn/ui 官方推荐），在根布局添加 `<Toaster />`
- Server Component 预取投票统计 + 收藏状态，作为 initial props 传给 Client 互动组件

## Capabilities

### New Capabilities

- `post-interactions-frontend`: 帖子详情页前端互动组件（投票、收藏、评论）的完整实现，包括 API 客户端层、乐观更新逻辑、评论区 UI、toast 集成

### Modified Capabilities

- `posts-frontend`: 帖子详情页（`app/posts/[id]/page.tsx`）需增加互动组件区和 SSR 预取逻辑

## Impact

- **新增依赖**：`sonner`（toast 通知库，~3KB）
- **新增组件文件**：`app/posts/_components/` 下新增 VoteButtons / BookmarkButton / CommentSection / CommentList / CommentItem / CommentInput（均为 Client Component）
- **新增 API 文件**：`lib/api/interactions.ts`
- **修改文件**：`app/posts/[id]/page.tsx`（插入互动组件 + SSR 预取）、`app/layout.tsx`（添加 `<Toaster />`）、`package.json`（sonner 依赖）
- **后端新增**：`GET /api/posts/{id}/bookmark-status` 端点（BookmarkController + BookmarkService）
- **不涉及**：帖子列表页、发帖页、认证流程、路由守卫
