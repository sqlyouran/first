## Context

当前 `SpotEntity` 处于 Phase 1 最小集（名称、描述、标签、评分、统计），实用信息字段（门票、开放时间、地址）在设计文档中明确推迟到 Phase 2。种子数据全部手写，北京仅 3 个景点，信息单薄。

现有 RAG 知识库（`KnowledgeBuilderService`）已将 Spot 转为 Document 写入 Chroma，但 Spot Document 文本仅含名称、城市、标签、评分、描述，缺乏实用信息。

携程景点页面包含本次需要的 6 类数据：名称、门票价格、开放时间、地址、简介、评分。通过 Qoder 内置的 Browser MCP（Playwright）可模拟浏览器操作，逐页提取并结构化。

## Goals / Non-Goals

**Goals:**

- SpotEntity 新增 3 个 Phase 2 实用字段（ticketPrice / openingHours / address），所有 NULL-able
- SpotResponse DTO 同步新增 `ticket_price` / `opening_hours` / `address`，向后兼容（前端未消费时为 null）
- SpotService / SpotPostService 的 `toSpotResponse()` 映射新字段
- KnowledgeBuilderService 的 `toSpotDocument()` 文本包含新字段（null 时省略）
- SpotQueryTool 的 `getSpotDetails()` 输出包含新字段（null 时省略）
- data.sql 中北京景点扩至 20 个，含真实采集的实用信息
- 采集产出物为 `spots-beijing.json`，便于后续城市复用

**Non-Goals:**

- 不做前端展示新字段（后续 change）
- 不做定期自动采集/同步（一次性数据填充）
- 不做后端采集 Service（携程反爬复杂，YAGNI）
- 不修改 CityEntity / PostEntity
- 不新增 Maven 依赖
- 不做多城市采集（仅北京试点）

## Decisions

### D1: 新字段类型——全 VARCHAR，不做结构化拆分

**选择**: ticketPrice VARCHAR(200)、openingHours VARCHAR(500)、address VARCHAR(500)
**替代方案**: ticketPrice 用 DECIMAL + currency 两列；openingHours 用 JSON 对象（按星期拆分）
**理由**:
- 携程原始数据就是非结构化文本（"旺季60元/淡季40元"、"08:30-17:00（4月-10月）"），强行结构化会丢信息
- 前端当前不消费这些字段做筛选/排序，只需展示
- YAGNI：等需要结构化查询时再拆

### D2: 采集方式——Qoder + Browser MCP 手工采集

**选择**: 在 Qoder 会话中用 Browser MCP 访问携程 → LLM 结构化提取 → JSON 文件
**替代方案**: 后端 Java Service 集成 Playwright Java / HTTP 请求
**理由**:
- 一次性数据填充，不值得在后端引入 Playwright Java 依赖
- Browser MCP 模拟真实浏览器操作，反爬风险低于 HTTP 直接请求
- 产出 JSON 文件可版本控制，便于 review 和复用

### D3: 种子数据合并策略——UUID 不变 + INSERT IGNORE 幂等

**选择**: 现有 3 个北京景点 UUID 不变，data.sql 中用新数据覆盖旧值；新增 17 个用新 UUID
**替代方案**: 删除重建（所有 UUID 换新）
**理由**:
- 现有 UUID 被 `spots_posts` 关联表引用，删除重建会破坏关联关系
- INSERT IGNORE 保证幂等，重启不重复插入
- 但 INSERT IGNORE 不会更新已有行——因此需要 **先删除旧的 3 个北京景点再重新插入**，或改用 `MERGE` 语法。鉴于 H2 `create-drop` 每次启动重建，实际用 INSERT 即可；MySQL 环境需用 `INSERT ... ON DUPLICATE KEY UPDATE`

### D4: 采集数据中转——JSON 文件 → data.sql 两阶段

**选择**: 先产出 `output/spots-beijing.json`，review 后人工转成 `data.sql` INSERT 语句
**替代方案**: 采集完直接写 data.sql
**理由**:
- JSON 文件便于 review 数据质量（不混入 SQL 语法噪音）
- 后续城市扩展时只需替换 JSON，转换逻辑可复用
- data.sql 是后端启动时执行的 SQL，不适合频繁修改

### D5: 新增字段的 API 向后兼容

**选择**: 新字段为 nullable，SpotResponse 构造器新增参数放在末尾
**理由**:
- 前端未消费这些字段时，JSON 中多几个 null 字段不影响渲染
- SpotResponse 已有 `@JsonCreator` 构造器，新增字段需同步更新所有调用点
- 影响范围：SpotService.toSpotResponse()、SpotPostService.toSpotResponse()、RankingCacheService 测试、SpotControllerTest、SpotQueryToolTest

## 文件变更清单

| 文件 | 变更类型 | 说明 |
|---|---|---|
| `entity/SpotEntity.java` | MODIFY | 新增 3 字段 + getter/setter |
| `entity/SpotEntityTest.java` | MODIFY | 新增实用字段持久化测试 |
| `dto/response/SpotResponse.java` | MODIFY | 新增 3 字段 + 构造器参数 + getter |
| `service/SpotService.java` | MODIFY | toSpotResponse() 映射新字段 |
| `service/SpotPostService.java` | MODIFY | toSpotResponse() 映射新字段 |
| `service/KnowledgeBuilderService.java` | MODIFY | toSpotDocument() 文本含新字段 |
| `service/SpotQueryTool.java` | MODIFY | getSpotDetails() 输出含新字段 |
| `service/KnowledgeBuilderServiceTest.java` | MODIFY | 验证新字段文档生成 |
| `service/SpotQueryToolTest.java` | MODIFY | 验证新字段输出 |
| `service/SpotServiceTest.java` | MODIFY | 构造器调用更新 |
| `service/RankingCacheServiceTest.java` | MODIFY | 构造器调用更新 |
| `controller/SpotControllerTest.java` | MODIFY | 构造器调用更新 |
| `src/main/resources/data.sql` | MODIFY | 北京景点替换 + 新增 |
| `output/spots-beijing.json` | NEW | 采集产出 JSON |

## Risks / Trade-offs

| 风险 | 缓解措施 |
|---|---|
| 携程页面结构变化导致采集失败 | 一次性采集，不影响运行时；后续城市扩展时重新适配 |
| 携程反爬触发验证码 | Browser MCP 操作速度慢，模拟真人；单页采集间隔 3-5 秒 |
| SpotResponse 构造器参数膨胀（已达 20+） | 当前可接受；后续如继续膨胀可引入 Builder 模式 |
| data.sql 中 INSERT IGNORE 不更新已有行 | H2 `create-drop` 每次重建无影响；MySQL 环境用 `ON DUPLICATE KEY UPDATE` |
| 采集数据质量（门票价格可能有"免费"等多种表述） | JSON 文件 review 环节人工校验 |

## Open Questions

1. **携程景点列表入口 URL**：需要确认携程北京景点列表页的具体 URL 格式
2. **评分映射**：携程评分是 5 分制还是 10 分制？是否需要归一化到 5 分制（项目已有 `rating` 字段是 5 分制 DECIMAL(2,1)）
3. **非北京景点的实用字段**：现有 13 个非北京景点（上海/成都/西安/杭州/桂林/丽江/厦门）的 ticketPrice/openingHours/address 暂时保持 null，是否需要在后续 change 中补全？
