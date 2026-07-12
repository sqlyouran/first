## Why

当前景点数据全部来自种子数据（`data.sql`），上次通过 Browser MCP 人工采集了北京 Top 20 景点数据（2026-07-11 `spots-data-enrichment` change）。但该流程是一次性的——没有自动刷新机制，景点门票价格、开放时间、评分等信息会逐渐过时。

数据过时带来的问题：
- AI 助手回答用户的实用信息问题（如"故宫门票多少钱"）时给出过期答案
- RAG 知识库中的景点文档与携程实际页面不一致
- 用户看到的景点信息可能已不准确

本次变更建立**自动化数据采集流水线**：后端 `@Scheduled` 每天凌晨 2 点自动触发，检查数据库中过期景点数据，通过 MCP Client 调用 Browser MCP Server 访问携程采集最新信息，DashScope LLM 结构化提取后双写 MySQL + Chroma 向量库，最后生成采集报告。

## What Changes

### 后端新增能力

- **MCP Client 集成**：引入 `spring-ai-starter-mcp-client`，后端作为 MCP Client 通过 stdio 模式连接 Browser MCP Server，调用 `navigate_page` / `take_snapshot` / `evaluate_script` 等浏览器工具
- **SpotEntity 新增 `dataRefreshedAt` 字段**：`TIMESTAMP` 类型，记录最后一次数据采集刷新的时间。采集更新时显式设置，`viewCount` 等非采集字段的变更不会触发该时间戳
- **SpotRepository 新增过期查询方法**：按 `dataRefreshedAt` 找出过期景点，严重过期（>30天）优先
- **SpotDataCollectorService 采集编排服务**：定时触发 → 查过期景点 → MCP Client 调用 Browser MCP 采集页面 → DashScope LLM 结构化提取 → 更新 MySQL + Chroma → 生成报告
- **SpotEnrichmentService 数据刷新服务**：更新 Spot 的采集字段 + `dataRefreshedAt`，触发 Chroma 增量更新
- **SpotEnrichmentReport 实体**：记录每次采集运行的汇总报告
- **后端管理 API 端点**（供前端/运维消费）：
  - `GET /api/spots/stale` — 返回过期景点列表（按优先级排序）
  - `POST /api/spots/enrichment/trigger` — 手动触发一次采集
  - `GET /api/spots/enrichment/report/latest` — 查询最近一次采集报告

## Capabilities

### New Capabilities

- `spots-data-refresh`: 景点数据自动采集刷新系统——后端 MCP Client 调用 Browser MCP + LLM 结构化提取 + 定时调度 + 过期检测 + Chroma 增量更新 + 采集报告

### Modified Capabilities

- `spots-backend-api`: SpotEntity 新增 `dataRefreshedAt` 字段，新增过期查询、采集管理 API 端点；后端同时作为 MCP Server（提供景点查询）和 MCP Client（调用 Browser MCP）
- `ai-chat-rag`: KnowledgeBuilderService 新增按 slug 删除/更新单个 Spot Document 的能力，支持采集后的增量更新

## Impact

- **后端数据库**：`spots` 表新增 `data_refreshed_at`（TIMESTAMP）列；新增 `spot_enrichment_reports` 表
- **后端 API**：新增 3 个管理端点（GET stale / POST trigger / GET report）
- **Chroma 向量库**：KnowledgeBuilderService 新增按 metadata.slug 删除旧 Document 的方法，采集后立即更新
- **后端依赖**：新增 `spring-ai-starter-mcp-client`（MCP Client 连接 Browser MCP Server）
- **运行环境**：后端启动时通过 stdio 模式自动拉起 Browser MCP Server 进程（Node.js），无需手动管理
- **前端**：本次不做前端页面（后续 change 可消费报告 API）
