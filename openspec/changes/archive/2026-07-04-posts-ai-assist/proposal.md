## Why

WanderChina 发帖流程目前完全依赖用户手动填写标题、正文、标签，创作门槛高且效率低。平台已集成 Spring AI + DashScope（用于 AI 聊天助手），可复用同一 LLM 基础设施为创作环节提供即时辅助——生成吸引人的标题、推荐相关标签、润色 Markdown 正文，降低内容创作摩擦、提升帖子质量。

## What Changes

- 新增后端端点 `POST /api/ai/post-assist`，支持三种 AI 辅助 action：`generate_title`（生成标题）、`recommend_tags`（推荐标签）、`polish`（润色正文）
- 新增 `AiPostAssistController` + `AiPostAssistService`，同步 JSON 响应（非 SSE），需要登录认证
- 新增 prompt 模板常量，按 action 组装不同 system prompt + user prompt
- 前端 `PostForm` 增加三个 AI 辅助按钮（标题旁 / 正文旁 / 标签旁），点击后 loading → 结果直接填充到表单字段
- 新增 `lib/api/aiPostAssist.ts` 封装 API 调用
- 不改动现有 `/api/posts` CRUD 端点，不改动 `AiChatService`

## Capabilities

### New Capabilities
- `posts-ai-assist`: 发帖 AI 辅助端点及前端交互——生成标题、推荐标签、润色正文

### Modified Capabilities

无。本次变更不修改现有 spec 的需求行为。

## Impact

- **后端**：新增 `controller/AiPostAssistController`、`service/AiPostAssistService`、`dto/AiPostAssistRequest`、`dto/response/AiPostAssistResponse`、`exception/AiPostAssistException`；更新 `SecurityConfig` 允许 `/api/ai/post-assist`（已登录用户）
- **前端**：修改 `app/posts/_components/PostForm.tsx`（新增按钮 + loading 状态）；新增 `lib/api/aiPostAssist.ts`
- **依赖**：复用现有 `spring-ai-alibaba-starter-dashscope`（ChatClient），无需新增 Maven 依赖
- **API**：新增 `POST /api/ai/post-assist`（需认证），不影响现有端点
