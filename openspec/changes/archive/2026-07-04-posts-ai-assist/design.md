## Context

当前 WanderChina 发帖流程：用户通过 `PostForm` 手动填写标题（text input）、正文（Markdown editor）、标签（TagInput）、封面图 URL、发布状态，提交到 `POST /api/posts`。

后端已有完整的 AI 基础设施：
- `AiConfig` 配置 `ChatClient` bean（DashScope qwen-plus）
- `AiChatService` 提供 SSE 流式对话 + RAG（Chroma 向量检索）
- `spring-ai-alibaba-starter-dashscope` 依赖已就绪
- `SecurityConfig` 已放行 `/api/ai/**`

前端 `PostForm.tsx` 是纯 `"use client"` 组件，当前无任何 AI 相关逻辑。

**约束**：
- 后端 Spring Boot 3.3.5 + Java 17
- 前端 Next.js 16 + React 19 + TypeScript + shadcn/ui + lucide-react
- 测试环境使用 `@MockBean ChatClient` + H2 内存库
- 发帖 AI 辅助是独立功能，不改动现有 `AiChatService` / `PostService`

## Goals / Non-Goals

**Goals:**
- 新增 `POST /api/ai/post-assist` 端点，支持三种 action：生成标题、推荐标签、润色正文
- 同步 JSON 响应（非 SSE），调用耗时可接受（2-5s）
- 需要登录认证（Bearer Token），复用现有 JWT 鉴权链
- 前端 PostForm 新增 AI 辅助按钮，交互清晰（loading → 填充结果）
- prompt 模板可维护、与 `AiConfig.SYSTEM_PROMPT` 风格一致
- 测试覆盖所有 action 的成功/失败/校验场景

**Non-Goals:**
- 不做流式响应（非对话场景，同步即可）
- 不做对话历史持久化（一次性工具调用）
- 不做 AI 辅助封面图生成
- 不做内容审核/敏感词检测
- 不做 AI 写完整帖子（只辅助三个字段）
- 不改动现有 `AiChatService` / `PostService`

## Decisions

### D1: 单端点 + action 参数（非三个独立端点）

**选择**: `POST /api/ai/post-assist` + `action` 字段  
**备选**: 三个独立端点 `/api/ai/generate-title`、`/api/ai/recommend-tags`、`/api/ai/polish`  
**理由**:
- 三种 action 共享相同的认证链、请求结构（content + title?）、错误处理
- 单端点减少路由膨胀，前端只需封装一个 API 函数
- 后续新增 action（如"生成摘要"）只需扩展枚举值，不加新路由

### D2: 同步响应（非 SSE）

**选择**: `ChatClient.prompt().user(prompt).call().content()` 同步调用，返回 JSON  
**备选**: SSE 流式响应  
**理由**:
- 发帖辅助是"工具调用"而非"对话"，用户期望点击后 2-5s 拿到完整结果
- 同步调用代码更简单，无 SseEmitter 生命周期管理
- 标题和标签本身就是短文本，流式无意义

### D3: 认证策略 — 必须登录

**选择**: 复用 `JwtService` + `AuthUtil.requireUserId()`，要求 Bearer Token  
**备选**: 匿名可用  
**理由**:
- 发帖本身需要登录，AI 辅助是发帖流程的延伸
- 防止匿名滥用（LLM 调用有成本）
- 与 `PostController` 认证方式一致

### D4: prompt 模板管理 — 常量类

**选择**: `AiPostAssistService` 内定义 `static final` 常量，按 action 分别定义 system prompt  
**备选**: 抽取到 `AiConfig` 或外部配置  
**理由**:
- prompt 与具体业务逻辑强耦合，放在 Service 内更易维护
- 与 `AiConfig.SYSTEM_PROMPT` 风格一致（static final String 常量）
- 后续如需国际化再考虑配置化

### D5: 前端 AI 按钮禁用策略

**选择**: `content` 为空时，"生成标题"和"润色"按钮 disabled；"推荐标签"按钮需要 `content` 不为空  
**理由**:
- 生成标题和润色都需要内容作为输入，空内容无意义
- 推荐标签也需要内容来理解帖子主题
- 禁用态用 `opacity-50 cursor-not-allowed`，不用 tooltip

### D6: 润色结果直接替换正文

**选择**: 润色结果直接替换 Markdown editor 中的内容  
**备选**: 展示 diff 让用户选择接受/拒绝  
**理由**:
- 最简交互路径，用户可通过 Ctrl+Z 撤销
- diff 视图实现复杂，对 MVP 阶段过度设计
- 前端 state 中可保留原文引用供后续"撤销"按钮使用

## Risks / Trade-offs

- **[风险] DashScope API 延迟 > 5s** → 前端按钮有 loading 状态；后端 ChatClient 默认超时由 Spring AI 管理（通常 30s），用户可重试
- **[风险] 润色结果质量不稳定** → prompt 模板中强调"保持 Markdown 格式、保留核心信息、改善表达"；后续可根据用户反馈迭代 prompt
- **[风险] 推荐标签与平台已有标签不一致** → prompt 中不限制标签来源，由用户自行决定是否采纳 AI 推荐
- **[权衡] 不持久化调用记录** → 简化实现，但无法做用量统计或审计；后续可加 AiPostAssistLog 实体
