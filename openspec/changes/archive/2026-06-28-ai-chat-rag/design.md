## Context

当前 AI 智能助手架构：
- `AiChatController` → `AiChatService` → `ChatClient` → DashScope (qwen-plus)
- 对话上下文通过滑动窗口（最近 10 轮）构建
- System Prompt 为静态旅行助手角色描述
- 平台已有结构化数据：8 城市、15 景点、7 篇攻略（种子数据），含丰富的 description/tags/cityName 等文本字段

**约束**：
- 后端 Spring Boot 3.3.5 + Java 17，Spring AI 1.0.0 BOM 已引入
- DashScope API Key 已配置（`.env` 中 `DASHSCOPE_API_KEY`）
- 测试环境使用 H2 内存库 + mock ChatClient，不能依赖外部服务

## Goals / Non-Goals

**Goals:**
- 用户提问时，AI 能基于平台真实数据（城市/景点/攻略）回答
- AI 回答中标注信息来源，增强可信度
- 知识库支持定时同步，数据变更后自动更新
- 测试环境与生产环境隔离，测试不依赖 Chroma/DashScope Embedding API

**Non-Goals:**
- 不做 Function Calling / Tool Calling（后续迭代）
- 不做多知识库隔离（按用户/语言分库）
- 不做知识库管理 UI（上传/删除文档）
- 不做增量同步（事件驱动实时更新）
- 前端不做改动（RAG 对前端透明）

## Decisions

### 1. 向量数据库：Chroma

| 候选 | 评估 |
|---|---|
| PgVector | 需额外 PG 实例，项目用 MySQL |
| Redis Stack | 已有 Redis，但向量检索非核心功能，引入 Redis Stack 增加运维复杂度 |
| SimpleVectorStore（内存） | 零依赖，但重启丢失，仅适合测试 |
| **Chroma** | 开源专用向量库，Spring AI 原生支持，Docker 一行启动 |

**选择**：Chroma — 专用向量数据库，API 清晰，Spring AI auto-configuration 开箱即用，Docker 部署简单。

**开发环境**：`docker run -p 8000:8000 ghcr.io/chroma-core/chroma:1.0.0`
**配置**：`spring.ai.vectorstore.chroma.client.host=http://localhost:8000`

---

### 2. Embedding 模型：DashScope text-embedding-v3

已有 `spring-ai-alibaba-starter-dashscope` 依赖，自动提供 `EmbeddingModel` bean。text-embedding-v3 支持中英双语，1024 维，适合平台双语内容。

**配置**：`spring.ai.dashscope.embedding.options.model=text-embedding-v3`

**测试隔离**：测试环境 `spring.ai.model.chat=none` 时，创建 mock `EmbeddingModel` bean，返回固定维度向量（避免真实 API 调用）。

---

### 3. 文档构建策略（ETL）

```
┌─────────────────────────────────────────────────┐
│           Knowledge Builder Service             │
├─────────────────────────────────────────────────┤
│                                                 │
│  CityRepository.findAll() ──▶ Document          │
│    text: "City: {name} ({nameZh})\n..."         │
│    meta: {entity_type, slug, name, name_zh}     │
│                                                 │
│  SpotRepository.findByStatusAndDeletedFalse()   │
│    ──▶ Document                                 │
│    text: "Spot: {name} ({nameZh})\nCity: ..."   │
│    meta: {entity_type, slug, city_name, tags}   │
│                                                 │
│  PostRepository.findByStatusAndDeletedFalse()   │
│    ──▶ Document(s)                              │
│    若 content > 1000 字符：TokenTextSplitter     │
│    meta: {entity_type, slug, title, tags}       │
│                                                 │
└─────────────────────────────────────────────────┘
```

- **City/Spot**：一个实体 = 一个 Document（内容短，无需切片）
- **Post**：超长内容用 Spring AI 的 `TokenTextSplitter` 切片（maxChunkSize=800 token, overlap=100）
- **过滤**：仅索引 `status=PUBLISHED` 且 `deleted=false` 的实体

---

### 4. 同步策略：定时全量重建

```
触发时机：
  1. ApplicationReadyEvent → 启动时全量构建
  2. @Scheduled(cron="0 0 */6 * * *") → 每 6 小时
  3. POST /api/ai/knowledge/rebuild → 手动触发

重建流程：
  1. 从 DB 加载全部活跃实体
  2. 生成 Document 列表
  3. 清空 Chroma collection（delete + recreate）
  4. 批量写入新 Document
  5. 记录日志："Knowledge base rebuilt: N documents indexed in X.Xs"
```

**全量 vs 增量**：种子数据量小（~30 Document），全量重建耗时 < 5 秒，无需复杂增量机制。

---

### 5. RAG 检索流程

```
用户消息: "北京有什么好玩"
         │
         ▼
┌────────────────────────┐
│ 1. 用户消息 → Embedding│
│    (text-embedding-v3) │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ 2. Chroma similarity   │
│    search + filter     │
│    Top-K=5             │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ 3. 构造增强 Prompt     │
│    System + Context    │
│    + History + User    │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ 4. ChatClient stream   │
│    → SSE               │
└────────────────────────┘
```

**Metadata 过滤**：当用户消息中检测到城市名关键词时，使用 Spring AI `FilterExpression` 过滤 `city_name` 元数据，缩小检索范围。若无明确城市意图，全库语义检索。

**相似度阈值**：0.3（低于此阈值的结果不注入 prompt，降级为通用回答）。

---

### 6. 来源引用格式

System Prompt 追加指令：

```
When answering based on platform knowledge, cite sources inline using (Source: {name}, {city}) format.
At the end of your response, add a "References" section listing the sources used:

References:
- {Spot/Post/City name} — {brief description}
```

---

### 7. 测试隔离

| 环境 | VectorStore | EmbeddingModel |
|---|---|---|
| 开发 | Chroma (Docker) | DashScope (真实 API) |
| 测试 | SimpleVectorStore（内存） | mock EmbeddingModel（固定维度） |

通过 `@ConditionalOnProperty` 区分：
- `spring.ai.vectorstore.chroma.client.host` 存在 → ChromaVectorStore
- `spring.ai.model.chat=none` → SimpleVectorStore + mock EmbeddingModel

## Risks / Trade-offs

| 风险 | 缓解措施 |
|---|---|
| Chroma 不可用导致启动失败 | 配置 fallback 到 SimpleVectorStore，开发环境 Chroma 容器化部署 |
| DashScope Embedding API 调用成本 | 仅在重建时调用（~30 次/6h），成本可忽略 |
| 全量重建期间检索结果不一致 | 重建为原子操作（先清空再写入），重建过程 < 5s |
| Post 切片导致语义断裂 | TokenTextSplitter 按 token 边界切片，保留 overlap 上下文 |
| 测试环境缺少真实 Embedding | 测试聚焦 ETL 逻辑 + 检索流程集成，不验证语义质量 |

## Open Questions

1. **metadata 过滤的意图识别**：用规则（正则匹配城市名）还是 LLM 提取？当前设计倾向规则匹配，简单高效。
2. **Chroma 持久化**：开发环境 Docker 容器重启后数据丢失，是否需要挂载 volume？
3. **生产部署**：Chroma Cloud vs 自托管 Docker？
