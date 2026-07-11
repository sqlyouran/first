# ai-chat-rag — AI 智能助手 RAG 知识库能力

## ADDED Requirements

### Requirement: 知识库文档构建（ETL Pipeline）

系统 SHALL 在启动时从数据库全量加载平台结构化数据（City / Spot / Post），将其转换为 Spring AI `Document` 对象并写入 Chroma 向量库。每个 Document 包含文本内容与结构化 metadata。

#### Scenario: 城市实体转为 Document

- **GIVEN** 数据库中存在 CityEntity（name="Beijing", nameZh="北京", description="Ancient capital...", bestSeason="Autumn"）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：
  - text = "City: Beijing (北京)\nDescription: Ancient capital with imperial grandeur\nBest Season: Autumn"
  - metadata = `{ "entity_type": "city", "slug": "beijing", "name": "Beijing", "name_zh": "北京" }`

#### Scenario: 景点实体转为 Document（含实用信息字段）

- **GIVEN** 数据库中存在 SpotEntity（name="Forbidden City", cityName="Beijing", tags=["heritage","history"], description="...", rating=4.8, ticketPrice="旺季60元/淡季40元", openingHours="08:30-17:00", address="北京市东城区景山前街4号"）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：
  - text = "Spot: Forbidden City (故宫)\nCity: Beijing\nTags: heritage, history\nRating: 4.8\nTicket Price: 旺季60元/淡季40元\nOpening Hours: 08:30-17:00\nAddress: 北京市东城区景山前街4号\nDescription: The world's largest palace complex with 600 years of imperial history"
  - metadata = `{ "entity_type": "spot", "slug": "forbidden-city", "city_name": "Beijing", "tags": "heritage,history", "name": "Forbidden City", "name_zh": "故宫" }`
- **AND** 当 ticketPrice / openingHours / address 为 null 时，对应行 SHALL 被省略（不输出 "Ticket Price: null"）

#### Scenario: 攻略实体转为 Document（按段落切片）

- **GIVEN** 数据库中存在 PostEntity（title="A Week in Beijing", content 含多个段落，tags=["beijing","heritage"]）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 若 content 长度 ≤ 1000 字符：生成一个 Document
- **AND** 若 content 长度 > 1000 字符：按段落切分为多个 Document，每个 ≤ 800 token，overlap 约 100 token
- **AND** 每个 Document 的 metadata = `{ "entity_type": "post", "slug": "a-week-in-beijing", "title": "A Week in Beijing", "tags": "beijing,heritage" }`

#### Scenario: 仅索引已发布内容

- **GIVEN** 数据库中存在 PostEntity status=DRAFT
- **WHEN** 知识库构建服务执行文档生成
- **THEN** DRAFT 状态的 Post 不被索引到向量库
- **AND** status=DELETED 的实体（逻辑删除）同样不被索引

---

### Requirement: 定时全量重建知识库

系统 SHALL 通过定时任务全量重建向量库索引，保持知识库与数据库一致。

#### Scenario: 应用启动时构建索引

- **GIVEN** 应用启动完成（ApplicationReadyEvent）
- **WHEN** Chroma 向量库可用
- **THEN** 自动执行一次全量索引构建
- **AND** 先清空旧 collection 数据，再写入新数据

#### Scenario: 定时任务触发重建

- **GIVEN** 应用正在运行
- **WHEN** 达到定时任务触发时间（默认每 6 小时）
- **THEN** 执行全量索引重建
- **AND** 重建过程不影响正在进行的 AI 对话

#### Scenario: 手动触发重建（管理 API）

- **GIVEN** 应用正在运行
- **WHEN** 发送 `POST /api/ai/knowledge/rebuild`
- **THEN** HTTP 200
- **AND** 触发异步全量重建
- **AND** 响应 body 包含 `request_id` 和 `status: "rebuild_started"`

---

### Requirement: RAG 增强对话（检索增强生成）

当用户发送消息时，系统 SHALL 基于用户消息语义检索知识库，将检索结果注入 LLM 上下文，使 AI 基于平台真实数据回答。

#### Scenario: 用户提问触发知识检索

- **GIVEN** 用户发送消息 "What are the best spots in Beijing?"
- **WHEN** AiChatService 处理该消息
- **THEN** 系统将用户消息向量化并在 Chroma 中执行 similarity search
- **AND** 返回 Top-K（K=5）最相关 Document
- **AND** 将检索到的 Document 文本作为 context 注入 LLM prompt

#### Scenario: 检索结果通过 metadata 过滤

- **GIVEN** 用户消息包含明确城市名 "Hangzhou"
- **WHEN** 执行 similarity search
- **THEN** 检索结果优先返回 city_name=Hangzhou 的 Document
- **AND** 使用 Spring AI FilterExpression 对 metadata 做过滤

