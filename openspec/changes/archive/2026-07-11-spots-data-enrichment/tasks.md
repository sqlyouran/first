## 1. SpotEntity 新增实用字段（TDD）

- [x] 1.1 编写 `SpotEntityTest` 新增测试：验证 ticketPrice/openingHours/address 可 NULL 持久化 + 可填充读写（RED）
- [x] 1.2 修改 `SpotEntity.java`：新增 ticketPrice(VARCHAR 200)、openingHours(VARCHAR 500)、address(VARCHAR 500) 字段 + getter/setter（GREEN）
- [x] 1.3 运行 SpotEntityTest 验证绿灯

## 2. SpotResponse DTO 扩展（TDD）

- [x] 2.1 修改 `SpotResponse.java`：新增 ticketPrice、openingHours、address 三个 `private final` 字段 + `@JsonProperty` 注解 + 构造器参数（放在末尾）+ getter
- [x] 2.2 修复所有 SpotResponse 构造器调用点（编译错误清零）：
  - `SpotService.toSpotResponse()` — 映射新字段
  - `SpotPostService.toSpotResponse()` — 映射新字段
  - `SpotServiceTest` / `SpotControllerTest` / `RankingCacheServiceTest` / `SpotQueryToolTest` 中的测试辅助方法
- [x] 2.3 运行全部测试确认编译通过 + 绿灯

## 3. KnowledgeBuilderService 更新（TDD）

- [x] 3.1 编写 `KnowledgeBuilderServiceTest` 新增测试：验证 SpotDocument 文本含 Ticket Price / Opening Hours / Address（RED）
- [x] 3.2 编写测试：验证新字段为 null 时对应行被省略（RED）
- [x] 3.3 修改 `KnowledgeBuilderService.toSpotDocument()`：拼接新字段，null 时省略（GREEN）
- [x] 3.4 运行 KnowledgeBuilderServiceTest 验证绿灯

## 4. SpotQueryTool 更新（TDD）

- [x] 4.1 编写 `SpotQueryToolTest` 新增测试：验证 getSpotDetails() 输出含 Ticket Price / Opening Hours / Address（RED）
- [x] 4.2 编写测试：验证新字段为 null 时输出不含对应行（RED）
- [x] 4.3 修改 `SpotQueryTool.getSpotDetails()`：拼接新字段，null 时省略（GREEN）
- [x] 4.4 运行 SpotQueryToolTest 验证绿灯

## 5. 携程数据采集（Browser MCP）

- [x] 5.1 用 Browser MCP 打开携程北京景点列表页，确认可用性
- [x] 5.2 逐个访问 Top 20 景点详情页，提取：名称(中/英)、门票价格、开放时间、地址、简介、评分
- [x] 5.3 LLM 结构化提取结果写入 `output/spots-beijing.json`（JSON 数组，每条含 name/nameZh/ticketPrice/openingHours/address/description/descriptionZh/rating/tags/slug）
- [x] 5.4 人工 review JSON 数据质量（评分归一化到 5 分制、slug 格式校验、字段完整性）

## 6. 种子数据更新

- [x] 6.1 将 `output/spots-beijing.json` 转为 data.sql 中的 INSERT 语句：现有 3 个北京景点（b1111111/b2222222/b3333333）字段值更新，新增 16 个景点使用新 UUID
- [x] 6.2 确保新 INSERT 包含 ticket_price / opening_hours / address 列
- [x] 6.3 启动后端验证 data.sql 正常加载 + 全部测试绿灯（379 tests, 0 failures）
- [x] 6.4 调用 `POST /api/ai/knowledge/rebuild` 重建 Chroma 索引，确认日志输出文档数量增加（51 documents indexed）

## 7. 收尾

- [x] 7.1 运行完整测试套件，确认全绿（379 tests, 0 failures, BUILD SUCCESS）
- [x] 7.2 验证 `GET /api/spots/{id}` 返回的北京景点包含 ticket_price / opening_hours / address
- [x] 7.3 验证 `GET /api/spots?city_id=<beijing>` 列表中新景点可见（19 Beijing spots）
