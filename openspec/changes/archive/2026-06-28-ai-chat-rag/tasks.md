## 1. 依赖与配置

- [x] 1.1 pom.xml 新增 `spring-ai-starter-vector-store-chroma` 依赖
- [x] 1.2 application.yml 新增 Chroma 向量库配置（host/port/collection-name/initialize-schema）
- [x] 1.3 application.yml 新增 DashScope Embedding 配置（model=text-embedding-v3）
- [x] 1.4 application.yml 新增 app.rag 配置节（top-k / similarity-threshold / rebuild-cron / max-chunk-size / chunk-overlap）
- [x] 1.5 test/resources/application.yml 禁用 Chroma 自动配置（避免测试依赖外部服务）

## 2. 测试基础设施

- [x] 2.1 创建 `config/TestRagConfig.java`：提供 mock EmbeddingModel bean（返回固定维度向量）
- [x] 2.2 创建 `config/TestRagConfig.java`：提供 SimpleVectorStore bean 替代 Chroma
- [x] 2.3 验证现有测试通过（318 个测试全绿）

## 3. ETL — 知识库构建

- [x] 3.1 创建 `service/KnowledgeBuilderService.java`：注入 CityRepository / SpotRepository / PostRepository / VectorStore
- [x] 3.2 实现 `buildCityDocuments()`：CityEntity → Document（text 含城市名/描述/最佳季节，metadata 含 entity_type/slug/name/name_zh）
- [x] 3.3 实现 `buildSpotDocuments()`：SpotEntity → Document（text 含景点名/城市/标签/评分/描述，metadata 含 entity_type/slug/city_name/tags/name/name_zh）
- [x] 3.4 实现 `buildPostDocuments()`：PostEntity → Document(s)（长文用 TokenTextSplitter 切片，metadata 含 entity_type/slug/title/tags）
- [x] 3.5 实现 `rebuildAll()`：构建全部 Document → 批量写入 → 记录日志
- [x] 3.6 编写 `KnowledgeBuilderServiceTest`：验证 City/Spot/Post 文档生成逻辑（RED→GREEN）
- [x] 3.7 编写测试：验证仅索引 PUBLISHED 且未删除的实体

## 4. 知识检索服务

- [x] 4.1 创建 `service/KnowledgeSearchService.java`：注入 VectorStore + 配置参数
- [x] 4.2 实现 `search(query)`：语义检索，返回 Document 列表
- [x] 4.3 实现 `search(query, cityName)`：带 metadata filter 的检索（FilterExpression: city_name == cityName）
- [x] 4.4 实现相似度阈值过滤：丢弃 score < threshold 的结果
- [x] 4.5 编写 `KnowledgeSearchServiceTest`：验证检索逻辑（使用 SimpleVectorStore + mock EmbeddingModel）

## 5. RAG 增强对话

- [x] 5.1 修改 `AiChatService`：注入 KnowledgeSearchService
- [x] 5.2 修改 `sendMessage()`：在构建 context 前调用 knowledgeSearch.search()
- [x] 5.3 修改 `buildContextMessages()`：将检索到的 Document 文本注入 System Message
- [x] 5.4 更新 `AiConfig.SYSTEM_PROMPT`：追加引用来源指令（内联 Source 标注 + References 区块）
- [x] 5.5 编写 `AiChatServiceRagTest`：验证 RAG 检索结果被注入 prompt（RED→GREEN）
- [x] 5.6 编写测试：验证无检索结果时不注入 context

## 6. 知识库重建 API

- [x] 6.1 创建 `dto/response/KnowledgeRebuildResponse.java`：继承 BaseResponse，含 status 字段
- [x] 6.2 创建 `controller/KnowledgeController.java`：`POST /api/ai/knowledge/rebuild` → 异步触发 rebuildAll()
- [x] 6.3 SecurityConfig 已覆盖 `/api/ai/**` 无需修改
- [x] 6.4 编写 `KnowledgeControllerTest`：验证 API 返回 200 + status=rebuild_started（RED→GREEN）

## 7. 定时同步

- [x] 7.1 在 `AppApplication` 添加 `@EnableScheduling` + `@EnableAsync`
- [x] 7.2 创建 `KnowledgeIndexScheduler.java`：`@Scheduled(cron)` 触发 rebuildAll()
- [x] 7.3 添加 `ApplicationReadyEvent` 监听器：启动时触发首次构建
- [x] 7.4 编写 `KnowledgeIndexSchedulerTest`：验证定时任务触发（使用 mock）

## 8. 集成验证

- [ ] 8.1 启动 Chroma Docker 容器（需手动操作）
- [ ] 8.2 启动后端服务，验证知识库构建日志（需手动操作）
- [ ] 8.3 发送 AI 对话请求，验证回答包含平台数据引用（需手动操作）
- [x] 8.4 全量测试通过：336 个测试全绿（原 318 + 新增 18）
