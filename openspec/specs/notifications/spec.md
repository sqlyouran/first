## ADDED Requirements

### Requirement: NotificationEntity 实体

系统 SHALL 提供 `NotificationEntity` 继承 `BaseEntity`，包含 `recipient_id`(UUID)、`actor_id`(UUID)、`type`(NotificationType ENUM)、`entity_id`(UUID, NULLABLE)、`entity_type`(VARCHAR 20, NULLABLE)、`content_preview`(VARCHAR 200, NULLABLE)、`read`(BOOLEAN, default false)。索引 `(recipient_id, read, created_at DESC)`。

#### Scenario: 持久化通知

- **WHEN** 创建一条通知记录
- **THEN** 数据库正确写入所有字段，`created_at` 自动填充

---

### Requirement: 通知创建（互动触发）

系统 SHALL 在用户互动操作时同步创建通知：点赞帖子 → `POST_LIKED`、评论帖子 → `POST_COMMENTED`、回复评论 → `COMMENT_REPLIED`、收藏帖子 → `POST_BOOKMARKED`。

#### Scenario: 帖子被点赞

- **WHEN** 用户 B 点赞用户 A 的帖子
- **THEN** 为用户 A 创建一条 `POST_LIKED` 通知，`actor_id` = B，`entity_id` = 帖子 ID

#### Scenario: 帖子被评论

- **WHEN** 用户 B 在用户 A 的帖子下发表评论
- **THEN** 为用户 A 创建 `POST_COMMENTED` 通知，`content_preview` = 评论前 50 字

#### Scenario: 评论被回复

- **WHEN** 用户 B 回复用户 A 的评论
- **THEN** 为用户 A 创建 `COMMENT_REPLIED` 通知

#### Scenario: 帖子被收藏

- **WHEN** 用户 B 收藏用户 A 的帖子
- **THEN** 为用户 A 创建 `POST_BOOKMARKED` 通知

#### Scenario: 自我过滤

- **WHEN** 用户 A 点赞/评论/收藏自己的帖子
- **THEN** 不创建通知

#### Scenario: 去重策略

- **WHEN** 用户 B 对用户 A 的帖子 X 重复点赞（toggle 后重新点赞）
- **THEN** 取消点赞时删除已有通知，重新点赞时创建新通知

---

### Requirement: 通知列表查询

系统 SHALL 提供 `GET /api/notifications?page=1&size=20` 端点，需 JWT 认证，返回分页通知列表（按 `created_at DESC`）。

#### Scenario: 正常分页

- **WHEN** 用户有 25 条通知，GET `?page=1&size=20`
- **THEN** 返回 `{ items: [...20条], total: 25, page: 1, size: 20, request_id }`

#### Scenario: 包含触发者信息

- **WHEN** 返回通知列表
- **THEN** 每条通知包含 `actor: { nickname, avatar_url, username }` 和 `target_title`（帖子标题）

---

### Requirement: 标记单条通知已读

系统 SHALL 提供 `POST /api/notifications/{id}/read` 端点，需 JWT 认证。

#### Scenario: 标记已读

- **WHEN** POST 一条未读通知的 read 端点
- **THEN** 该通知 `read` 变为 true，返回 HTTP 200

#### Scenario: 操作他人通知

- **WHEN** 尝试标记不属于自己的通知
- **THEN** 返回 HTTP 404

---

### Requirement: 标记全部已读

系统 SHALL 提供 `POST /api/notifications/mark-all-read` 端点，需 JWT 认证。

#### Scenario: 全部标记

- **WHEN** 用户有 10 条未读通知，POST 该端点
- **THEN** 所有通知 `read` 变为 true，返回 HTTP 200 + `{ updated_count: 10 }`

---

### Requirement: 未读计数

系统 SHALL 提供 `GET /api/notifications/unread-count` 端点，需 JWT 认证。

#### Scenario: 有未读

- **WHEN** 用户有 5 条未读通知
- **THEN** 返回 `{ count: 5, request_id }`

#### Scenario: 无未读

- **WHEN** 用户所有通知已读
- **THEN** 返回 `{ count: 0, request_id }`
