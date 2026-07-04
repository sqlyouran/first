## Why

当前 WanderChina 平台没有任何用户可见的搜索功能。首页 HeroSlot 有一个搜索框但纯装饰——无 onSubmit、不跳转、不查询。景点和帖子列表页仅支持城市筛选和排序，无文本搜索。与此同时，平台已建成完整的 RAG 向量检索基础设施（Chroma + DashScope embedding-v3 + KnowledgeSearchService），但这些能力仅被 AI 聊天内部使用，从未暴露给用户。本变更将复用现有向量数据库，新增关键词检索，通过 RRF 混合融合为用户提供自然语言搜索能力。

## What Changes

- 新增后端混合检索 API：`GET /api/search?q=...&type=...&city=...&page=...&size=...`，返回跨类型分组结果（spots / posts / cities）
- 新增后端搜索建议 API：`GET /api/search/suggest?q=...`，纯关键词 LIKE 查询返回 top-5 建议（不调 embedding API，低延迟）
- 新增 `HybridSearchService`：调用 `KnowledgeSearchService`（向量检索）+ `KeywordSearchService`（MySQL LIKE 检索），通过 RRF (Reciprocal Rank Fusion, k=60) 融合排名，按 slug 去重，按 entity_type 分组返回
- 新增 `KeywordSearchService`：MySQL LIKE 查询 Spot/Post/City 的 name/description/tags，自定义打分（name=3, tags=2, desc=1）产出排名供 RRF
- 新增前端搜索结果页 `/search?q=...`：分类 Tab（全部/景点/帖子/城市）+ 结果卡片列表，复用现有 SpotCard / PostCard 组件
- 新增前端搜索建议组件：HeroSlot 搜索框输入时 debounce 300ms 请求建议 API，显示 dropdown 快速建议
- 修改 `HeroSlot` 搜索框：从纯装饰变为功能性——输入时显示建议 dropdown，提交时跳转 `/search?q=...`
- 修改 `SpotRepository` / `PostRepository`：新增关键词查询方法（`findByNameContainingOrDescriptionContaining` 等）

## Capabilities

### New Capabilities

- `semantic-search`: 语义搜索能力——RRF 混合检索（向量 + 关键词）、统一搜索 API、搜索建议 API、搜索结果页、HeroSlot 搜索框激活

### Modified Capabilities

- `homepage-hero`: HeroSlot 搜索框从纯装饰升级为功能性交互组件（建议 dropdown + 提交跳转）

## Impact

- **后端新增文件**：`SearchController`、`HybridSearchService`、`KeywordSearchService`、`SearchResponse` / `SearchResultItem` DTO、`SearchSuggestResponse` DTO
- **后端修改文件**：`SpotRepository`（新增 LIKE 查询方法）、`PostRepository`（新增 LIKE 查询方法）、`CityRepository`（新增 LIKE 查询方法）、`SecurityConfig`（放行 `/api/search/**`）
- **复用已有基础设施**：`KnowledgeSearchService`（向量检索）、Chroma VectorStore、DashScope embedding-v3、`KnowledgeBuilderService` ETL（零改动，数据已索引）
- **前端新增文件**：`app/search/page.tsx`（结果页）、`app/search/_components/SearchResults.tsx`、`app/search/_components/SearchResultCard.tsx`、`app/_components/SearchSuggest.tsx`、`lib/api/search.ts`
- **前端修改文件**：`app/regions/HeroSlot.tsx`（激活搜索框）、`app/regions/hero.data.ts`（无需改动，placeholder 已有）
- **API**：新增 `GET /api/search` 和 `GET /api/search/suggest` 两个公开端点（无需认证）
- **数据库**：无 schema 变更，仅新增 Repository 查询方法
- **外部依赖**：无新增依赖，复用现有 Spring AI + Chroma + MySQL
- **测试**：测试环境使用 SimpleVectorStore + H2 LIKE，与现有测试隔离策略一致
