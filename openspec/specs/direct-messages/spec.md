## ADDED Requirements

### Requirement: ConversationEntity 实体

系统 SHALL 提供 `ConversationEntity` 继承 `BaseEntity`，包含 `user_a_id`(UUID)、`user_b_id`(UUID)、`last_message_at`(TIMESTAMP)。

#### Scenario: 持久化会话

- **WHEN** 创建一条会话记录
- **THEN** 数据库正确写入，`user_a_id` 和 `user_b_id` 分别存储两用户 ID

---

### Requirement: MessageEntity 实体

系统 SHALL 提供 `MessageEntity` 继承 `BaseEntity`，包含 `conversation_id`(UUID, FK)、`sender_id`(UUID)、`content`(TEXT, max 2000)、`read`(BOOLEAN, default false)。索引 `(conversation_id, created_at DESC)`。

#### Scenario: 持久化消息

- **WHEN** 创建一条消息
- **THEN** 数据库正确写入，`read` 默认为 false

---

### Requirement: 查找或创建会话

系统 SHALL 提供 `POST /api/conversations` 端点，需 JWT 认证，接收 `{ recipient_username, content }`，在同一事务中创建会话 + 第一条消息。

#### Scenario: 新会话

- **WHEN** 用户 A 向用户 B（尚无会话）发送消息
- **THEN** 创建新会话 + 第一条消息，返回 HTTP 201 + `{ conversation_id, request_id }`

#### Scenario: 已有会话

- **WHEN** 用户 A 向用户 B（已有会话）发送消息
- **THEN** 复用已有会话 + 追加消息，返回 HTTP 201 + `{ conversation_id, request_id }`

#### Scenario: 给自己发消息

- **WHEN** 用户尝试给自己发消息
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`

#### Scenario: 对方已删除

- **WHEN** recipient 账户 state = deleted
- **THEN** 返回 HTTP 422，`error_code: "user_unavailable"`

#### Scenario: 消息内容为空或超长

- **WHEN** content 为空或超过 2000 字符
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`

---

### Requirement: 会话列表

系统 SHALL 提供 `GET /api/conversations?page=1&size=20` 端点，需 JWT 认证，返回会话列表（按 `last_message_at DESC`）。

#### Scenario: 正常列表

- **WHEN** 用户有 3 个会话
- **THEN** 返回 `{ items: [...3条], total: 3, page: 1, size: 20, request_id }`，每条含 `other_user: { nickname, avatar_url, username, deleted }`、`last_message`（前 50 字）、`unread_count`

#### Scenario: 无会话

- **WHEN** 用户无任何会话
- **THEN** 返回 `{ items: [], total: 0 }`

---

### Requirement: 消息历史

系统 SHALL 提供 `GET /api/conversations/{id}/messages?page=1&size=50` 端点，需 JWT 认证，返回消息列表（按 `created_at DESC`）。

#### Scenario: 正常分页

- **WHEN** 会话有 80 条消息，GET `?page=1&size=50`
- **THEN** 返回最新 50 条消息（前端 reverse 显示）

#### Scenario: 无权访问

- **WHEN** 用户请求不属于自己的会话消息
- **THEN** 返回 HTTP 403

---

### Requirement: 发送消息

系统 SHALL 提供 `POST /api/conversations/{id}/messages` 端点，需 JWT 认证，接收 `{ content }`。

#### Scenario: 发送成功

- **WHEN** 发送一条有效消息
- **THEN** 返回 HTTP 201 + 消息详情，会话 `last_message_at` 更新

#### Scenario: 频率限制

- **WHEN** 用户在该会话中 1 分钟内已发送 20 条
- **THEN** 返回 HTTP 429，`error_code: "rate_limited"`

#### Scenario: 对方已删除

- **WHEN** 对方账户 state = deleted
- **THEN** 返回 HTTP 422，`error_code: "user_unavailable"`

---

### Requirement: 标记会话已读

系统 SHALL 提供 `POST /api/conversations/{id}/mark-read` 端点，需 JWT 认证。

#### Scenario: 标记已读

- **WHEN** 进入对话页，POST 该端点
- **THEN** 该会话中对方发送的所有未读消息标记为 read，返回 HTTP 200

---

### Requirement: 未读消息总数

系统 SHALL 提供 `GET /api/conversations/unread-count` 端点，需 JWT 认证。

#### Scenario: 有未读

- **WHEN** 用户跨多个会话共有 7 条未读消息
- **THEN** 返回 `{ count: 7, request_id }`
