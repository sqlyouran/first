# 站内信（Direct Messages）PRD

## 1. 背景与目标

WanderChina 作为旅游社区平台，用户之间可能需要就旅行经验、路线规划等进行私下交流。当前平台没有用户间直接沟通的渠道，只能通过帖子评论区公开互动。

**目标**：提供用户间一对一私信功能，支持发送文字消息、查看会话列表和历史消息记录。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 旅行者 | 看到某用户的攻略很好，想私信询问细节 |
| 内容创作者 | 收到其他用户的私信提问，回复旅行建议 |
| 活跃用户 | 管理多个会话，查看未读消息 |

## 3. 用户故事

### US-1: 发起私信

```
As a logged-in user,
I want to send a direct message to another user,
So that I can have a private conversation about travel topics.

Acceptance Criteria:
- Given I am viewing another user's profile, When I click "Send Message", Then I am navigated to a conversation page with that user
- Given I am on the conversation page with user B, When I type a message and click send, Then the message appears in the conversation thread
- Given no prior conversation exists with user B, When I send the first message, Then a new conversation is created
- Given I try to send a message to myself, When the action triggers, Then the system prevents it with an error message "You cannot message yourself"
```

### US-2: 查看会话列表

```
As a logged-in user,
I want to view all my conversations in a list,
So that I can manage my private messages.

Acceptance Criteria:
- Given I navigate to /messages, When the page loads, Then I see a list of conversations sorted by most recent message time (newest first)
- Given I have conversations, When I view the list, Then each item shows: other user's avatar+nickname, last message preview (truncated to 50 chars), relative timestamp, and unread count badge
- Given I have no conversations, When I view /messages, Then I see an empty state with a prompt "Start a conversation by messaging another traveler"
```

### US-3: 查看消息历史

```
As a logged-in user,
I want to view the full message history with another user,
So that I can reference past conversations.

Acceptance Criteria:
- Given I click on a conversation from the list, When the conversation page loads, Then I see the most recent 50 messages in chronological order (oldest at top, newest at bottom)
- Given the conversation has more than 50 messages, When I scroll to the top, Then older messages are loaded via pagination (50 per page)
- Given I view a conversation, When the page loads, Then all messages from the other user in this conversation are marked as read
```

### US-4: 未读消息提醒

```
As a logged-in user,
I want to see unread message indicators in the navigation bar,
So that I know when someone has sent me a new message.

Acceptance Criteria:
- Given user B sends me a message while I am on a different page, When I look at the nav bar, Then the message icon shows an unread badge with the total unread count
- Given I have 3 conversations with unread messages totaling 7 messages, When I view /messages list, Then the nav badge shows "7"
- Given I open a conversation with unread messages, When the conversation loads, Then the unread count for that conversation resets to 0 and the nav badge updates
```

### US-5: 从他人资料页发起对话

```
As a logged-in user,
I want to start a conversation from another user's profile page,
So that I can quickly reach out to someone whose content I appreciate.

Acceptance Criteria:
- Given I am viewing user B's public profile and I am logged in, When I see the profile page, Then a "Send Message" button is prominently displayed
- Given I click "Send Message" on user B's profile, When the navigation happens, Then I am taken to the existing conversation with user B (or a new conversation page if none exists)
- Given I am not logged in, When I view user B's profile, Then the "Send Message" button is not visible
```

## 4. 功能规格

### 4.1 核心流程

**发起新对话流程**：
1. 用户从他人资料页点击 "Send Message"
2. Service 层查询两用户间是否已有会话（若无则创建）
3. 进入对话页面 `/messages/{conversationId}`
4. 输入第一条消息并发送
5. 消息出现在对话流中，对方会话列表新增该会话

**回复已有对话流程**：
1. 用户从 `/messages` 会话列表选择对话
2. 进入 `/messages/{conversationId}`
3. 查看历史消息 + 输入新消息
4. 发送后消息追加到对话流

### 4.2 消息规格

| 字段 | 约束 |
|------|------|
| 内容 (content) | 1–2000 字符，纯文本（不支持富文本/图片/链接预览） |
| 发送频率限制 | 同一会话中，单用户每分钟最多发送 20 条消息（防刷） |

### 4.3 业务规则

- **会话唯一性**：两个用户之间有且仅有一个会话，由 Service 层在创建时查询判断（不依赖数据库复合唯一约束）
- **对称可见**：会话双方均可看到完整的消息历史
- **不可撤回**：已发送的消息不可撤回或删除
- **自我限制**：不能给自己发消息，Service 层校验并拒绝
- **消息已读**：进入对话页面时，对方发送的所有消息标记为已读
- **会话排序**：按最新消息时间倒序排列（`last_message_at`）
- **消息预览**：会话列表中显示最后一条消息的前 50 个字符
- **无系统消息**：所有消息均为用户发起，系统不发公告（通知系统承担此角色）
- **无消息搜索**：本期不提供消息内容搜索功能
- **无屏蔽/拉黑**：本期不提供屏蔽或拉黑功能

### 4.4 页面/交互说明

| 路由 | 组件类型 | 说明 |
|------|---------|------|
| `/messages` | Client Component | 会话列表页 |
| `/messages/{conversationId}` | Client Component | 对话详情页 |

**会话列表页 `/messages`**：
- 使用卡片样式展示每个会话
- 每张卡片：对方头像（圆形）+ 昵称 + 最后消息预览（截断 50 字）+ 相对时间 + 未读数 badge
- 空状态：居中图标 + "Start a conversation by messaging another traveler" + CTA
- 点击卡片 → 进入对话详情页

