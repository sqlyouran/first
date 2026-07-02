## MODIFIED Requirements

### Requirement: 发送消息并流式返回 AI 回复

`POST /api/ai/chat` SHALL 接收用户消息、持久化到 DB、**执行 RAG 知识检索**、组装上下文窗口（含检索结果）、调用 LLM 流式生成、通过 SSE 逐 token 推送 AI 回复，完成后持久化 assistant 消息。

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

#### Scenario: RAG 知识检索注入上下文

- **GIVEN** 用户消息 "北京有什么好玩"
- **WHEN** AiChatService 处理该消息
- **THEN** 系统执行知识库语义检索，获取 Top-5 相关 Document
- **AND** 检索结果作为 System Message 的一部分注入 LLM prompt
- **AND** LLM 收到的 prompt 包含：System Prompt + Knowledge Context + 对话历史 + 当前消息

#### Scenario: 检索结果低于阈值时不注入

- **GIVEN** 用户消息与平台数据无关（相似度均 < 0.3）
- **WHEN** AiChatService 处理该消息
- **THEN** 知识库检索结果不注入 prompt
- **AND** LLM 仅基于 System Prompt + 对话历史 + 当前消息回答

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
