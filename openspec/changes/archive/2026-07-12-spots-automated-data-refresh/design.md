## Context

项目已有 `spots-data-enrichment` change 完成了北京 Top 20 景点的一次性数据采集（2026-07-11 归档）。该流程是手动的：人工在 Qoder 中使用 Browser MCP 逐页访问携程，LLM 提取后产出 JSON，人工转 SQL 写入 `data.sql`。

当前系统的数据刷新痛点：
- `SpotEntity.updatedAt` 在**任何字段变更**时都会刷新（包括 `viewCount++`），无法区分"采集刷新"和"普通更新"
- `KnowledgeBuilderService.rebuildAll()` 只能全量重建，无增量更新单个 Spot Document 的能力
- 后端无 Spot 更新 API（`PUT /api/spots/{id}`），只有 GET 和 POST（knowledge/rebuild）
- Browser MCP 的浏览器能力仅存在于 Qoder 客户端，后端无法直接调用

**关键突破**：Spring AI 同时支持 MCP Server 和 MCP Client。后端已是 MCP Server（`spring-ai-starter-mcp-server-webmvc`），引入 `spring-ai-starter-mcp-client` 后可作为 MCP Client 连接 Browser MCP Server，实现后端直接调用浏览器能力。

## Goals / Non-Goals

**Goals:**

- 后端引入 `spring-ai-starter-mcp-client`，通过 stdio 模式连接 Browser MCP Server
- SpotEntity 新增 `dataRefreshedAt`（`Instant`）字段，独立于 `updatedAt`，仅由采集更新操作设置
- SpotRepository 新增过期查询：按 `dataRefreshedAt` 找出 >7天未刷新的景点，严重过期（>30天）排最前
- 新增 `SpotDataCollectorService`：定时采集编排（查过期 → MCP 浏览器采集 → LLM 提取 → 存储 → 报告）
- 新增 `SpotEnrichmentService`：更新 Spot 采集字段 + 增量更新 Chroma Document
- 新增 `SpotEnrichmentReport` 实体和报告 API
- 后端提供 3 个管理 API 端点：
  - `GET /api/spots/stale` — 返回过期景点列表
  - `POST /api/spots/enrichment/trigger` — 手动触发采集
  - `GET /api/spots/enrichment/report/latest` — 查询最新报告
- KnowledgeBuilderService 新增 `refreshSpotDocument(spot)` 方法：删除 Chroma 中旧 Document + 写入新 Document
- 种子数据 `data.sql` 中为所有现有景点设置 `dataRefreshedAt` 初始值（采集日期）
- `@Scheduled(cron = "0 0 2 * * *")` 每天凌晨 2 点自动触发采集

**Non-Goals:**

- 不做前端采集管理页面（后续 change）
- 不做携程页面变化的自动适配（采集失败时标记为 failed，人工介入）
- 不做多城市自动扩展（当前仅覆盖已有景点的刷新）
- 不新增景点（仅刷新已有景点数据）
- 不做 Chroma 增量删除的 fallback 到全量重建（如果删除失败则记录警告，等下次全量重建）

## Architecture