**对话详情页 `/messages/{conversationId}`**：
- 顶部：对方头像 + 昵称 + 返回按钮（← Back to Messages）
- 消息区域：聊天气泡 UI
  - 自己发送：靠右，蓝色气泡（`bg-blue-700 text-white`）
  - 对方发送：靠左，灰色气泡（`bg-slate-100 text-slate-900`）
  - 每条消息下方显示发送时间（小字灰色）
- 底部输入区：
  - 文本输入框（支持多行，Shift+Enter 换行）
  - 发送按钮（Enter 直接发送）
  - 字符计数（接近 2000 时显示）
  - 频率限制触发时显示提示

**导航栏**：
- 登录用户右上角消息 icon（lucide-react `MessageCircle`）
- 未读消息总数 > 0 时显示 badge（红色圆点 + 数字）
- 点击 message icon 跳转 `/messages`

## 5. 数据需求

**ConversationEntity**（会话）：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | UUID | PK | 会话唯一 ID |
| `user_a_id` | UUID | NOT NULL | 会话一方用户 ID |
| `user_b_id` | UUID | NOT NULL | 会话另一方用户 ID |
| `last_message_at` | TIMESTAMP | NOT NULL | 最后消息时间（用于排序） |
| `created_at` | TIMESTAMP | NOT NULL | 会话创建时间 |
| `updated_at` | TIMESTAMP | NOT NULL | 最后更新时间 |

> 会话唯一性由 Service 层在创建前查询保证：查找 `user_a_id` 和 `user_b_id` 组合（无论顺序）是否已存在会话。

**MessageEntity**（消息）：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `id` | UUID | PK | 消息唯一 ID |
| `conversation_id` | UUID | NOT NULL, FK | 所属会话 ID |
| `sender_id` | UUID | NOT NULL | 发送者用户 ID |
| `content` | TEXT | NOT NULL, max 2000 chars | 消息纯文本内容 |
| `read` | BOOLEAN | NOT NULL, default false | 对方是否已读 |
| `created_at` | TIMESTAMP | NOT NULL | 消息发送时间 |

**索引**：
- `conversations`: `(user_a_id, user_b_id)` — 会话查找
- `messages`: `(conversation_id, created_at DESC)` — 消息历史分页查询
- `messages`: `(conversation_id, read, sender_id)` — 未读消息计数

## 6. 非功能需求

- **性能**：会话列表加载 < 500ms，消息历史分页加载 < 300ms
- **无障碍**：对话区域使用 `role="log"` + `aria-live="polite"`，新消息到达时屏幕阅读器播报
- **安全**：消息内容做 XSS 过滤（HTML 转义存储，纯文本渲染）
- **频率限制**：每分钟 20 条/会话，超出返回 HTTP 429 + `error_code: "rate_limited"`

## 7. 验收标准

- [ ] 已登录用户可从他人资料页发起私信（"Send Message" 按钮）
- [ ] 两用户之间有且仅有一个会话（Service 层保证）
- [ ] 自己不能给自己发消息（前端阻止 + 后端 422）
- [ ] 消息内容为纯文本，1-2000 字符
- [ ] `/messages` 展示会话列表，按最新消息时间倒序排列
- [ ] `/messages/{id}` 展示对话消息历史，最新 50 条 + 滚动加载更多
- [ ] 进入对话后，对方消息自动标记为已读
- [ ] 导航栏消息 icon 显示未读消息总数 badge
- [ ] 空会话列表有引导提示
- [ ] 未登录用户无法访问 `/messages`（重定向到登录页）
- [ ] 消息发送频率限制：每分钟 20 条/会话

## 8. 边界清单

| 边界场景 | 处理方式 |
|---------|---------|
| 对方账户已删除（state=deleted） | 会话列表仍显示，标注 "Deleted user"，不可发送新消息（后端 422） |
| 消息内容包含 HTML/XSS | 后端 HTML 转义存储，前端纯文本渲染 |
| 消息超过 2000 字符 | 前端输入框字符计数 + 禁用发送按钮，后端 422 `validation_error` |
| 短时间大量发送（刷屏） | 限流：每分钟 20 条/会话，超出返回 429 `rate_limited` |
| 空会话（无消息） | 不存在——会话创建与第一条消息发送原子化（Service 层保证） |
| 并发创建会话（两次点击发起） | Service 层加锁/幂等：第二次查询到已有会话直接复用 |
| 消息发送后对方下线 | 消息持久化，对方下次上线后可见 |
| 导航栏未读数计算 | `SUM` 所有会话中对方发送且 `read=false` 的消息数 |

## 9. 优先级与排期建议

| 优先级 | 功能项 |
|--------|-------|
| 🔴 P0 | 发送/接收纯文本消息 |
| 🔴 P0 | 会话列表（含未读计数 badge） |
| 🔴 P0 | 对话消息历史（分页加载） |
| 🟠 P1 | 从他人资料页 "Send Message" 入口 |
| 🟠 P1 | 导航栏消息 badge |
| 🟠 P1 | 进入对话自动标记已读 |
| 🟠 P1 | 消息发送频率限制（20 条/分钟） |

## 10. 依赖关系

- 依赖个人中心的 `nickname` + `avatar_url` 用于会话列表和对话中展示对方身份
- 依赖他人资料页（`/users/{username}`）提供 "Send Message" 入口
- 依赖认证系统（JWT token）识别当前用户
