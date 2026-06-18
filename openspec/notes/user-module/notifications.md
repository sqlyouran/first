# 消息通知（Notifications）PRD

## 1. 背景与目标

WanderChina 已有点赞（Vote）、评论（Comment）、收藏（Bookmark）等互动功能，但用户无法知道自己发布的内容被他人互动了。缺少通知系统会严重降低用户回访率和内容创作动力。

**目标**：建立站内互动通知系统，让用户及时收到被点赞、被评论、被收藏的通知，并支持已读/未读状态管理。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 内容创作者 | 发布帖子后，收到他人点赞/评论/收藏通知 |
| 活跃用户 | 打开通知列表，快速浏览所有未读通知 |
| 导航栏用户 | 通过 badge 数字感知未读通知数量 |

## 3. 用户故事

### US-1: 接收互动通知

```
As a content creator,
I want to receive notifications when someone likes, comments on, or bookmarks my post,
So that I know my content is being engaged with.

Acceptance Criteria:
- Given user A published a post, When user B likes that post, Then user A receives a "post_liked" notification
- Given user A published a post, When user B comments on that post, Then user A receives a "post_commented" notification
- Given user A published a post, When user B bookmarks that post, Then user A receives a "post_bookmarked" notification
- Given user A posted a comment, When user B replies to that comment, Then user A receives a "comment_replied" notification
- Given I like/comment/bookmark my own content, When the action completes, Then I do NOT receive a self-notification
```

### US-2: 查看通知列表

```
As a logged-in user,
I want to view all my notifications in a chronological list,
So that I can review interactions with my content.

Acceptance Criteria:
- Given I navigate to /notifications, When the page loads, Then I see a list of notifications sorted by time (newest first)
- Given I have notifications, When I view the list, Then each notification shows: actor avatar+nickname, action type, target content title, and relative timestamp
- Given I click a notification, When the action triggers, Then I am navigated to the related content and the notification is marked as read
```

### US-3: 已读/未读管理

```
As a logged-in user,
I want to distinguish between read and unread notifications,
So that I can focus on new interactions.

Acceptance Criteria:
- Given I have 5 unread notifications, When I view the notification list, Then unread items are visually highlighted (bold text + blue dot indicator)
- Given I click on an unread notification, When the navigation happens, Then that notification is marked as read
- Given I click "Mark all as read", When the action completes, Then all my notifications become read state
- Given I have 3 unread notifications, When I look at the navigation bar, Then I see a badge showing "3" on the bell icon
```

### US-4: 导航栏通知入口

```
As a logged-in user,
I want to see a notification bell icon with unread count badge in the navigation bar,
So that I'm aware of new interactions without navigating to the notification page.

Acceptance Criteria:
- Given I am logged in and have unread notifications, When I view any page, Then I see a bell icon with a numeric badge in the top navigation bar
- Given I have 0 unread notifications, When I view the nav bar, Then the bell icon shows no badge
- Given I have more than 99 unread notifications, When I view the badge, Then it shows "99+"
- Given I click the bell icon, When the action triggers, Then I navigate to /notifications
```

## 4. 功能规格

### 4.1 通知类型

| 类型 | 触发条件 | 通知文案 | 跳转目标 |
|------|---------|---------|---------|
| `post_liked` | 他人点赞我的帖子 | "{actor} liked your post {title}" | 帖子详情页 |
| `post_commented` | 他人在我的帖子下发表评论 | "{actor} commented on your post {title}" | 帖子详情页（锚定评论区） |
| `comment_replied` | 他人回复我的评论 | "{actor} replied to your comment on {title}" | 帖子详情页（锚定回复） |
| `post_bookmarked` | 他人收藏我的帖子 | "{actor} bookmarked your post {title}" | 帖子详情页 |

> 景点评论不产生通知（景点非用户创建，无通知接收者）。

### 4.2 业务规则

- **去重策略**：同一用户对同一内容的重复互动，不产生重复通知。例如用户 B 取消点赞后重新点赞，只保留最新一条通知（更新而非新增）
- **自我过滤**：用户不会收到自己操作产生的通知
- **不聚合**：每条通知独立展示，本期不做批量聚合（如 "50 people liked your post"）
- **通知保留**：通知永久保留，不做自动清理
- **未读计数**：`SELECT COUNT(*) FROM notifications WHERE recipient_id = ? AND read = false`，badge 上限显示 "99+"
- **无实时推送**：用户进入页面或刷新时拉取最新通知，不使用 WebSocket/SSE