> **设计说明**：是否做 metadata filter 由 LLM 或规则引擎从用户消息中提取城市意图决定。若无明确城市意图，则全库语义检索。

#### Scenario: 增强 Prompt 结构

- **WHEN** 构造 LLM 请求
- **THEN** prompt 结构为：
  ```
  [System Prompt] — 旅行助手角色 + 引用来源指令
  [Context] — 检索到的知识库片段（最多 5 段，每段带来源标注）
  [History] — 最近 10 轮对话历史
  [User Message] — 当前用户消息
  ```

#### Scenario: AI 回答引用来源

- **GIVEN** 检索到 3 个相关 Document（2 个 spot + 1 个 post）
- **WHEN** LLM 生成回答
- **THEN** System Prompt 指令要求 LLM 在回答中标注信息来源
- **AND** 引用格式为内联标注：如 "(Source: Forbidden City, Beijing)"
- **AND** 回答末尾附 "References" 区块，列出引用的平台内容标题与 slug

#### Scenario: 无相关知识检索结果

- **GIVEN** 用户提问与平台数据无关（如 "How to cook Italian pasta?"）
- **WHEN** similarity search 返回结果相似度均低于阈值（threshold=0.3）
- **THEN** LLM 仍正常回答，但 prompt 中不含额外 context
- **AND** LLM 基于自身通用知识回答（降级为当前行为）

---

### Requirement: Embedding 模型配置

系统 SHALL 使用 DashScope text-embedding-v3 模型生成文档与查询的向量表示。

#### Scenario: EmbeddingModel Bean 自动配置

- **GIVEN** `spring-ai-alibaba-starter-dashscope` 依赖已引入
- **GIVEN** `spring.ai.dashscope.api-key` 已配置（复用现有 DASHSCOPE_API_KEY）
- **WHEN** 应用启动
- **THEN** 自动注入 `EmbeddingModel` bean（DashScope 实现）
- **AND** 默认使用 text-embedding-v3 模型，维度 1024

#### Scenario: 测试环境禁用 Embedding

- **GIVEN** 测试环境 `spring.ai.model.chat=none`
- **WHEN** 测试上下文加载
- **THEN** EmbeddingModel 不发起真实 API 调用
- **AND** 使用 mock EmbeddingModel 返回固定维度向量

---

### Requirement: Chroma 向量库配置

系统 SHALL 使用 Chroma 作为向量存储，通过 Spring AI auto-configuration 集成。

#### Scenario: 开发环境连接本地 Chroma

- **GIVEN** 本地运行 `docker run -p 8000:8000 ghcr.io/chroma-core/chroma:1.0.0`
- **GIVEN** application.yml 配置 `spring.ai.vectorstore.chroma.client.host=http://localhost`
- **WHEN** 应用启动
- **THEN** 自动创建 collection（`initialize-schema=true`）
- **AND** collection name 默认 "wanderchina-knowledge"

#### Scenario: 测试环境使用 SimpleVectorStore 替代

- **GIVEN** 测试环境 `spring.ai.vectorstore.chroma.client.host` 未配置或 Chroma 不可用
- **WHEN** 测试上下文加载
- **THEN** 使用内存 `SimpleVectorStore` 替代 Chroma
- **AND** 测试不依赖外部 Chroma 实例

---

### Requirement: 知识库重建 API

`POST /api/ai/knowledge/rebuild` SHALL 触发异步全量知识库重建。

#### Scenario: 触发重建

- **WHEN** 发送 `POST /api/ai/knowledge/rebuild`
- **THEN** HTTP 200
- **AND** 响应体包含 `request_id` 和 `status: "rebuild_started"`
- **AND** 重建在后台异步执行

#### Scenario: 重建完成日志

- **GIVEN** 重建任务已触发
- **WHEN** 重建完成
- **THEN** 日志记录重建耗时与文档数量
- **AND** 格式如 "Knowledge base rebuilt: 29 documents indexed in 3.2s"

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      RAG-Enhanced AI Chat                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐                                        │
│  │  Knowledge Builder  │ ← 定时/启动/手动触发                     │
│  │  (Service)          │                                        │
│  │                     │                                        │
│  │  CityRepository ──▶ Document (city)                          │
│  │  SpotRepository ──▶ Document (spot)                          │
│  │  PostRepository ──▶ Document (post, chunked)                 │
│  └──────────┬──────────┘                                        │
│             │ write                                             │
│             ▼                                                   │
│  ┌─────────────────────┐     ┌──────────────────────┐           │
│  │  Chroma VectorStore │◀────│  DashScope Embedding │           │
│  │  (localhost:8000)   │     │  text-embedding-v3   │           │
│  └──────────┬──────────┘     └──────────────────────┘           │
│             │ read (similarity search)                          │
│             ▼                                                   │
│  ┌─────────────────────┐                                        │
│  │  AiChatService      │ ← 现有服务，新增 RAG 检索步骤           │
│  │  (RAG-enhanced)     │                                        │
│  │                     │                                        │
│  │  1. 用户消息 → Embedding                                     │
│  │  2. Chroma similarity search (Top-5)                         │
│  │  3. 构建增强 Prompt (System + Context + History + User)      │
│  │  4. ChatClient 流式生成 → SSE                                │
│  └─────────────────────┘                                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

