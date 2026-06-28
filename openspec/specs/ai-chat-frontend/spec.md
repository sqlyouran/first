## ADDED Requirements

### Requirement: AiChatPanel 渲染聊天界面

`AiChatPanel` SHALL 是一个 `"use client"` 组件，包含消息列表区和输入区。消息列表区在空状态时显示引导文案，有消息时显示对话气泡。输入区包含文本输入框和发送按钮。

#### Scenario: 空状态显示引导文案

- **WHEN** RTL 渲染 `<AiChatPanel />` 且 messages 为空
- **THEN** 显示引导文案（包含 "Ask me" 或 "traveling" 文本）
- **AND** 输入框可见且未 disabled

#### Scenario: 用户消息右对齐蓝色气泡

- **GIVEN** store 中有一条 role=USER 的消息
- **WHEN** 渲染 `<AiChatPanel />`
- **THEN** 消息气泡文本匹配
- **AND** 气泡样式含 `bg-blue-700` 或 `text-white`

#### Scenario: AI 回复左对齐灰色气泡

- **GIVEN** store 中有一条 role=ASSISTANT 的消息
- **WHEN** 渲染 `<AiChatPanel />`
- **THEN** 消息气泡文本匹配
- **AND** 气泡样式含 `bg-slate-100` 或 `bg-slate-200`

#### Scenario: 发送按钮在 streaming 时 disabled

- **GIVEN** `isStreaming` 为 true
- **WHEN** 渲染 `<AiChatPanel />`
- **THEN** 发送按钮 disabled
- **AND** 按钮内含 Loader2 旋转图标（SVG）

#### Scenario: Enter 键发送消息

- **GIVEN** 输入框有文本 "hello"
- **WHEN** 按下 Enter 键（非 Shift+Enter）
- **THEN** 调用 store 的 `sendMessage`
- **AND** 输入框清空

### Requirement: SSE 流式消费函数

`lib/api/aiChat.ts` SHALL 导出 `streamChat` 函数，使用原生 fetch + ReadableStream 消费后端 SSE 端点。

#### Scenario: streamChat 调用 POST /api/ai/chat

- **WHEN** 调用 `streamChat(conversationId, "hello", onToken, onDone, onError)`
- **THEN** 发起 `fetch` 请求到 `/api/ai/chat`
- **AND** method 为 POST
- **AND** body 为 `{ "conversation_id": conversationId, "message": "hello" }`

#### Scenario: onToken 回调逐 chunk 触发

- **GIVEN** SSE 流返回 `event: token\ndata: 你\n\nevent: token\ndata: 好\n\nevent: done\ndata: \n\n`
- **WHEN** streamChat 消费该流
- **THEN** `onToken("你")` 被调用
- **AND** `onToken("好")` 被调用
- **AND** `onDone()` 被调用

#### Scenario: onDone 回调在流结束时触发

- **GIVEN** SSE 流正常结束（`event: done`）
- **WHEN** 消费到 done 事件
- **THEN** `onDone()` 被调用

#### Scenario: onError 回调在网络错误时触发

- **GIVEN** fetch 抛出网络异常
- **WHEN** streamChat 捕获异常
- **THEN** `onError(errorMessage)` 被调用

### Requirement: Zustand store 管理对话状态

`lib/stores/aiChat.ts` SHALL 导出 `useAiChatStore`，包含 messages、conversationId、isStreaming、error 状态，以及 createConversation、sendMessage、reset actions。

#### Scenario: 初始状态

- **WHEN** 首次访问 `useAiChatStore.getState()`
- **THEN** `conversationId` 为 null
- **AND** `messages` 为空数组
- **AND** `isStreaming` 为 false
- **AND** `error` 为 null

#### Scenario: sendMessage 追加用户消息并触发流式接收

- **GIVEN** conversationId 已设置
- **WHEN** 调用 `sendMessage("hello")`
- **THEN** messages 末尾追加 `{ role: "user", content: "hello" }`
- **AND** `isStreaming` 变为 true
- **AND** 流式 token 到达后追加到 assistant 消息

#### Scenario: sendMessage 完成后 isStreaming 为 false

- **GIVEN** SSE 流完成（onDone 触发）
- **WHEN** 检查 store 状态
- **THEN** `isStreaming` 为 false

#### Scenario: reset 清空所有状态

- **WHEN** 调用 `reset()`
- **THEN** `conversationId` 为 null, `messages` 为空, `isStreaming` 为 false, `error` 为 null

### Requirement: 创建会话 API 函数

`lib/api/aiChat.ts` SHALL 导出 `createConversation` 函数，调用 `POST /api/ai/conversations` 并返回 conversationId。

#### Scenario: createConversation 返回会话 ID

- **WHEN** 调用 `createConversation()`
- **THEN** 发起 `POST /api/ai/conversations`
- **AND** 返回 `{ id: "uuid-string" }`
