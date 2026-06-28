## ADDED Requirements

### Requirement: 创建对话会话

`POST /api/ai/conversations` SHALL 创建一个新的 `AiConversation` 实体并返回会话 ID。该端点无需认证，匿名用户也可创建会话。

#### Scenario: 匿名用户创建会话

- **WHEN** 发送 `POST /api/ai/conversations`（无 Authorization header）
- **THEN** HTTP 201 Created
- **AND** 响应体包含 `request_id`、`id`（UUID）、`created_at`（ISO 8601）

#### Scenario: 已登录用户创建会话

- **WHEN** 发送 `POST /api/ai/conversations`（携带有效 JWT）
- **THEN** HTTP 201 Created
- **AND** 会话实体的 `userId` 字段记录当前用户 ID

### Requirement: 发送消息并流式返回 AI 回复

`POST /api/ai/chat` SHALL 接收用户消息、持久化到 DB、组装上下文窗口、调用 LLM 流式生成、通过 SSE 逐 token 推送 AI 回复，完成后持久化 assistant 消息。

#### Scenario: 发送消息并接收 SSE 流

- **GIVEN** 已存在一个 conversation（ID 为 `conv-id`）
- **WHEN** 发送 `POST /api/ai/chat` body `{ "conversation_id": "conv-id", "message": "推荐北京景点" }`
- **THEN** HTTP 200
- **AND** Content-Type 为 `text/event-stream`
- **AND** SSE 事件流包含多个 `event: token` 事件，每个 data 为非空字符串
- **AND** 最终以 `event: done` 事件结束

#### Scenario: 用户消息被持久化

- **GIVEN** 已存在一个 conversation
- **WHEN** 发送 `POST /api/ai/chat` 包含消息 "hello"
- **THEN** `AiMessage` 表中新增一条记录：role=USER, content="hello"

#### Scenario: AI 回复被持久化

- **GIVEN** SSE 流完成（`event: done` 已发送）
- **WHEN** 查询该 conversation 的 messages
- **THEN** 新增一条 role=ASSISTANT 的消息，content 为完整 AI 回复（所有 token 拼接）

#### Scenario: 多轮对话上下文

- **GIVEN** conversation 中已有 2 轮对话（4 条消息：user→assistant→user→assistant）
- **WHEN** 发送第 3 条用户消息
- **THEN** LLM 收到的 prompt 包含前 2 轮历史 + 当前消息（共 5 条消息上下文）

#### Scenario: 上下文窗口滑动

- **GIVEN** conversation 中已有 15 轮对话（30 条消息），窗口配置为 10 轮
- **WHEN** 发送新消息
- **THEN** LLM 收到的 prompt 仅包含最近 10 轮（20 条消息）+ 当前消息

#### Scenario: conversation_id 不存在

- **WHEN** 发送 `POST /api/ai/chat` 的 `conversation_id` 指向不存在的会话
- **THEN** HTTP 404
- **AND** error_code 为 `not_found`

#### Scenario: message 为空

- **WHEN** 发送 `POST /api/ai/chat` 的 `message` 为空白字符串
- **THEN** HTTP 422
- **AND** error_code 为 `validation_error`

### Requirement: SSE 事件格式

SSE 流 SHALL 使用标准 Server-Sent Events 格式，定义三种事件类型。

#### Scenario: token 事件

- **WHEN** LLM 生成一个 token chunk
- **THEN** 发送 `event: token\ndata: <token文本>\n\n`

#### Scenario: done 事件

- **WHEN** LLM 生成完毕
- **THEN** 发送 `event: done\ndata: \n\n`
- **AND** SseEmitter 关闭连接

#### Scenario: error 事件

- **WHEN** LLM 调用出错（超时、API 异常等）
- **THEN** 发送 `event: error\ndata: <错误描述>\n\n`
- **AND** SseEmitter 关闭连接

### Requirement: AiConversation 实体继承 BaseEntity

`AiConversation` SHALL 继承 `BaseEntity`（UUID 主键、createdAt、updatedAt、deleted），新增 userId（UUID, nullable）、title（String）、lastMessageAt（Instant）。

#### Scenario: 新会话 userId 为 null（匿名）

- **WHEN** 未认证用户创建会话
- **THEN** 实体 `userId` 字段为 null

#### Scenario: 新会话 title 取自首条消息

- **WHEN** 用户发送第一条消息 "Plan a trip to Beijing"
- **THEN** 会话 `title` 为 "Plan a trip to Beijing"（截断至 100 字符）

### Requirement: AiMessage 实体继承 BaseEntity

`AiMessage` SHALL 继承 `BaseEntity`，新增 conversationId（UUID）、role（AiMessageRole 枚举：USER / ASSISTANT）、content（String, @Lob）。

#### Scenario: 消息 role 仅允许 USER 和 ASSISTANT

- **WHEN** 检查 `AiMessageRole` 枚举
- **THEN** 仅包含 `USER` 和 `ASSISTANT` 两个值
- **AND** 使用 `@Enumerated(EnumType.STRING)` 持久化