| 决策 | 选型 | 理由 |
|---|---|---|
| 向量数据库 | Chroma (Docker, port 8000) | 用户指定；开源、轻量、Spring AI 原生支持 |
| Embedding 模型 | DashScope text-embedding-v3 | 复用已有 DashScope 依赖；支持中英双语；1024 维 |
| 同步策略 | 定时全量重建（6h 间隔） | 简单可靠；种子数据量小（~30 Document）；无需事件机制 |
| 检索策略 | 语义检索 + metadata filter | 模糊意图走语义；明确城市走 filter 缩小范围 |
| 来源引用 | LLM 内联标注 + References 区块 | 用户要求引用来源；增强回答可信度 |
| 测试隔离 | SimpleVectorStore + mock EmbeddingModel | 测试不依赖 Chroma/DashScope 外部服务 |

## Dependencies to Add

```xml
<!-- Chroma Vector Store (Spring AI 1.0.0) -->
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-starter-vector-store-chroma</artifactId>
</dependency>
```

> DashScope EmbeddingModel 已通过 `spring-ai-alibaba-starter-dashscope` 提供，无需额外依赖。

## Configuration (application.yml additions)

```yaml
spring:
  ai:
    vectorstore:
      chroma:
        client:
          host: ${CHROMA_HOST:http://localhost}
          port: ${CHROMA_PORT:8000}
        collection-name: wanderchina-knowledge
        initialize-schema: true
    dashscope:
      embedding:
        options:
          model: text-embedding-v3

app:
  rag:
    top-k: 5
    similarity-threshold: 0.3
    rebuild-cron: "0 0 */6 * * *"   # 每 6 小时
    max-chunk-size: 800             # Post 切片最大 token 数
    chunk-overlap: 100              # 切片重叠 token 数
```

## New Source Files (estimated)

| 文件 | 职责 |
|---|---|
| `config/RagConfig.java` | Chroma VectorStore bean、EmbeddingModel bean、RAG 参数配置 |
| `service/KnowledgeBuilderService.java` | ETL：从 DB 生成 Document → 写入 VectorStore |
| `service/KnowledgeSearchService.java` | 检索：similarity search + metadata filter |
| `controller/KnowledgeController.java` | `POST /api/ai/knowledge/rebuild` 管理 API |
| `config/TestRagConfig.java` | 测试用 SimpleVectorStore + mock EmbeddingModel |

## Modified Source Files

| 文件 | 变更 |
|---|---|
| `service/AiChatService.java` | `sendMessage()` 中新增 RAG 检索步骤，将 context 注入 prompt |
| `config/AiConfig.java` | System Prompt 增加引用来源指令 |
| `config/SecurityConfig.java` | 允许 `/api/ai/knowledge/**` 端点 |
| `application.yml` | 新增 Chroma + RAG 配置节 |
| `pom.xml` | 新增 `spring-ai-starter-vector-store-chroma` 依赖 |

## Non-Goals

- 不做 Function Calling / Tool Calling（后续增强）
- 不做多知识库隔离（如按用户/按语言分库）
- 不做知识库管理 UI（上传文档、删除文档等）
- 不做增量同步（事件驱动更新）
- 前端不做改动（RAG 对前端透明，SSE 协议不变）

---

### Requirement: SpotQueryTool 景点详情输出

`SpotQueryTool.getSpotDetails()` SHALL 在输出文本中包含实用信息字段（门票价格、开放时间、地址），使 AI 助手能够回答用户的实用信息问题。

#### Scenario: 景点详情包含实用信息

- **GIVEN** 数据库中存在 slug="forbidden-city" 的景点，ticketPrice="旺季60元/淡季40元", openingHours="08:30-17:00", address="北京市东城区景山前街4号"
- **WHEN** 调用 `spotQueryTool.getSpotDetails("forbidden-city")`
- **THEN** 返回文本 SHALL 包含 "Ticket Price: 旺季60元/淡季40元"、"Opening Hours: 08:30-17:00"、"Address: 北京市东城区景山前街4号"

#### Scenario: 景点无实用信息时优雅降级

- **GIVEN** 数据库中存在 slug="some-spot" 的景点，ticketPrice=null, openingHours=null, address=null
- **WHEN** 调用 `spotQueryTool.getSpotDetails("some-spot")`
- **THEN** 返回文本 SHALL 不包含 "Ticket Price" / "Opening Hours" / "Address" 行（避免输出 null）
