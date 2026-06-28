## Why

首页"Plan with AI"按钮当前仅展示 coming soon 占位，无法为用户提供实际的 AI 行程规划能力。需要后端提供 SSE 流式对话接口 + 多轮对话上下文管理，让 AI 助手从占位升级为可用的核心功能。

## What Changes

- 新增 `spring-ai-alibaba-starter`（DashScope）依赖，接入通义千问大模型
- 新增 `AiConversation` 实体：对话会话，匿名可用（userId nullable）
- 新增 `AiMessage` 实体：消息记录，含 role（user/assistant）+ content
- 新增后端 API：
  - `POST /api/ai/conversations` — 创建对话会话，返回 conversationId
  - `POST /api/ai/chat` — 发送消息并 SSE 流式返回 AI 回复
- 新增 `AiChatService`：管理对话上下文窗口（最近 N 轮）、调用 Spring AI ChatClient 流式生成
- 新增 `AiConfig`：配置 ChatClient bean + 系统 prompt（旅行助手角色）
- 对话历史持久化到 DB，前端通过 conversationId 续接会话

## Capabilities

### New Capabilities
- `ai-chat-backend`: AI 智能助手后端服务——SSE 流式对话、多轮上下文管理、对话历史持久化、通义千问集成

### Modified Capabilities
<!-- 无现有 spec 需要修改，homepage-ai-launcher spec 的占位行为不变（前端 change 负责升级 UI） -->

## Impact

- **Backend**: 新增 `AiConversation` + `AiMessage` 实体、`AiChatController` + `AiChatService` + `AiConfig`
- **Database**: 新增 `ai_conversations` + `ai_messages` 表
- **Dependencies**: 新增 `spring-ai-alibaba-starter`（DashScope）、可能需要调整 `spring-ai-bom` 版本
- **Environment**: 需要 `DASHSCOPE_API_KEY` 环境变量
- **API**: 新增 2 个端点，均为匿名可访问（无认证要求）
