## ADDED Requirements

### Requirement: 知识库文档构建（ETL Pipeline）

系统 SHALL 从数据库加载平台结构化数据（City / Spot / Post），将其转换为 Spring AI `Document` 对象。每个 Document 包含文本内容与结构化 metadata。

#### Scenario: 城市实体转为 Document

- **GIVEN** 数据库中存在 CityEntity（name="Beijing", nameZh="北京", description="Ancient capital...", bestSeason="Autumn"）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：text 包含城市名（中英文）、描述、最佳季节
- **AND** metadata 包含 `entity_type=city`, `slug`, `name`, `name_zh`

#### Scenario: 景点实体转为 Document

- **GIVEN** 数据库中存在 SpotEntity（name="Forbidden City", cityName="Beijing", tags=["heritage","history"]）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：text 包含景点名（中英文）、城市名、标签、评分、描述
- **AND** metadata 包含 `entity_type=spot`, `slug`, `city_name`, `tags`, `name`, `name_zh`

#### Scenario: 攻略实体转为 Document（按段落切片）

- **GIVEN** 数据库中存在 PostEntity（content 含多个段落）
- **WHEN** 知识库构建服务执行文档生成且 content 长度 > 1000 字符
- **THEN** 使用 TokenTextSplitter 按 token 边界切分为多个 Document
- **AND** 每个 Document 的 metadata 包含 `entity_type=post`, `slug`, `title`, `tags`

#### Scenario: 仅索引已发布内容

- **GIVEN** 数据库中存在 PostEntity status=DRAFT 或 deleted=true
- **WHEN** 知识库构建服务执行文档生成
- **THEN** DRAFT 状态或已删除的实体不被索引到向量库

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
- **WHEN** 达到定时任务触发时间（默认每 6 小时，cron: `0 0 */6 * * *`）
- **THEN** 执行全量索引重建
- **AND** 重建过程不影响正在进行的 AI 对话

#### Scenario: 重建完成记录日志

- **GIVEN** 重建任务已执行
- **WHEN** 重建完成
- **THEN** 日志记录重建耗时与文档数量
- **AND** 格式如 "Knowledge base rebuilt: 29 documents indexed in 3.2s"

---

### Requirement: 知识库重建 API

`POST /api/ai/knowledge/rebuild` SHALL 触发异步全量知识库重建。

#### Scenario: 触发重建

- **WHEN** 发送 `POST /api/ai/knowledge/rebuild`
- **THEN** HTTP 200
- **AND** 响应体包含 `request_id` 和 `status: "rebuild_started"`
- **AND** 重建在后台异步执行

---

### Requirement: RAG 增强对话（检索增强生成）

当用户发送消息时，系统 SHALL 基于用户消息语义检索知识库，将检索结果注入 LLM 上下文。

#### Scenario: 用户提问触发知识检索

- **GIVEN** 用户发送消息 "What are the best spots in Beijing?"
- **WHEN** AiChatService 处理该消息
- **THEN** 系统将用户消息向量化并在 Chroma 中执行 similarity search
- **AND** 返回 Top-K（K=5）最相关 Document
- **AND** 将检索到的 Document 文本作为 context 注入 LLM prompt

#### Scenario: 检索结果通过 metadata 过滤

- **GIVEN** 用户消息包含明确城市名 "Hangzhou"
- **WHEN** 执行 similarity search
- **THEN** 使用 Spring AI FilterExpression 对 metadata 做过滤
- **AND** 检索结果优先返回 city_name=Hangzhou 的 Document

#### Scenario: 增强 Prompt 结构

- **WHEN** 构造 LLM 请求
- **THEN** prompt 结构为：[System Prompt] + [Context: 检索到的知识库片段] + [History: 最近 10 轮对话] + [User Message: 当前消息]

#### Scenario: 无相关知识检索结果

- **GIVEN** 用户提问与平台数据无关
- **WHEN** similarity search 返回结果相似度均低于阈值（threshold=0.3）
- **THEN** LLM 仍正常回答，但 prompt 中不含额外 context
- **AND** 降级为当前行为（基于通用知识回答）

---

### Requirement: AI 回答引用来源

当 AI 基于平台知识回答时，SHALL 在回答中标注信息来源。

#### Scenario: 内联来源标注

- **GIVEN** 检索到相关 Document（如 Forbidden City spot）
- **WHEN** LLM 生成回答
- **THEN** 回答中包含内联标注，如 "(Source: Forbidden City, Beijing)"

#### Scenario: References 区块

- **GIVEN** LLM 回答使用了多个平台知识来源
- **WHEN** 回答生成完毕
- **THEN** 回答末尾附 "References" 区块
- **AND** 列出引用的平台内容标题与简要描述

---

### Requirement: Embedding 模型配置

系统 SHALL 使用 DashScope text-embedding-v3 模型生成文档与查询的向量表示。

#### Scenario: EmbeddingModel Bean 自动配置

- **GIVEN** `spring-ai-alibaba-starter-dashscope` 依赖已引入
- **GIVEN** `spring.ai.dashscope.api-key` 已配置
- **WHEN** 应用启动
- **THEN** 自动注入 `EmbeddingModel` bean（DashScope 实现）
- **AND** 默认使用 text-embedding-v3 模型

#### Scenario: 测试环境禁用 Embedding

- **GIVEN** 测试环境 `spring.ai.model.chat=none`
- **WHEN** 测试上下文加载
- **THEN** 使用 mock EmbeddingModel 返回固定维度向量
- **AND** 不发起真实 DashScope API 调用

---

### Requirement: Chroma 向量库配置

系统 SHALL 使用 Chroma 作为向量存储，通过 Spring AI auto-configuration 集成。

#### Scenario: 开发环境连接本地 Chroma

- **GIVEN** 本地运行 Chroma Docker 容器（`docker run -p 8000:8000 ghcr.io/chroma-core/chroma:1.0.0`）
- **GIVEN** application.yml 配置 `spring.ai.vectorstore.chroma.client.host=http://localhost`
- **WHEN** 应用启动
- **THEN** 自动创建 collection（`initialize-schema=true`）
- **AND** collection name 默认 "wanderchina-knowledge"

#### Scenario: 测试环境使用 SimpleVectorStore 替代

- **GIVEN** 测试环境 `spring.ai.model.chat=none`
- **WHEN** 测试上下文加载
- **THEN** 使用内存 `SimpleVectorStore` 替代 Chroma
- **AND** 测试不依赖外部 Chroma 实例
