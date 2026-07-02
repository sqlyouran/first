## Why

当前 AI 智能助手仅依赖硬编码的 system prompt 回答问题，无法基于平台真实数据（城市、景点、攻略）提供精准推荐。用户提问"北京有什么好玩"时，AI 只能凭通用知识泛泛而谈，而非引用平台上的真实景点和攻略。RAG（检索增强生成）能让 AI 基于平台数据库的结构化内容回答，提升回答准确性、可信度和平台粘性。

## What Changes

- 新增知识库构建管道：将 City/Spot/Post 实体转为 Spring AI `Document`，写入 Chroma 向量库
- 新增 Embedding 集成：复用 DashScope API 的 text-embedding-v3 模型（中英双语，1024 维）
- 新增 Chroma 向量库：通过 Docker 运行本地实例，Spring AI auto-configuration 集成
- 新增知识库定时同步：启动时全量构建 + 每 6 小时 cron 重建 + 手动触发 API
- 增强 AI 对话流程：用户消息触发语义检索 → Top-5 相关文档注入 prompt → LLM 基于真实数据生成
- 新增来源引用：AI 回答中标注信息来源（内联 Source 标注 + 末尾 References 区块）
- 新增 metadata 过滤：按城市名、标签等结构化字段缩小检索范围
- 前端零改动（RAG 对前端完全透明，SSE 协议不变）

## Capabilities

### New Capabilities

- `ai-chat-rag`: AI 智能助手 RAG 知识库能力——文档构建（ETL）、Chroma 向量存储、语义检索、metadata 过滤、来源引用、定时同步

### Modified Capabilities

- `ai-chat-backend`: AiChatService 的 `sendMessage()` 方法新增 RAG 检索步骤，将检索到的知识库文档注入 LLM prompt 上下文；system prompt 更新为包含引用来源指令

## Impact

- **后端依赖**：新增 `spring-ai-starter-vector-store-chroma`（由 spring-ai-bom 管理版本）
- **外部服务**：新增 Chroma Docker 容器（开发环境 `localhost:8000`）
- **配置**：`application.yml` 新增 Chroma 连接配置 + RAG 参数（top-k / threshold / cron）
- **API**：新增 `POST /api/ai/knowledge/rebuild` 管理端点
- **数据库**：不新增表，复用现有 City/Spot/Post Repository
- **测试**：测试环境使用 SimpleVectorStore + mock EmbeddingModel 替代 Chroma/DashScope
- **前端**：无影响
