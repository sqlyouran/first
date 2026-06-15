## Why

景点后端 API 已就绪（`spots-backend-api` change），`GET /api/spots/{id}` 返回完整景点数据（gallery、tags、rating 等）。但前端尚无景点详情页，用户从首页/列表页点击景点后无处可去。同时帖子互动组件（BookmarkButton / CommentSection）硬绑 `postId`，无法复用于景点。本次变更新建景点详情页，并将互动组件泛化为支持 `entityType` 参数。

## What Changes

- 新增 **景点详情页** `app/spots/[id]/page.tsx`（Server Component），SSR 预取景点详情 + 收藏状态
- 新增 **SpotGallery** 组件：基于 shadcn Carousel 实现主图 + 缩略图条联动（双 Carousel 同步滚动）
- 新增 **SpotInfo** 组件：两列布局展示景点基本信息（城市、名称、状态、统计等）
- 新增 **RelatedPosts** 预留区块：骨架屏 + "即将上线" 占位，等 SpotPostEntity 关联表就绪后对接
- **泛化 BookmarkButton**：props 从 `postId` 改为 `entityId + entityType`（POST/SPOT），API 调用路径根据 entityType 动态拼接
- **泛化 CommentSection / CommentInput / CommentItem**：props 从 `postId` 改为 `entityId + entityType`
- **泛化 `lib/api/interactions.ts`**：收藏和评论 API 函数接受 `entityType` 参数，URL 拼接 `/api/{type}s/{id}/bookmark` 等
- 帖子详情页现有调用适配新 props 签名（传入 `entityType="post"`）

## Capabilities

### New Capabilities

- `spots-frontend-detail`: 景点详情页完整实现（Gallery + 缩略图条、基本信息两列布局、收藏/评论复用、相关攻略预留）

### Modified Capabilities

- `post-interactions-frontend`: BookmarkButton / CommentSection / interactions.ts 从 `postId` 泛化为 `entityId + entityType`，帖子详情页调用适配

## Impact

- **新增文件**: `app/spots/[id]/page.tsx`、`app/spots/[id]/_components/SpotGallery.tsx`、`SpotInfo.tsx`、`RelatedPosts.tsx`
- **修改文件**: `app/posts/_components/BookmarkButton.tsx`、`CommentSection.tsx`、`CommentInput.tsx`、`CommentItem.tsx`、`lib/api/interactions.ts`、`app/posts/[id]/page.tsx`
- **依赖**: 无新增（Carousel / lucide-react 已在锁定栈内）
- **前置依赖**: `polymorphic-interactions-backend` change（提供景点收藏/评论后端 API）
- **不涉及**: 景点列表页、帖子列表页、发帖页、认证流程
