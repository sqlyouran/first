## MODIFIED Requirements

### Requirement: 发送消息并 SSE 流式返回 AI 回复

`AiChatService.sendMessage()` SHALL 支持在流式调用中携带 Function Calling 工具，使 LLM 能在对话过程中自动调用景点查询函数并将结果融入回答。

现有行为不变：
- 用户消息持久化到 DB
- 对话上下文滑动窗口（最近 10 轮）
- RAG 知识检索注入上下文
- SSE 事件流：`token` → `token` → ... → `done`

新增行为：
- `ChatClient.prompt()` 调用链自动包含已注册的 `ToolCallbackProvider` 工具
- 当 LLM 决定调用工具时，Spring AI 框架自动执行函数、将结果注入对话、然后继续流式输出最终回答
- 对前端 SSE 消费完全透明（前端无需感知 Function Calling 发生）

#### Scenario: 普通对话（无工具调用）

- **GIVEN** 用户发送不涉及景点查询的消息
- **WHEN** `AiChatService.sendMessage()` 处理消息
- **THEN** 行为与现有实现一致：RAG 检索 + 流式输出
- **AND** 工具注册不影响普通对话的 SSE 事件流

#### Scenario: 触发 Function Calling 的对话

- **GIVEN** 用户发送涉及景点查询的消息（如"杭州有哪些景点"）
- **WHEN** `AiChatService.sendMessage()` 处理消息
- **THEN** LLM 识别意图并调用 `searchSpotsByCity("Hangzhou")`
- **AND** Spring AI 自动执行函数并将结果注入对话上下文
- **AND** LLM 基于函数返回的景点数据生成回答
- **AND** 回答通过 SSE `token` 事件流式推送给前端
- **AND** 最终 SSE `done` 事件触发，完整回答持久化到 DB

---

### Requirement: AI 聊天接口匿名限流

`AiChatController` 的 `/api/ai/chat` 和 `/api/ai/conversations` 接口 SHALL 实施匿名限流：未登录用户每 IP 每天最多 20 次调用，已登录用户不限流（由 `AuthUtil.optionalUserId` 判断）。

#### Scenario: 匿名用户超过每日限额

- **GIVEN** 未登录用户从 IP `1.2.3.4` 当天已调用 20 次 `/api/ai/chat`
- **WHEN** 该用户再次请求 `/api/ai/chat`
- **THEN** HTTP 429，响应 `error_code: "rate_limited"`

#### Scenario: 已登录用户不受匿名限流限制

- **GIVEN** 已登录用户从同一 IP 当天已调用 25 次 `/api/ai/chat`
- **WHEN** 该用户请求 `/api/ai/chat`（携带有效 Token）
- **THEN** 正常处理，不触发限流

#### Scenario: 新 IP 首次调用

- **GIVEN** IP `5.6.7.8` 当天未调用过 AI 接口
- **WHEN** 请求 `/api/ai/chat`
- **THEN** 正常处理
