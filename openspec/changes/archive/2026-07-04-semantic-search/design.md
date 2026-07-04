## Context

WanderChina 平台已建成完整的 RAG 向量检索基础设施：

- **Chroma 向量库**（`localhost:8000`，collection `wanderchina-knowledge`）存储 City / Spot / Post 的 1024 维 DashScope text-embedding-v3 向量
- **KnowledgeSearchService** 封装 `VectorStore.similaritySearch()`，支持 topK + similarity threshold + metadata filter（city_name）
- **KnowledgeBuilderService** ETL 管道将 DB 实体转为 Spring AI `Document` 写入 Chroma，定时全量重建（6h）

但上述能力仅被 `AiChatService` 内部调用用于 RAG 增强 AI 对话。用户侧无任何搜索入口——HeroSlot 搜索框纯装饰，Spots/Posts 列表页仅支持筛选和排序。

数据库环境：开发/生产用 MySQL 8（`jdbc:mysql://localhost:3306/wanderchina`），测试用 H2 内存库（`jdbc:h2:mem:testdb`）。

## Goals / Non-Goals

**Goals:**

- 将现有向量检索能力暴露为用户可用的搜索 API
- 通过 RRF (Reciprocal Rank Fusion) 融合向量检索 + 关键词检索，兼顾语义匹配与精确匹配
- 两级搜索体验：HeroSlot 输入时实时建议（低延迟）+ 提交后跳转完整搜索结果页（高召回）
- 复用现有 Chroma + KnowledgeSearchService + KnowledgeBuilderService，零改动
- 测试环境隔离：H2 LIKE + SimpleVectorStore，不依赖外部服务

**Non-Goals:**

- 不引入 MySQL FULLTEXT INDEX（LIKE 足够，且 H2 不支持 FULLTEXT 语法）
- 不引入 Elasticsearch / Meilisearch 等独立搜索引擎
- 不做搜索历史 / 个性化排序 / 点击反馈
- 不做搜索结果分页（种子数据量小，首屏返回全部）
- 不修改 KnowledgeBuilderService ETL 管道（数据已索引，无需重建）
- 不做搜索 API 认证（公开端点，与 spots/posts 列表一致）

## Decisions

### 1. 混合检索融合：RRF (k=60)

**选择**：Reciprocal Rank Fusion，公式 `score(d) = Σ 1/(k + rank_i(d))`，k=60

**备选方案**：

| 方案 | 优点 | 缺点 |
|------|------|------|
| 向量优先 + 关键词补全 | 实现最简单 | 排序不最优，关键词结果永远排在后面 |
| **RRF** | 无需分数归一化，天然兼容异构检索系统，业界标准 | 需要两路结果都有排名 |
| 加权分数融合 | 可调节权重 | 需要分数归一化（向量 0~1 vs 关键词 0~6），复杂 |

**理由**：RRF 只看排名位置，不依赖原始分数。向量相似度（0~1）和关键词打分（整数）量纲不同，RRF 天然规避归一化问题。k=60 是 SIGIR 2009 论文经验值，对小数据集（~30 Document）仍有效。

### 2. 关键词检索：MySQL LIKE + 自定义打分

**选择**：JPA `LIKE` 查询 + 手动打分（name/nameZh 命中=3 分，tags 命中=2 分，description 命中=1 分）

**备选方案**：

| 方案 | 优点 | 缺点 |
|------|------|------|
| **LIKE + 自定义打分** | MySQL/H2 双兼容，实现简单 | 无原生相关性分数 |
| MySQL FULLTEXT + H2 fallback | 生产环境关键词匹配更精准 | 两套代码路径，`@Profile` 区分，复杂度高 |
| Chroma where_document | 一步完成向量+关键词 | Chroma 1.0 的 where_document 支持有限，中文分词差 |

**理由**：种子数据量小（~30 条），LIKE 性能不是瓶颈。打分逻辑只需产出排名供 RRF，不需要精确的相关性分数。H2 测试兼容性是硬约束——FULLTEXT 语法在 H2 上不可用。

### 3. 搜索建议：纯关键词，不调 embedding API

**选择**：`GET /api/search/suggest?q=...` 仅做 MySQL LIKE top-5，不调 DashScope embedding API

**理由**：搜索建议需要低延迟（< 50ms）。DashScope embedding API 调用延迟 ~200ms，不适合实时输入场景。关键词 LIKE 查询纯 DB 操作，延迟 < 50ms。建议结果仅用于快速预览，用户提交后走完整 RRF 混合检索。

### 4. 搜索 API 端点：统一 `/api/search`

**选择**：`GET /api/search?q=...&type=all|spot|post|city&city=...` 返回分组结果

**备选方案**：

| 方案 | 优点 | 缺点 |
|------|------|------|
| **统一端点** | 跨类型搜索最自然，一次请求返回混合结果 | 需要分组逻辑 |
| 按类型分发 | 每个端点简单 | 前端需并发 3 个请求，合并复杂 |

**理由**：语义搜索天然是跨类型的——用户搜"长城"可能想看景点、帖子或城市。统一端点一次返回所有类型，前端用 Tab 分组展示。

### 5. 前端搜索组件：提取 `SearchSuggest` Client Component

**选择**：从 HeroSlot 提取搜索交互逻辑为独立的 `"use client"` 组件 `SearchSuggest`，HeroSlot 作为 Server Component 渲染它

**理由**：HeroSlot 当前是 Server Component（无 `"use client"`）。搜索建议需要客户端状态（input value、debounce、dropdown 显隐），必须用 Client Component。提取为独立组件保持 HeroSlot 的 Server Component 性质，符合前端规约"默认 Server Component，仅在需要交互时加 use client"。

### 6. 搜索结果页路由：`/search`

