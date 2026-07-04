## 1. 配置与安全

- [x] 1.1 `application.yml` 新增 `app.search` 配置节（rrf-k / vector-top-k / keyword-top-k / suggest-top-k / similarity-threshold）
- [x] 1.2 `SecurityConfig.java` 放行 `/api/search/**` 端点（已有 anyRequest().permitAll()）
- [x] 1.3 `test/resources/application.yml` 新增 `app.search` 测试配置（RRF 参数可覆盖）

## 2. Repository 关键词查询

- [x] 2.1 `SpotRepository` 新增 `findByNameContainingIgnoreCaseOrNameZhContainingIgnoreCaseAndDeletedFalseAndStatus` 方法
- [x] 2.2 `PostRepository` 新增 `findByTitleContainingIgnoreCaseOrTagsContainingIgnoreCaseAndDeletedFalseAndStatus` 方法
- [x] 2.3 `CityRepository` 新增 `findByNameContainingIgnoreCaseOrNameZhContainingIgnoreCaseAndDeletedFalse` 方法

## 3. KeywordSearchService (TDD)

- [x] 3.1 RED: `KeywordSearchServiceTest` — search() 返回按打分排序的结果列表
- [x] 3.2 RED: `KeywordSearchServiceTest` — 搜索仅包含已发布的 Spot/Post
- [x] 3.3 RED: `KeywordSearchServiceTest` — 查询为空时返回空列表
- [x] 3.4 RED: `KeywordSearchServiceTest` — 打分规则：name=3, tags=2, desc=1，同实体多字段命中分数累加
- [x] 3.5 GREEN: 创建 `KeywordSearchService.java` — 注入 Repository + 配置参数，实现 search() + scoreKeyword()
- [x] 3.6 GREEN: 全量测试通过 `mvn -f backend/pom.xml test`

## 4. Response DTO

- [x] 4.1 创建 `SearchResultItem.java`（record：type / id / slug / name / name_zh / summary / score）+ `@JsonProperty` snake_case
- [x] 4.2 创建 `SearchResponse.java`（extends BaseResponse：items / spots_count / posts_count / cities_count）
- [x] 4.3 创建 `SearchSuggestItem.java`（record：type / slug / name / name_zh）
- [x] 4.4 创建 `SearchSuggestResponse.java`（extends BaseResponse：items）

## 5. HybridSearchService (TDD)

- [x] 5.1 RED: `HybridSearchServiceTest` — search() 调用 KnowledgeSearchService + KeywordSearchService，RRF 融合后按分数降序返回
- [x] 5.2 RED: `HybridSearchServiceTest` — RRF k=60 公式验证（两路 rank 位置 → 分数计算正确）
- [x] 5.3 RED: `HybridSearchServiceTest` — 按 slug 去重，同实体不重复出现
- [x] 5.4 RED: `HybridSearchServiceTest` — 按 entity_type 分组计数（spots_count / posts_count / cities_count）
- [x] 5.5 RED: `HybridSearchServiceTest` — Chroma 不可用时降级为纯关键词检索
- [x] 5.6 RED: `HybridSearchServiceTest` — type 过滤（仅返回指定类型）
- [x] 5.7 GREEN: 创建 `HybridSearchService.java` — 注入 KnowledgeSearchService + KeywordSearchService + 配置，实现 rrfMerge() + deduplicate() + groupBy()
- [x] 5.8 GREEN: 全量测试通过

## 6. SearchController (TDD)

- [x] 6.1 RED: `SearchControllerTest` — GET /api/search?q=长城 返回 200 + SearchResponse
- [x] 6.2 RED: `SearchControllerTest` — GET /api/search（无 q）返回 422
- [x] 6.3 RED: `SearchControllerTest` — GET /api/search?q=x&type=spot 按类型过滤
- [x] 6.4 RED: `SearchControllerTest` — GET /api/search/suggest?q=长城 返回 200 + SearchSuggestResponse
- [x] 6.5 RED: `SearchControllerTest` — GET /api/search/suggest?q= 返回空列表
- [x] 6.6 GREEN: 创建 `SearchController.java` — 参数校验 + 委托 HybridSearchService / KeywordSearchService
- [x] 6.7 GREEN: 全量测试通过

## 7. 前端 API 客户端

- [x] 7.1 创建 `lib/api/search.ts` — `search(query, type?, city?)` 函数，返回 `ApiResponse<SearchResponse>`
- [x] 7.2 `lib/api/search.ts` — `suggest(query)` 函数，返回 `ApiResponse<SearchSuggestResponse>`
- [x] 7.3 RED: `lib/api/search.test.ts` — 测试 search() 和 suggest() 的请求构造 + 错误处理
- [x] 7.4 GREEN: `npm test` 通过

## 8. SearchSuggest 组件 + HeroSlot 修改

- [x] 8.1 创建 `app/_components/SearchSuggest.tsx`（"use client"）— 输入框 + debounce 300ms suggest + dropdown + Enter 提交跳转 /search
- [x] 8.2 RED: `app/_components/SearchSuggest.test.tsx` — 输入触发 suggest 请求、显示 dropdown、Enter 跳转
- [x] 8.3 GREEN: `npm test` 通过
- [x] 8.4 修改 `app/regions/HeroSlot.tsx` — 搜索 Input/Button 替换为 `<SearchSuggest placeholder={hero.searchPlaceholder} />`
- [x] 8.5 修改 `app/regions/HeroSlot.test.tsx` — 更新测试验证功能性搜索组件存在
- [x] 8.6 `npm test` 全绿

## 9. 搜索结果页

- [x] 9.1 创建 `app/search/page.tsx`（"use client"）— 搜索框 + Tab（全部/景点/帖子/城市）+ 结果列表
- [x] 9.2 创建 `app/search/_components/SearchResults.tsx` — 按 type 渲染 SpotCard / PostCard / CityCard
- [x] 9.3 RED: `app/search/page.test.tsx` — 渲染搜索框 + Tab + 空状态 + 加载骨架屏
- [x] 9.4 GREEN: `npm test` 通过
- [x] 9.5 实现 Loading / Error / Empty 三态覆盖（Skeleton / 错误提示 / 空状态组件）

## 10. 集成验证

- [x] 10.1 `mvn -f backend/pom.xml test` 全绿
- [x] 10.2 `cd frontend && npm test` 全绿
- [x] 10.3 `cd frontend && npm run build` 通过
- [x] 10.4 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空（BFF 边界）
- [x] 10.5 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`（BFF 边界）
- [x] 10.6 父仓 `git add frontend` + `git add backend` 更新子模块指针

## 11. 归档

- [x] 11.1 父仓提交：`feat: semantic-search — proposal + design + specs + tasks`
- [x] 11.2 等待实现完成后执行 `/opsx:archive` 归档
