## Why

帖子列表当前仅返回基础摘要（id / title / cover_image / tags / status / created_at），缺少互动统计数据，用户无法在列表页感知帖子热度。分页仅支持 offset 模式，无法满足无限滚动场景；排序固定为 `created_at DESC`，缺乏按热度排序能力。

## What Changes

- **PostResponse 增强**：列表项追加 `comment_count` / `up_vote_count` / `bookmark_count` 三个聚合字段，通过批量查询获取（不在 PostEntity 存冗余字段）
- **分页增强**：`created_at` 排序同时支持 cursor-based 和 offset 分页；cursor 与 page 参数互斥，优先 cursor
- **排序支持**：新增 `sort` 参数，可选 `latest`（默认）/ `most_upvoted` / `most_commented`；聚合排序仅支持 offset 分页
- **PostListResponse 增强**：新增 `next_cursor` / `has_more` 字段
- **listUserPosts 同步增强**：`GET /api/users/{userId}/posts` 与全局列表保持一致的增强
- **前端 PostCard 展示**：卡片底部新增互动统计行（点赞 / 评论 / 收藏图标 + 数字）
- **前端排序切换 UI**：帖子列表页新增排序选项卡

## Capabilities

### New Capabilities

（无新增 capability）

### Modified Capabilities

- `posts-backend-api`: 列表接口增加互动统计字段、cursor 分页、排序参数
- `posts-frontend`: PostCard 展示互动统计、列表页排序切换 UI

## Impact

- **后端代码**：`PostService` / `PostController` / `PostResponse` / `PostListResponse` 重构；`PostRepository` / `VoteRepository` / `BookmarkRepository` / `CommentRepository` 新增批量聚合查询方法
- **API 契约**：`GET /api/posts` 和 `GET /api/users/{userId}/posts` 响应结构变更（新增字段 + cursor 分页字段）
- **前端代码**：`PostCard.tsx` 新增统计行；`posts/page.tsx` 新增排序 UI；`lib/api/posts.ts` 类型 + 函数签名更新
- **数据库**：无 schema 变更（聚合查询基于已有表），无新依赖