**选择**：`app/search/page.tsx`，Client Component，通过 URL query param `?q=...` 传参

**理由**：搜索结果页需要可分享、可书签的 URL。`?q=...` 是搜索页面的标准 URL 模式。Client Component 因为需要根据 query param 变化重新请求 API。

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| H2 LIKE 与 MySQL LIKE 中文匹配行为差异 | 测试使用英文数据规避；LIKE 在两种 DB 上语义一致（`%keyword%` 子串匹配） |
| RRF k=60 对小数据集可能不够敏感 | 实现时将 k 设为可配置参数（`app.search.rrf-k`），便于调优；种子数据量小可人工验证 |
| Chroma 不可用时搜索降级 | `HybridSearchService` 对向量检索做 try-catch，失败时降级为纯关键词检索（与 AiChatService 的 RAG 降级策略一致） |
| 搜索建议 dropdown 与 HeroSlot 视觉风格冲突 | SearchSuggest 复用 shadcn/ui Popover/Command 组件，保持设计系统一致性 |
| 搜索结果页与 spots/posts 列表页卡片样式不统一 | 复用现有 SpotCard / PostCard 组件，搜索结果卡片统一适配 |

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                     语义搜索架构                                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Frontend                                                        │
│  ┌──────────────────────────────────────────┐                    │
│  │ HeroSlot (Server Component)              │                    │
│  │  └── <SearchSuggest /> (Client)          │                    │
│  │       ├── input → debounce 300ms         │                    │
│  │       │   → GET /api/search/suggest?q=   │                    │
│  │       │   → dropdown top-5 suggestions   │                    │
│  │       └── submit → router.push('/search')│                    │
│  ├──────────────────────────────────────────┤                    │
│  │ /search?q=... (Client Component)         │                    │
│  │  ├── Tab: 全部 | 景点 | 帖子 | 城市      │                    │
│  │  └── GET /api/search?q=...&type=...      │                    │
│  │      → SearchResults → SpotCard/PostCard │                    │
│  └──────────────────────────────────────────┘                    │
│              │                          │                        │
│         lib/api/search.ts         lib/backend.ts (BFF)           │
│              │                          │                        │
│  ─ ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│              ▼                          ▼                        │
│  Backend                                                         │
│  ┌──────────────────────────────────────────┐                    │
│  │ SearchController                          │                    │
│  │  ├── GET /api/search?q=&type=&city=      │                    │
│  │  └── GET /api/search/suggest?q=          │                    │
│  ├──────────────────────────────────────────┤                    │
│  │ HybridSearchService                      │                    │
│  │  ├── vectorResults ← KnowledgeSearchService │  (复用)         │
│  │  ├── keywordResults ← KeywordSearchService  │  (新)           │
│  │  ├── RRF融合 (k=60) + slug去重            │                    │
│  │  └── 按entity_type分组 → SearchResponse   │                    │
│  ├──────────────────────────────────────────┤                    │
│  │ KeywordSearchService (新)                 │                    │
│  │  ├── SpotRepository.findByNameContaining  │                    │
│  │  ├── PostRepository.findByTitleContaining │                    │
│  │  ├── CityRepository.findByNameContaining  │                    │
│  │  └── 打分: name=3, tags=2, desc=1         │                    │
│  ├──────────────────────────────────────────┤                    │
│  │ KnowledgeSearchService (复用，零改动)      │                    │
│  │  └── vectorStore.similaritySearch(query)  │                    │
│  └──────────────────────────────────────────┘                    │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## New Source Files

| 文件 | 职责 |
|---|---|
| `controller/SearchController.java` | HTTP 层：参数校验、委托 service、构造 response |
| `service/HybridSearchService.java` | RRF 融合：向量检索 + 关键词检索 → 合并去重 → 分组 |
| `service/KeywordSearchService.java` | 关键词检索：LIKE 查询 + 打分排名 |
| `dto/response/SearchResponse.java` | 搜索结果响应（items + 分组计数 + request_id） |
| `dto/response/SearchResultItem.java` | 单条搜索结果（type + slug + name + 摘要 + score） |
| `dto/response/SearchSuggestResponse.java` | 搜索建议响应（items + request_id） |
| `frontend/lib/api/search.ts` | 搜索 API 客户端函数 |
| `frontend/app/search/page.tsx` | 搜索结果页 |
| `frontend/app/search/_components/SearchResults.tsx` | 结果列表组件 |
| `frontend/app/_components/SearchSuggest.tsx` | Hero 搜索建议 Client Component |

## Modified Source Files

| 文件 | 变更 |
|---|---|
| `repository/SpotRepository.java` | 新增 `findByNameContainingOrNameZhContainingOrDescriptionContaining` |
| `repository/PostRepository.java` | 新增 `findByTitleContainingAndStatusAndDeletedFalse` |
| `repository/CityRepository.java` | 新增 `findByNameContainingOrNameZhContaining` |
| `config/SecurityConfig.java` | 放行 `/api/search/**` 端点 |
| `frontend/app/regions/HeroSlot.tsx` | 搜索框替换为 `<SearchSuggest />` 组件 |

## Configuration

```yaml
app:
  search:
    rrf-k: 60                    # RRF 常数
    vector-top-k: 10             # 向量检索返回数量
    keyword-top-k: 10            # 关键词检索返回数量
    suggest-top-k: 5             # 搜索建议返回数量
    similarity-threshold: 0.3    # 向量检索相似度阈值（复用 RAG 配置）
```

## Open Questions

- 搜索结果页是否需要支持无限滚动？当前设计为首屏返回全部结果（种子数据量小）。后续数据量增长时可加 cursor 分页。
- 搜索建议 dropdown 的键盘导航（↑↓选择）是否在 MVP 范围内？建议 P2 实现。