### 4.3 页面/交互说明

| 路由 | 组件类型 | 说明 |
|------|---------|------|
| `/notifications` | Client Component | 通知列表页，支持实时标记已读 |

**通知列表**：
- 分页加载：每页 20 条，滚动加载更多
- 未读通知左侧带蓝色竖线 + 文字加粗
- 每条通知显示：触发者头像（小尺寸）+ 触发者昵称 + 通知文案 + 相对时间（如 "2h ago"）
- 点击通知条目 → 标记已读 + 跳转到对应内容页
- 顶部有 "Mark all as read" 按钮

**导航栏**：
- 登录用户右上角 bell icon（lucide-react `Bell`）
- 未读数 > 0 时显示 badge（红色圆点 + 数字）
- 未读数 > 99 时显示 "99+"
- 点击 bell icon 跳转 `/notifications`

## 5. 数据需求

新增 `NotificationEntity`：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | UUID | PK | 通知唯一 ID |
| `recipient_id` | UUID | NOT NULL | 通知接收者（关联 users.id） |
| `actor_id` | UUID | NOT NULL | 触发者（关联 users.id） |
| `type` | ENUM | NOT NULL | 通知类型：post_liked / post_commented / comment_replied / post_bookmarked |
| `entity_id` | UUID | NULLABLE | 关联内容 ID（帖子/评论 ID） |
| `entity_type` | ENUM | NULLABLE | 内容类型：POST |
| `content_preview` | VARCHAR(200) | NULLABLE | 内容摘要（如评论前 50 字） |
| `read` | BOOLEAN | NOT NULL, default false | 是否已读 |
| `created_at` | TIMESTAMP | NOT NULL | 通知创建时间 |

**索引**：
- `(recipient_id, read, created_at DESC)` — 未读通知查询 + 列表分页

## 6. 非功能需求

- **性能**：未读计数接口响应 < 200ms（数据库 COUNT 直接查询，无需缓存）
- **一致性**：通知在互动操作完成后 1 秒内可见（同步写入，非异步队列）
- **无障碍**：通知条目支持键盘导航，`aria-label` 描述通知内容

## 7. 验收标准

- [ ] 帖子被点赞时，帖子作者收到 `post_liked` 通知
- [ ] 帖子被评论时，帖子作者收到 `post_commented` 通知
- [ ] 评论被回复时，评论者收到 `comment_replied` 通知
- [ ] 帖子被收藏时，帖子作者收到 `post_bookmarked` 通知
- [ ] 自己操作自己的内容不产生通知
- [ ] 同一用户对同一内容重复互动不产生重复通知
- [ ] `/notifications` 页面按时间倒序展示通知列表
- [ ] 未读通知有视觉区分（蓝色竖线 + 文字加粗）
- [ ] 点击通知跳转到对应内容并标记已读
- [ ] "Mark all as read" 按钮一键全部已读
- [ ] 导航栏 bell icon 显示未读数量 badge（99+ 封顶）
- [ ] 通知列表支持分页（每页 20 条，滚动加载）

## 8. 边界清单

| 边界场景 | 处理方式 |
|---------|---------|
| 被互动内容已删除 | 通知仍展示，点击后显示"内容已删除"提示，不跳转 |
| 触发者账户已删除 | 通知中显示 "Deleted user"，头像为默认占位图 |
| 未读通知超过 99 | Badge 显示 "99+" |
| 大量通知（1000+） | 分页加载，每页 20 条，不影响性能 |
| 点赞 toggle（取消后重新点赞） | 取消点赞时删除对应通知；重新点赞时创建新通知 |
| 通知接收者的帖子被删除后又被互动 | 通知仍生成（帖子虽删但互动记录保留） |
| 景点评论 | 不产生通知（景点非用户创建） |

## 9. 优先级与排期建议

| 优先级 | 功能项 |
|--------|-------|
| 🔴 P0 | 通知生成（点赞/评论/回复/收藏触发）|
| 🔴 P0 | 通知列表页 + 已读/未读状态 |
| 🔴 P0 | 导航栏 bell badge 未读计数 |
| 🟠 P1 | 点击通知跳转对应内容 |
| 🟠 P1 | "Mark all as read" 批量操作 |

## 10. 依赖关系

- 依赖个人中心的 `nickname` + `avatar_url` 用于通知中展示触发者身份
- 依赖已有的 Vote / Comment / Bookmark Service 在互动操作时触发通知创建
- 通知类型仅限帖子相关互动（景点评论不触发）
