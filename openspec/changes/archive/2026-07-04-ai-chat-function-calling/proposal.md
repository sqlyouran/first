## Why

WanderChina AI 聊天助手当前基于 RAG（Chroma 向量检索）回答旅行问题，但 RAG 检索的是非结构化文本片段，无法提供精确的景点结构化数据（如评分、浏览量、具体位置）。用户在聊天中询问"杭州有哪些景点"时，AI 只能依赖知识库中的攻略文本片段回答，无法像查询数据库一样返回平台实时景点列表。

`ai-chat-rag` 变更的 design.md 明确将 Function Calling 列为 Non-Goals（"后续迭代"）——本次就是那个后续迭代。Spring AI 1.0.0 原生支持 `@Tool` 注解 + `ToolCallbackProvider` 模式，项目已有 `WeatherService` 和 `ExchangeRateService` 使用 `@Tool` 注解（暴露为 MCP Server 工具），只需注册为 ChatClient 的 Function Calling 工具即可让 AI 助手精确查询景点。

## What Changes

- 新增 `SpotQueryTool` 类，使用 Spring AI `@Tool` 注解封装三个景点查询函数：`searchSpotsByCity`（按城市查询景点列表）、`getSpotDetails`（按名称/slug 查询景点详情）、`getTopRatedSpots`（查询评分最高的景点）
- 新增 `ToolCallbackProvider` bean（`SpotToolCallbackProvider`），自动发现 `@Tool` 方法并注册
- 修改 `AiConfig.chatClient()` — 通过 `ChatClient.Builder.defaultTools()` 注入工具
- 修改 `AiChatService.sendMessage()` — 流式调用时携带 tools 上下文（Spring AI 自动处理 function call → 结果回传 → LLM 生成回答）
- 前端无改动（Function Calling 对前端透明）
- 不接入现有 Weather/ExchangeRate 工具（scope 聚焦景点查询）

## Capabilities

### New Capabilities
- `ai-chat-spot-tools`: AI 聊天 Function Calling — 景点查询工具注册与调用

### Modified Capabilities
- `ai-chat-backend`: AI 聊天服务需适配 Function Calling — `AiChatService` 流式调用需兼容 tools 上下文（Spring AI 自动处理，代码改动极小）

## Impact

- **后端**：新增 `service/SpotQueryTool.java`、`config/SpotToolCallbackProvider.java`；修改 `config/AiConfig.java`（注入 tools）；可能微调 `service/AiChatService.java`（stream 调用适配）
- **前端**：无改动
- **依赖**：复用现有 `spring-ai-alibaba-starter-dashscope`（已含 Tool 支持），无需新增 Maven 依赖
- **API**：无新增端点，现有 `POST /api/ai/chat` SSE 行为不变（对前端透明）
- **测试**：新增 `SpotQueryTool` 单元测试；修改 `AiChatServiceTest` mock 适配 tools 上下文；全量测试需通过