```
┌─ 后端 Spring Boot (MCP Server + MCP Client 双角色) ──────────────────────────┐
│                                                                                │
│  ┌─ MCP Server（已有）──────────┐   ┌─ MCP Client（新增）───────────────────┐   │
│  │  wanderchina-travel-services │   │  连接 Browser MCP Server (stdio)     │   │
│  │  提供景点查询工具给 Qoder     │   │  调用 navigate_page / take_snapshot  │   │
│  └──────────────────────────────┘   └──────────┬───────────────────────────┘   │
│                                                │                               │
│  ┌─ @Scheduled 定时采集流水线 ──────────────────┴──────────────────────────┐    │
│  │                                                                        │    │
│  │  SpotDataCollectorService                                              │    │
│  │  @Scheduled(cron = "0 0 2 * * *")  ← 每天凌晨 2:00                     │    │
│  │       │                                                                │    │
│  │       ├─ Step 1: spotRepository.findStaleSpots(cutoff)                 │    │
│  │       │   → 返回过期景点列表（严重过期 >30天 优先）                       │    │
│  │       │                                                                │    │
│  │       ├─ Step 2: for each stale spot:                                  │    │
│  │       │   ├─ MCP Client → navigate_page(携程详情页URL)                  │    │
│  │       │   ├─ MCP Client → take_snapshot() → 页面文本                    │    │
│  │       │   ├─ DashScope LLM → 结构化提取 → EnrichRequest JSON            │    │
│  │       │   └─ enrichmentService.updateSpot(id, data)                    │    │
│  │       │       ├─ 更新 MySQL spots 表采集字段                             │    │
│  │       │       ├─ 设置 dataRefreshedAt = now()                          │    │
│  │       │       └─ KnowledgeBuilderService.refreshSpotDocument()          │    │
│  │       │           ├─ 删除 Chroma 旧 Document                            │    │
│  │       │           └─ 写入新 Document                                    │    │
│  │       │                                                                │    │
│  │       └─ Step 3: 保存 SpotEnrichmentReport（成功/失败/耗时/明细）         │    │
│  │                                                                        │    │
│  └────────────────────────────────────────────────────────────────────────┘    │
│                                                                                │
│  ┌─ 管理 API（供前端/运维消费）──────────────────────────────────────────┐      │
│  │  GET  /api/spots/stale                → 查看过期景点列表              │      │
│  │  POST /api/spots/enrichment/trigger   → 手动触发一次采集              │      │
│  │  GET  /api/spots/enrichment/report/latest → 查看最近采集报告          │      │
│  └──────────────────────────────────────────────────────────────────────┘      │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
         │                                              │
         │ MCP Client (stdio)                           │ DashScope API
         ▼                                              ▼
┌─ Browser MCP Server ──────────────────┐    ┌─ DashScope ──────────┐
│  (Node.js 进程, 后端自动启动)          │    │  qwen-plus (提取)     │
│  navigate_page / take_snapshot / ...   │    │  text-embedding-v3   │
└────────────────────────────────────────┘    └──────────────────────┘
```

## Decisions

### D1: 数据新鲜度追踪——新增 `dataRefreshedAt` 字段

**选择**: SpotEntity 新增 `dataRefreshedAt`（`Instant`），独立于 `BaseEntity.updatedAt`
**替代方案**: 复用 `updatedAt`（viewCount 变更也会刷新）；新增 SpotEnrichmentLog 表（复杂度高）
**理由**:
- `updatedAt` 被 `@PreUpdate` 控制，任何字段变更（含 viewCount++）都触发，无法精确判断采集时间
- `dataRefreshedAt` 仅在 `SpotEnrichmentService.updateSpot()` 中显式设置，语义精确
- 种子数据初始化时设置 `dataRefreshedAt` 为采集日期，后续过期检测基于此字段
- 比 SpotEnrichmentLog 表简单，符合 YAGNI

### D2: 采集调度——后端 `@Scheduled` + MCP Client 调用 Browser MCP

**选择**: 后端 `@Scheduled(cron)` 定时触发，通过 `spring-ai-starter-mcp-client` 作为 MCP Client 连接 Browser MCP Server，直接调用浏览器工具（navigate_page / take_snapshot / evaluate_script）
**替代方案 A**: Qoder Agent + Schedule MCP 自延续（依赖 Qoder 客户端运行，Schedule MCP 只支持 one-shot）
**替代方案 B**: 后端直接引入 Playwright Java（需装 Chromium 引擎，~150MB 运行时，丢失 LLM 提取便利）
**理由**:
- `@Scheduled` 天然支持 cron 循环，无需自延续模式
- MCP Client 复用 Browser MCP 的浏览器能力和反爬封装，无需自己装 Chromium
- 后端独立运行，不依赖 Qoder 客户端——只要后端服务在跑就能自动采集
- Browser MCP Server 进程由 MCP Client 的 stdio 模式自动启动和管理（后端关了它也跟着关）
- DashScope LLM 提取能力已有（AI 聊天在用），零额外依赖

