## 1. 后端 — NotificationEntity + 基础设施

- [x] 1.1 创建 `NotificationType` 枚举：`POST_LIKED`、`POST_COMMENTED`、`COMMENT_REPLIED`、`POST_BOOKMARKED`
- [x] 1.2 创建 `NotificationEntity` 继承 `BaseEntity`：`recipient_id`(UUID)、`actor_id`(UUID)、`type`(NotificationType, STRING)、`entity_id`(UUID, NULLABLE)、`entity_type`(VARCHAR 20, NULLABLE)、`content_preview`(VARCHAR 200, NULLABLE)、`read`(BOOLEAN, default false)
- [x] 1.3 创建 `NotificationRepository` 继承 `JpaRepository<NotificationEntity, UUID>`，含 `findByRecipientIdAndReadFalseAndDeletedFalse`、`countByRecipientIdAndReadFalseAndDeletedFalse`、`findByRecipientIdAndActorIdAndTypeAndEntityIdAndDeletedFalse` 方法
- [x] 1.4 创建 `NotificationService`（构造器注入 `NotificationRepository` + `UserRepository` + `PostRepository`）

## 2. 后端 — 通知创建逻辑

- [x] 2.1 编写 `NotificationService.createNotification()` 成功测试（帖子被点赞 → 创建 POST_LIKED 通知）
- [x] 2.2 编写自我过滤测试（自己点赞自己帖子 → 不创建通知）
- [x] 2.3 编写去重测试（同用户同内容重复互动 → 不产生重复通知）
- [x] 2.4 实现 `NotificationService.createNotification()`（含自我过滤 + 去重查询）
- [x] 2.5 实现 `NotificationService.deleteNotification()`（取消点赞时删除对应通知）

## 3. 后端 — 通知 API 端点

- [x] 3.1 创建 `NotificationController` + Request/Response DTO（`NotificationListResponse`、`NotificationItemResponse`、`UnreadCountResponse`、`MarkAllReadResponse`）
- [x] 3.2 编写 `GET /api/notifications?page=1&size=20` 测试（成功分页 + 未认证 401 + 包含 actor 信息 + target_title）
- [x] 3.3 实现 `GET /api/notifications` 端点（JOIN user 表获取 actor nickname/avatar_url/username，JOIN post 表获取 title）
- [x] 3.4 编写 `POST /api/notifications/{id}/read` 测试（标记成功 + 操作他人通知 404）
- [x] 3.5 实现 `POST /api/notifications/{id}/read` 端点
- [x] 3.6 编写 `POST /api/notifications/mark-all-read` 测试（批量标记 + 返回 updated_count）
- [x] 3.7 实现 `POST /api/notifications/mark-all-read` 端点
- [x] 3.8 编写 `GET /api/notifications/unread-count` 测试（有未读 + 无未读）
- [x] 3.9 实现 `GET /api/notifications/unread-count` 端点

## 4. 后端 — 互动 Service 植入通知调用

- [x] 4.1 编写 `VoteService.toggleVote()` 通知集成测试（点赞 → 创建通知 + 取消点赞 → 删除通知 + 自我点赞不通知）
- [x] 4.2 修改 `VoteService.toggleVote()` 调用 `NotificationService.createNotification()` / `deleteNotification()`
- [x] 4.3 编写 `CommentService.createComment()` 通知集成测试（评论帖子 → 创建 POST_COMMENTED + 回复评论 → 创建 COMMENT_REPLIED + 自我评论不通知）
- [x] 4.4 修改 `CommentService.createComment()` 调用 `NotificationService.createNotification()`（含 content_preview = 评论前 50 字）
- [x] 4.5 编写 `BookmarkService.toggleBookmark()` 通知集成测试（收藏 → 创建通知 + 取消收藏 → 删除通知）
- [x] 4.6 修改 `BookmarkService.toggleBookmark()` 调用 `NotificationService.createNotification()` / `deleteNotification()`

## 5. 前端 — API 封装层

- [ ] 5.1 创建 `lib/api/notifications.ts`：`fetchNotifications(page, size)`、`markAsRead(id)`、`markAllRead()`、`fetchUnreadCount()`
- [ ] 5.2 定义 TypeScript 类型：`NotificationData`、`NotificationItem`、`UnreadCountData`、`MarkAllReadData`

## 6. 前端 — notifications Zustand store

- [ ] 6.1 创建 `lib/stores/notifications.ts`：`unreadCount`、`setUnreadCount`、`decrementUnread`、`resetUnread`、`fetchUnreadCount`
- [ ] 6.2 编写 notifications store 测试

## 7. 前端 — 通知列表页 /notifications

- [ ] 7.1 创建 `app/notifications/page.tsx`（Client Component，含分页 + 状态管理）
- [ ] 7.2 创建 `app/notifications/_components/NotificationItem.tsx`（单条通知，含 unread/read/hover/actor-deleted/target-deleted 5 种状态）
- [ ] 7.3 创建 `app/notifications/_components/NotificationTypeIcon.tsx`（4 种类型图标 + 颜色映射）
- [ ] 7.4 实现四态覆盖：Loading 骨架（6 条）/ Content / Empty（BellOff 引导）/ Error（AlertCircle + Retry）
- [ ] 7.5 实现分页加载（Intersection Observer + loadMore 状态：loading/error/hasMore）
- [ ] 7.6 实现 "Mark all as read" 按钮（enabled/disabled/submitting/success/error 5 种状态 + 乐观更新）
- [ ] 7.7 实现点击通知条目行为（未读 → 标记已读乐观更新 + 跳转；已删除 target → toast 不跳转）
- [ ] 7.8 实现相对时间显示（just now / Xm / Xh / Xd / Xw / 日期）
- [ ] 7.9 实现响应式布局（Mobile 紧凑头部 + icon-only 按钮 / Tablet+ 完整头部）
- [ ] 7.10 编写 `/notifications` 页面测试

## 8. 前端 — NotificationBell 导航栏组件

- [ ] 8.1 创建 `app/_components/NotificationBell.tsx`（Client Component，Bell icon + 未读 badge）
- [ ] 8.2 实现 8 种状态：未登录不渲染 / 0 未读无 badge / 1-9 / 10-99 / 100+（99+）/ hover / loading / fetch 失败静默
- [ ] 8.3 实现未读数刷新策略（挂载 + visibilitychange + 乐观更新 + 60s 轮询）
- [ ] 8.4 导航栏集成 NotificationBell（位于 UserDropdown 左侧）
- [ ] 8.5 编写 NotificationBell 组件测试

## 9. 前端 — 路由守卫

- [ ] 9.1 `middleware.ts` 的 `PROTECTED_PAGES` 新增 `/notifications`
- [ ] 9.2 编写 middleware 测试更新
