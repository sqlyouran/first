## Why

当前景点数据全部手写（`data.sql` 中 16 条种子数据），字段仅覆盖 Phase 1 最小集（名称、描述、标签、评分），缺少门票价格、开放时间、地址等实用信息。北京仅有 3 个景点（故宫、八达岭长城、天坛），数据单薄，无法支撑 AI 问答、景点详情页等场景的信息丰富度需求。

本次变更以北京 Top 20 景点为试点，通过 Browser MCP 从携程采集真实数据，同时落地 Phase 2 实用字段（门票、开放时间、地址），为后续其他城市扩展建立可复用的采集→导入流程。

## What Changes

- **SpotEntity 新增 3 个实用字段**：`ticketPrice`（VARCHAR 200）、`openingHours`（VARCHAR 500）、`address`（VARCHAR 500），均可为 NULL
- **SpotResponse 新增对应字段**：`ticket_price`、`opening_hours`、`address`，snake_case 序列化
- **SpotQueryTool（AI Function Calling）更新**：`getSpotDetails()` 输出中包含门票、开放时间、地址
- **KnowledgeBuilderService 更新**：Spot Document 文本中包含新字段内容，提升 RAG 回答信息量
- **data.sql 北京景点数据替换**：现有 3 个北京景点（故宫、八达岭长城、天坛）用采集数据覆盖；新增约 17 个北京景点，合计 20 个
- **采集工具链（一次性流程）**：Qoder + Browser MCP 访问携程景点页 → LLM 结构化提取 → 产出 `spots-beijing.json` → 转为 `data.sql` INSERT 语句

## Capabilities

### New Capabilities

_（无新增运行时能力。采集工具链为一次性数据填充流程，不构成持久化能力。）_

### Modified Capabilities

- `spots-backend-api`: SpotEntity 新增 Phase 2 实用字段（ticketPrice / openingHours / address），SpotResponse 和 API 响应格式同步更新，种子数据替换为北京 Top 20 真实采集数据
- `ai-chat-rag`: KnowledgeBuilderService 的 `toSpotDocument()` 方法输出文本包含门票价格、开放时间、地址等新字段；SpotQueryTool 的 `getSpotDetails()` 输出同步更新

## Impact

- **后端数据库**：`spots` 表新增 `ticket_price`（VARCHAR 200）、`opening_hours`（VARCHAR 500）、`address`（VARCHAR 500）三列，均允许 NULL；H2 开发环境 `create-drop` 自动重建无影响，MySQL 需 `ddl-auto: update` 或手动 ALTER TABLE
- **后端 API**：`GET /api/spots`、`GET /api/spots/{id}`、`GET /api/spots/ranking` 响应中新增 `ticket_price`、`opening_hours`、`address` 字段（可为 null）；前端未消费这些字段时不受影响（向后兼容）
- **种子数据**：北京 3 个景点的 UUID 保持不变（`b1111111`、`b2222222`、`b3333333`），字段值用采集数据覆盖；新增约 17 个北京景点使用新 UUID
- **Chroma 向量库**：重建后 Spot Document 文本更丰富，RAG 检索质量提升
- **前端**：无需改动（新字段暂不在前端展示，后续 change 可消费）
- **依赖**：无新增 Maven/Node 依赖
