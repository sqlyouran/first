## Context

平台已有 Vote（点赞）、Comment（评论）、Bookmark（收藏）互动功能，后端 Service 层已稳定。用户无法感知他人对自己内容的互动，缺乏回访动力。

已有基础设施：
- `VoteEntity` / `CommentEntity` / `BookmarkEntity` + 对应 Service
- `PostEntity.authorId` 可确定帖子作者（通知接收者）
- `CommentEntity.userId` 可确定评论者（回复通知接收者）
- JWT 认证 + `GlobalExceptionHandler`
- 前端 `sonner` toast + Zustand store 模式

依赖：`user-profile` change 提供的 nickname/avatar_url 用于通知展示。

## Goals / Non-Goals

**Goals:**
- 帖子被点赞/评论/收藏时生成通知，评论被回复时生成通知
- 通知列表分页展示，支持已读/未读状态管理
- 导航栏 Bell icon 显示未读计数 badge
- 去重策略（同用户同内容不重复）+ 自我过滤

**Non-Goals:**
- 不做通知聚合（"50 people liked your post"）
- 不做分类筛选 Tab
- 不做景点评论通知（景点非用户创建）
- 不做实时推送（WebSocket/SSE）
- 不做 Redis 缓存未读计数

## Decisions

### D1: 通知创建时机——Service 层同步写入

**决策**：在 `VoteService.toggleVote()`、`CommentService.createComment()`、`BookmarkService.toggleBookmark()` 中同步调用 `NotificationService.createNotification()`

**理由**：同步写入保证通知在互动操作完成后立即可见。本期数据量可控，无需异步队列。

### D2: 去重策略——按 (recipient_id, actor_id, type, entity_id) 查找

**决策**：`NotificationService` 在创建前先查询是否存在相同 `(recipient_id, actor_id, type, entity_id)` 的通知：
- 存在 → 更新 `created_at`（不新增）
- 不存在 → 新增

**理由**：同一用户对同一内容的 toggle 操作（取消点赞再点赞）不产生重复通知。

### D3: 通知类型枚举

**决策**：`NotificationType` 枚举包含 4 个值：`POST_LIKED`、`POST_COMMENTED`、`COMMENT_REPLIED`、`POST_BOOKMARKED`

**理由**：覆盖 PRD 定义的 4 种互动通知，景点评论不纳入。

### D4: 未读计数——数据库 COUNT

**决策**：`GET /api/notifications/unread-count` 直接 `SELECT COUNT(*) WHERE recipient_id = ? AND read = false`

**理由**：本期 DAU 较小，数据库 COUNT 足够。后续可升级 Redis 缓存。

### D5: 点赞 toggle 时的通知处理

**决策**：取消点赞时**删除**对应通知（如果存在）；重新点赞时**创建新**通知

**理由**：避免已取消互动的通知残留。

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| 同步写入通知增加互动操作延迟 | 通知表轻量（单行 INSERT），影响 < 5ms |
| 帖子被删除后通知仍可点击 | 前端检测 target 已删除，toast 提示不跳转 |
| 大量通知时列表性能 | 分页 20 条/页 + 数据库索引 `(recipient_id, read, created_at)` |
| 并发通知写入 | 去重查询 + INSERT 非原子操作，极端并发可能有少量重复——可接受 |
