## Why

平台已有点赞、评论、收藏等互动功能，但用户无法感知他人对自己内容的互动。缺少通知系统导致用户回访率低、内容创作动力不足。

## What Changes

- 新增 `NotificationEntity` 实体，记录互动通知（类型、触发者、接收者、关联内容、已读状态）
- 新增后端 API：通知列表分页、单条标记已读、全部标记已读、未读计数查询
- 在 Vote / Comment / Bookmark Service 中植入通知创建逻辑（去重 + 自我过滤）
- 新增前端页面：`/notifications`（通知列表）
- 导航栏新增 Bell icon + 未读 badge
- `middleware.ts` 新增 `/notifications` 路由守卫

## Capabilities

### New Capabilities
- `notifications`: 站内互动通知系统——通知生成（点赞/评论/回复/收藏触发）、通知列表分页、已读/未读管理、未读计数

### Modified Capabilities
- `post-interactions-backend`: Vote / Comment / Bookmark 操作需植入通知创建调用
- `polymorphic-interactions`: 评论回复操作需植入 `comment_replied` 通知创建

## Impact

- **Backend**: 新增 `NotificationEntity` + `NotificationRepository` + `NotificationService` + `NotificationController`、修改 `VoteService` / `CommentService` / `BookmarkService`
- **Frontend**: 新增 `/notifications` 页面、`NotificationBell` 组件、`notifications` Zustand store
- **Database**: 新增 `notifications` 表 + 索引 `(recipient_id, read, created_at)`
- **Middleware**: `PROTECTED_PAGES` 新增 `/notifications`
- **依赖**: 依赖 `user-profile` change 的 nickname + avatar_url 展示触发者身份