### D3: 后端 MCP 双角色——Server + Client 共存

**选择**: 后端同时作为 MCP Server（提供景点查询工具给 Qoder/AI）和 MCP Client（调用 Browser MCP 采集数据）
**理由**:
- MCP Server 和 MCP Client 是 Spring AI 的两个独立模块，可以共存
- Server 角色不变（`spring-ai-starter-mcp-server-webmvc`），继续为 AI 聊天提供景点查询
- Client 角色新增（`spring-ai-starter-mcp-client`），仅在采集流水线中使用

### D4: Chroma 增量更新——按 slug 删除旧 Document + 写入新 Document

**选择**: KnowledgeBuilderService 新增 `refreshSpotDocument(SpotEntity)` 方法，先删除 metadata.slug 匹配的旧文档，再写入新 Document
**替代方案**: 全量重建（调用现有 `rebuildAll()`）；不做 Chroma 更新（等 6h 定时重建自动同步）
**理由**:
- 全量重建对 50+ 文档只需几秒，但每次采集 N 个景点就重建 N 次不合理
- 增量更新保持 Chroma 与 MySQL 实时一致，RAG 回答立即反映最新数据
- 风险：Chroma 的 metadata-based delete 可能不支持精确匹配，需要验证

### D5: 过期检测优先级排序——SQL 单查询 + CASE WHEN

**选择**: SpotRepository 使用 `@Query` 注解，SQL 中用 `CASE WHEN` 将景点分为两组（>30天 / 7-30天），`ORDER BY` 排序
**替代方案**: Java 内存排序（查出所有过期景点后在 Java 层分组排序）
**理由**:
- 数据库排序效率高，避免大数据量时内存排序
- 景点数量有限（<100），差异不大，但 SQL 方案更规范

### D6: 采集报告存储——独立 SpotEnrichmentReport 实体

**选择**: 新建 `SpotEnrichmentReport` 实体，记录每次采集运行的汇总信息
**替代方案**: 写入日志文件；复用 notifications 模块
**理由**:
- 结构化存储便于后续前端消费（展示采集历史）
- 日志文件不便于查询和展示
- 报告实体保持轻量：runId/startedAt/completedAt/totalAttempted/totalSuccess/totalFailed/details(JSON)

### D7: LLM 结构化提取——复用 DashScope ChatModel

**选择**: 采集编排服务直接注入现有的 `ChatModel`（DashScope qwen-plus），构造提取 prompt 让 LLM 从页面文本中提取结构化 JSON
**替代方案**: 使用 Function Calling（过度设计）；自己写正则解析（脆弱）
**理由**:
- 项目已有 DashScope API Key 和 ChatModel Bean，零额外依赖
- LLM 提取对页面结构变化有天然容错性（页面改版后只需调整 prompt，不需改解析代码）
- 提取 prompt 可配置化（存入 application.yml 或配置类），便于迭代

## File Changes

### 新建文件

| 文件 | 职责 |
|---|---|
| `service/SpotDataCollectorService.java` | 采集编排：@Scheduled 触发 → 查过期 → MCP 浏览器采集 → LLM 提取 → 存储 → 报告 |
| `service/SpotEnrichmentService.java` | 数据刷新：updateSpot + Chroma 增量更新 |
| `entity/SpotEnrichmentReport.java` | 采集报告实体：runId, startedAt, completedAt, totalAttempted/Success/Failed, details(JSON) |
| `repository/SpotEnrichmentReportRepository.java` | 报告 Repository：findTopByOrderByStartedAtDesc |
| `dto/request/EnrichRequest.java` | LLM 提取结果 / 内部数据传递 record |
| `dto/response/StaleSpotResponse.java` | 过期景点响应 DTO |
| `dto/response/StaleSpotListResponse.java` | 过期景点列表响应 DTO |
| `dto/response/EnrichmentReportResponse.java` | 采集报告响应 DTO |
| `controller/SpotEnrichmentController.java` | 管理 API 端点 |
| `config/McpClientConfig.java` | MCP Client 连接配置（Browser MCP Server stdio 模式） |

