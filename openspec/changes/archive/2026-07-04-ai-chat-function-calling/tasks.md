## 1. 景点查询工具类

- [x] 1.1 新增 `service/SpotQueryTool.java` — 构造器注入 `SpotRepository` + `SpotService`；定义三个 `@Tool` 方法
- [x] 1.2 实现 `searchSpotsByCity(@ToolParam citySlug)` — 调用 `SpotRepository.findByCitySlugAndDeletedFalse(citySlug, PageRequest.of(0, 10, Sort.by(DESC, "rating")))`；将结果格式化为文本摘要（每行：`- {name} ({nameZh}) | Rating: {rating} | Tags: {tags}`），空结果返回 `"No spots found in {citySlug}"`
- [x] 1.3 实现 `getSpotDetails(@ToolParam nameOrSlug)` — 调用 `SpotRepository.findBySlugAndDeletedFalse(nameOrSlug)`；将结果格式化为完整信息文本（name, nameZh, description, descriptionZh, tags, rating, gallery, cityName），未找到返回 `"Spot not found: {nameOrSlug}"`
- [x] 1.4 实现 `getTopRatedSpots(@ToolParam limit)` — limit 截断到 max 10；调用 `SpotService.getRanking("rating", limit, requestId)`；将结果格式化为排行榜文本

## 2. 工具注册配置

- [x] 2.1 新增 `config/SpotToolCallbackProvider.java` — `@Configuration`，`@ConditionalOnProperty(name = "spring.ai.model.chat", havingValue = "dashscope", matchIfMissing = true)`；定义 `@Bean ToolCallbackProvider spotToolCallbackProvider(SpotQueryTool tool)` → 返回 `new SyncToolCallbackProvider(tool)`
- [x] 2.2 修改 `config/AiConfig.java` — `chatClient()` 方法增加 `ToolCallbackProvider` 参数，调用 `builder.defaultTools(toolCallbackProvider.getToolCallbacks())` 注册工具

## 3. AiChatService 适配

- [x] 3.1 确认 `AiChatService.sendMessage()` 的 `chatClient.prompt().messages().stream()` 调用链是否需显式传入 tools（Spring AI 通过 `defaultTools` 自动注入则无需改动）；如需显式传入，修改调用链增加 `.tools()` 调用

## 4. 测试

- [x] 4.1 新增 `service/SpotQueryToolTest.java` — 单元测试（非 @SpringBootTest）；mock `SpotRepository` + `SpotService`；测试三个工具的：正常返回、空结果、limit 截断
- [x] 4.2 修改 `AiChatServiceTest` — 确认现有 mock 链路是否需适配 tools 上下文（`when(requestSpec.tools(any())).thenReturn(requestSpec)` 等）；如需要则补充
- [x] 4.3 新增测试配置：`test/` 下新增 `TestSpotToolCallbackProvider` 或确保 `@ConditionalOnProperty` 在测试环境不创建真实 `ToolCallbackProvider` bean
- [x] 4.4 运行全量后端测试 `mvn -f backend/pom.xml test`，确保全部通过
