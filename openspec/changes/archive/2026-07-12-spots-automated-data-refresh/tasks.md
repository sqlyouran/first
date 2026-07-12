## 1. SpotEntity 新增 dataRefreshedAt 字段（TDD）

- [x] 1.1 编写 `SpotEntityTest` 新增测试：验证 dataRefreshedAt 可为 NULL 持久化 + 可设置和检索（RED）
- [x] 1.2 编写测试：验证 dataRefreshedAt 不随 viewCount 变化而更新——仅 viewCount++ 后 dataRefreshedAt 不变（RED）
- [x] 1.3 修改 `SpotEntity.java`：新增 dataRefreshedAt（Instant, nullable）字段 + getter/setter（GREEN）
- [x] 1.4 运行 SpotEntityTest 验证绿灯

## 2. SpotRepository 过期查询（TDD）

- [x] 2.1 编写 `SpotRepositoryTest` 新增测试：插入 3 个景点（dataRefreshedAt 分别为 35天前、10天前、2天前），验证 findStaleSpots(7天前cutoff) 返回前 2 个（RED）
- [x] 2.2 编写测试：验证 dataRefreshedAt=NULL 的景点被包含在过期结果中（RED）
- [x] 2.3 编写测试：验证仅返回 PUBLISHED 且 deleted=false 的景点（RED）
- [x] 2.4 修改 `SpotRepository.java`：新增 `findStaleSpots(Instant cutoff)` 查询方法，按优先级排序（>30天 critical 优先，7-30天 normal）（GREEN）
- [x] 2.5 运行 SpotRepositoryTest 验证绿灯

## 3. SpotEnrichmentReport 实体（TDD）

- [x] 3.1 编写 `SpotEnrichmentReportTest`：验证实体持久化（runId, startedAt, completedAt, totalAttempted/Success/Failed, details JSON）（RED）
- [x] 3.2 创建 `entity/SpotEnrichmentReport.java`：继承 BaseEntity，字段如 spec 定义（GREEN）
- [x] 3.3 创建 `repository/SpotEnrichmentReportRepository.java`：findTopByOrderByStartedAtDesc（GREEN）
- [x] 3.4 运行测试验证绿灯

## 4. DTO 定义

- [x] 4.1 创建 `dto/request/EnrichRequest.java`：record 类型，LLM 提取结果结构（nameZh, ticketPrice, openingHours, address, rating, description, descriptionZh）
- [x] 4.2 创建 `dto/response/StaleSpotResponse.java`：id, name, nameZh, slug, cityName, dataRefreshedAt, daysSinceRefresh, priority（"critical"/"normal"）
- [x] 4.3 创建 `dto/response/StaleSpotListResponse.java`：items[], total（继承 BaseResponse）
- [x] 4.4 创建 `dto/response/EnrichmentReportResponse.java`：报告响应 DTO

## 5. MCP Client 配置

- [x] 5.1 修改 `pom.xml`：新增 `spring-ai-starter-mcp-client` 依赖
- [x] 5.2 创建 `config/McpClientConfig.java`：配置 MCP Client 连接 Browser MCP Server（stdio 模式）
- [x] 5.3 修改 `application.yml`：新增 `spring.ai.mcp.client.stdio.connections.browser-use` 配置（command/args）
- [x] 5.4 验证后端启动时能自动拉起 Browser MCP Server 进程 + MCP Client 连接成功
- [x] 5.5 编写集成测试：验证 MCP Client 能调用 navigate_page / take_snapshot（或 mock 测试）

## 6. SpotEnrichmentService 数据刷新（TDD）

- [x] 6.1 编写 `SpotEnrichmentServiceTest`：updateSpot 成功更新景点采集字段 + 设置 dataRefreshedAt（RED）
- [x] 6.2 编写测试：null 字段不覆盖已有值（RED）
- [x] 6.3 编写测试：景点不存在抛出 SpotException(404, "not_found")（RED）
- [x] 6.4 编写测试：updateSpot 触发 KnowledgeBuilderService.refreshSpotDocument()（RED）
- [x] 6.5 创建 `service/SpotEnrichmentService.java`：实现 updateSpot 逻辑（GREEN）
- [x] 6.6 运行测试验证绿灯

## 7. KnowledgeBuilderService 增量更新（TDD）

- [x] 7.1 编写 `KnowledgeBuilderServiceTest` 新增测试：refreshSpotDocument 删除旧 Document + 写入新 Document（RED）
- [x] 7.2 编写测试：refreshSpotDocument 对不存在的 slug 不抛异常（RED）
- [x] 7.3 修改 `KnowledgeBuilderService.java`：新增 `refreshSpotDocument(SpotEntity)` 方法（GREEN）
- [x] 7.4 运行测试验证绿灯
- [x] 7.5 验证 Chroma delete API：确认 `VectorStore.delete()` 支持按 document ID 删除

## 8. SpotDataCollectorService 采集编排（TDD）

- [x] 8.1 编写 `SpotDataCollectorServiceTest`：collectStaleSpots 查询过期景点 + 逐个采集 + 保存报告（RED，mock MCP Client + mock ChatModel）
- [x] 8.2 编写测试：单个景点采集失败时标记为 failed，继续处理其他景点（RED）
- [x] 8.3 编写测试：无过期景点时保存 empty 报告（RED）
- [x] 8.4 编写测试：采集并发锁——已在执行时再次调用抛异常（RED）
- [x] 8.5 创建 `service/SpotDataCollectorService.java`：实现完整采集编排逻辑（GREEN）
  - `@Scheduled(cron)` 定时触发
  - `@Async` 异步执行
  - 内部调用 MCP Client 浏览器工具 + ChatModel LLM 提取 + SpotEnrichmentService 存储
- [x] 8.6 运行测试验证绿灯

## 9. SpotEnrichmentController 管理 API（TDD）

- [x] 9.1 编写 `SpotEnrichmentControllerTest`：GET /api/spots/stale 返回过期景点列表（RED）
- [x] 9.2 编写测试：POST /api/spots/enrichment/trigger 手动触发采集（RED）
- [x] 9.3 编写测试：POST /api/spots/enrichment/trigger 重复触发返回 409（RED）
- [x] 9.4 编写测试：GET /api/spots/enrichment/report/latest 返回最新报告（RED）
- [x] 9.5 创建 `controller/SpotEnrichmentController.java`：实现 3 个端点（GREEN）
- [x] 9.6 修改 `SecurityConfig.java`：允许 `/api/spots/stale`、`/api/spots/enrichment/**` 端点访问
- [x] 9.7 运行全部测试验证绿灯

## 10. 种子数据和配置更新

- [x] 10.1 修改 `data.sql`：现有景点 INSERT 语句增加 `data_refreshed_at` 列，北京景点设为 `2026-07-11`，其他城市景点设为更早日期（如 `2026-06-01`）
- [x] 10.2 修改 `application.yml`：新增 `app.enrichment.cron`、`app.enrichment.stale-days: 7`、`app.enrichment.critical-days: 30` 配置
- [x] 10.3 启动后端验证 data.sql 正常加载 + 全部测试绿灯

## 11. 收尾验证

- [x] 11.1 运行完整测试套件，确认全绿
- [x] 11.2 验证 `GET /api/spots/stale` 返回按优先级排序的过期景点列表
- [x] 11.3 验证 `POST /api/spots/enrichment/trigger` 手动触发采集 + 报告生成
- [x] 11.4 验证 `GET /api/spots/enrichment/report/latest` 返回采集报告
- [x] 11.5 验证 `@Scheduled` 定时任务在应用启动后正常注册（日志确认）