### 修改文件

| 文件 | 变更 |
|---|---|
| `entity/SpotEntity.java` | 新增 `dataRefreshedAt`（Instant）字段 + getter/setter |
| `repository/SpotRepository.java` | 新增 `findStaleSpots(Instant cutoff)` 查询方法 |
| `service/KnowledgeBuilderService.java` | 新增 `refreshSpotDocument(SpotEntity)` 方法（删旧写新） |
| `src/main/resources/data.sql` | 现有景点 INSERT 语句增加 `data_refreshed_at` 列 |
| `application.yml` | 新增 MCP Client 配置 + `app.enrichment.*` 配置 |
| `pom.xml` | 新增 `spring-ai-starter-mcp-client` 依赖 |

### 测试文件（TDD）

| 文件 | 测试内容 |
|---|---|
| `entity/SpotEnrichmentReportTest.java` | 报告实体持久化 |
| `service/SpotEnrichmentServiceTest.java` | 数据刷新逻辑 + Chroma 增量更新 |
| `service/SpotDataCollectorServiceTest.java` | 采集编排逻辑（mock MCP Client + mock LLM） |
| `controller/SpotEnrichmentControllerTest.java` | 3 个管理 API 端点 |
| `service/KnowledgeBuilderServiceTest.java`（修改） | 新增 refreshSpotDocument 测试 |
| `repository/SpotRepositoryTest.java`（修改） | 新增 findStaleSpots 测试 |

## Risks / Trade-offs

| 风险 | 缓解措施 |
|---|---|
| Browser MCP Server stdio 进程启动失败 | MCP Client 配置中设超时；采集服务 catch 异常后标记本次采集全部 failed，等下次定时重试 |
| 携程页面结构变化导致采集失败 | LLM 提取对页面变化有天然容错；单个景点采集失败标记为 failed，不中断整体流程 |
| 携程反爬触发验证码 | Browser MCP 操作间隔 3-5 秒（navigate_page 之间加 delay）；每次采集景点数 <50 |
| MCP Client 与 MCP Server 共存冲突 | Spring AI 支持双角色；MCP Server 走 webmvc HTTP，MCP Client 走 stdio，互不干扰 |
| Chroma delete by metadata 不可靠 | 如果按 metadata.slug 删除失败，记录 WARN 日志，等下次 6h 全量重建兜底 |
| `dataRefreshedAt` 初始值全部相同 | data.sql 中为不同景点设置不同日期（北京景点设为 07-11，其他城市设为更早日期） |
| 后端服务器没有 Node.js 环境 | Browser MCP 依赖 Node.js（npx）；部署文档中需注明；或提供 SSE 模式连接已有 Browser MCP |

## Open Questions

1. **Browser MCP Server 的 npm 包名和启动命令**：需确认当前 Qoder 使用的 Browser MCP 的具体包名和启动参数
2. **采集覆盖范围**：当前仅刷新已有景点数据，是否需要支持发现新景点？→ 本次 Non-Goal
3. **Chroma delete API 兼容性**：需验证 `VectorStore.delete(List<String>)` 是否支持按 document ID 或 metadata 删除
4. **MCP Client stdio 模式下的 Tool 调用方式**：需验证 Spring AI MCP Client 的 `ToolCallback` 接口是否支持直接调用 Browser MCP 的 navigate_page / take_snapshot
