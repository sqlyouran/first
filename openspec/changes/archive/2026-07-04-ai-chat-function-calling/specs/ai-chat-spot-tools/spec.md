## ADDED Requirements

### Requirement: 按城市查询景点列表

AI 助手 SHALL 能通过 Function Calling 调用 `searchSpotsByCity(cityName)` 查询指定城市的景点列表。

#### Scenario: 查询杭州景点

- **GIVEN** AI 助手已注册 `searchSpotsByCity` 工具
- **WHEN** 用户询问"杭州有哪些景点"
- **THEN** LLM 识别意图并调用 `searchSpotsByCity("Hangzhou")`
- **AND** 工具返回该城市最多 10 个 PUBLISHED 景点的摘要（name, nameZh, rating, tags）
- **AND** LLM 基于景点数据生成回答并流式推送

#### Scenario: 查询不存在的城市

- **WHEN** LLM 调用 `searchSpotsByCity("NonExistent")`
- **THEN** 工具返回空列表或"未找到景点"提示文本
- **AND** LLM 基于返回结果告知用户该城市暂无景点数据

---

### Requirement: 查询景点详情

AI 助手 SHALL 能通过 Function Calling 调用 `getSpotDetails(nameOrSlug)` 查询单个景点的完整信息。

#### Scenario: 查询灵隐寺详情

- **GIVEN** AI 助手已注册 `getSpotDetails` 工具
- **WHEN** 用户询问"灵隐寺的详细信息"
- **THEN** LLM 调用 `getSpotDetails("lingyin-temple")`
- **AND** 工具返回景点完整信息（name, nameZh, description, descriptionZh, tags, rating, gallery, cityName）
- **AND** LLM 基于详情数据生成结构化回答

#### Scenario: 查询不存在的景点

- **WHEN** LLM 调用 `getSpotDetails("non-existent")`
- **THEN** 工具返回"景点未找到"提示文本
- **AND** LLM 告知用户该景点不存在

---

### Requirement: 查询评分最高的景点

AI 助手 SHALL 能通过 Function Calling 调用 `getTopRatedSpots(limit)` 查询评分最高的景点列表。

#### Scenario: 查询 Top 5 景点

- **GIVEN** AI 助手已注册 `getTopRatedSpots` 工具
- **WHEN** 用户询问"评分最高的景点"
- **THEN** LLM 调用 `getTopRatedSpots(5)`
- **AND** 工具返回评分最高的 5 个景点摘要（name, nameZh, rating, cityName）
- **AND** LLM 基于排行榜数据生成回答

#### Scenario: limit 超出范围

- **WHEN** LLM 调用 `getTopRatedSpots(20)`
- **THEN** 工具将 limit 截断为 10（最大值）并返回结果

---

### Requirement: 工具注册

`SpotQueryTool` 的 `@Tool` 方法 SHALL 通过 `ToolCallbackProvider` bean 注册到 `ChatClient`，使 LLM 能在对话中自动发现并调用这些工具。

#### Scenario: ChatClient 工具注册验证

- **GIVEN** 应用启动且 `ToolCallbackProvider` bean 已配置
- **WHEN** `ChatClient` 构建时
- **THEN** `searchSpotsByCity`、`getSpotDetails`、`getTopRatedSpots` 三个工具的函数签名自动注入到 LLM prompt

#### Scenario: 测试环境工具不注册

- **GIVEN** 测试环境 `spring.ai.model.chat=none`
- **WHEN** `@SpringBootTest` 加载上下文
- **THEN** `ToolCallbackProvider` 不注册真实工具（mock ChatClient 不涉及工具调用）
