## Why

当前帖子列表页使用传统 offset 分页（上一页/下一页），用户体验割裂；PostCard 互动统计始终显示 0 值造成视觉噪音；排序切换后分页状态与数据不同步。需要统一升级为无限滚动 + cursor 分页，让浏览体验流畅连贯。

## What Changes

- **PostCard 互动统计优化**：零值项隐藏（避免视觉噪音），大数字格式化（>999 显示为 "1.2k"）
- **无限滚动加载**：IntersectionObserver 监听列表底部，触底自动加载下一页（cursor 分页），底部显示 3 张骨架卡占位，到底后显示"已经到底啦"
- **排序 Tab 切换重载**：切换排序时清空列表 + 重置 cursor，重新加载首页数据
- **后端 keyset 全排序支持**：扩展 cursor 分页第到 MOST_UPVOTED / MOST_COMMENTED 排序（复合 cursor：`voteCount:createdAt` / `commentCount:createdAt`），首次加载（无 cursor）也返回 `next_cursor` 启动无限滚动

## Capabilities

### New Capabilities

（无新增独立 capability，全部为已有 capability 修改）

### Modified Capabilities

- `posts-backend-api`：cursor 分页从仅 LATEST 扩展到全排序，首次加载也返回 `next_cursor`，新增复合 cursor 编码/解码逻辑和对应的 Repository keyset 查询
- `posts-frontend`：PostCard 统计零值隐藏 + 数字格式化，帖子列表页从 offset 分页切换为 IntersectionObserver 无限滚动，排序切换触发列表清空重载

## Impact

**后端代码**：
- `PostService.listPosts` / `listUserPosts` — 统一 keyset 分支（去掉 `sort == LATEST` 限制），offset 首次加载也构建 cursor
- `PostRepository` — 新增 `findByUpVoteCountCursor` / `findByCommentCountCursor` + 用户帖子变体（复合 WHERE 条件）
- `PostSortBy` — 新增 `encodeCursor` / `decodeCursor` 辅助方法

**前端代码**：
- `app/posts/_components/PostCard.tsx` — 统计行条件渲染 + `formatCount` 工具函数
- `app/posts/page.tsx` — 状态从 `page` 改为 `items[]` + `nextCursor` + `isLoadingMore`，IntersectionObserver hook，排序切换清空逻辑
- `lib/api/posts.ts` — 无签名变化，已有 cursor 参数可直接使用

**API 契约**：
- `GET /api/posts` 和 `GET /api/users/{userId}/posts` — `next_cursor` 在所有排序模式下均返回非 null（有数据时），不再仅限 LATEST
