## Context

项目已有 Spring AI BOM 1.0.0 + MCP Server 配置，但仅用于暴露旅行服务为 MCP 工具，未集成任何 LLM ChatClient。后端是标准 WebMvc 架构（非 WebFlux），全部 REST 端点均为 JSON 同步响应。

前端 `AiLauncherSlot` 当前渲染 coming soon 占位 Dialog/Sheet，无业务逻辑。本次仅改后端，前端由 `ai-chat-frontend` change 负责。

## Goals / Non-Goals

**Goals:**
- 接入通义千问（DashScope），通过 Spring AI `ChatClient` 统一接口
- 提供 SSE 流式对话端点 `POST /api/ai/chat`，逐 token 推送 AI 回复
- 提供会话创建端点 `POST /api/ai/conversations`
- DB 持久化对话历史（`AiConversation` + `AiMessage`），支持多轮上下文
- 上下文窗口策略：取最近 N 轮（可配置，默认 10 轮 = 20 条消息）
- 匿名可用：不要求认证，userId 可为 null
- TDD 全覆盖

**Non-Goals:**
- 前端 UI（由 `ai-chat-frontend` change 负责）
- Markdown 渲染、对话历史列表、快捷指令
- 用户认证/鉴权（匿名即可）
- WebSocket（SSE 单向推送足够）
- 对话标题自动生成、对话删除/归档
- RAG / 知识库检索增强

## Decisions

### D1: LLM Provider — 通义千问 via spring-ai-alibaba-starter

**选择**: `spring-ai-alibaba-starter`（DashScope）  
**备选**: OpenAI / Ollama / 自定义 HTTP 调用  
**理由**:
- 用户指定通义千问
- Spring AI 官方生态支持，`ChatClient` 接口统一，后续换 provider 只改配置
- 配置项：`spring.ai.dashscope.api-key=${DASHSCOPE_API_KEY}`

### D2: 流式响应 — SseEmitter（非 WebFlux）

**选择**: `SseEmitter`（WebMvc 原生）  
**备选**: 引入 `spring-boot-starter-webflux` + `Flux<String>`  
**理由**:
- 避免 WebMvc/WebFlux 混合的线程模型冲突
- Spring AI `ChatClient.stream()` 返回 `Flux`，通过 `.subscribe()` 桥接到 SseEmitter，约 5 行胶水代码
- 不引入新架构层

### D3: 对话上下文 — DB 持久化 + 滑动窗口

**选择**: MySQL 持久化 + 内存中取最近 N 轮组装 prompt  
**备选**: Redis 缓存 / 无状态（前端传全量历史）  
**理由**:
- 用户下次打开可续聊
- 滑动窗口（默认 10 轮）控制 token 用量
- Redis 缓存可后续优化热会话，当前不需要

### D4: 实体设计

```
AiConversation extends BaseEntity
├── userId: UUID (nullable, 匿名时为 null)
├── title: String (取第一条用户消息截断)
└── lastMessageAt: Instant

AiMessage extends BaseEntity
├── conversationId: UUID (FK → AiConversation)
├── role: AiMessageRole (enum: USER, ASSISTANT)
├── content: String (@Lob, 不限长度)
└── 无额外字段
```

### D5: 端点设计

| 方法 | 路径 | 请求体 | 响应 | 认证 |
|------|------|--------|------|------|
| POST | `/api/ai/conversations` | `{}` (空 body 或无) | `ConversationResponse { id, created_at }` | 无 |
| POST | `/api/ai/chat` | `ChatRequest { conversation_id, message }` | `SseEmitter` (text/event-stream) | 无 |

SSE 事件格式：
- `event: token` / `data: "你好"` — 每个 token chunk
- `event: done` / `data: ""` — 生成完毕
- `event: error` / `data: "错误描述"` — 异常

### D6: System Prompt

硬编码在 `AiConfig` 中，角色定位为 WanderChina 旅行助手：
- 帮助用户规划中国行程
- 回答旅行相关问题（城市、景点、美食、交通）
- 回复使用英文（面向境外用户）

### D7: 测试中 DashScope Mock

测试环境不依赖真实 API，使用 `@MockBean ChatClient` 或配置 `spring.ai.dashscope.api-key=test-key` + Mock 返回。

## Risks / Trade-offs

- **[风险] DashScope API 延迟或不可用** → SseEmitter 设超时（60s），超时后发 error 事件并关闭
- **[风险] Token 用量超限** → 滑动窗口限制上下文大小（默认 10 轮），后续可加 usage tracking
- **[风险] 匿名滥用** → 当前 MVP 不做限流，后续可加 IP-based rate limiting
- **[Trade-off] SseEmitter 桥接 vs 纯 WebFlux** → 牺牲少量胶水代码，换取架构一致性
- **[Trade-off] userId nullable** → 匿名可用降低门槛，但无法追踪匿名用户的对话归属，可接受
