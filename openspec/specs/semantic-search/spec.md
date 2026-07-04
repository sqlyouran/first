# semantic-search — 语义搜索能力

## ADDED Requirements

### Requirement: 统一搜索 API 端点

系统 SHALL 暴露 `GET /api/search` 端点接受自然语言查询，返回跨类型（spots / posts / cities）的混合检索结果。该端点 SHALL 为公开端点（无需认证）。

#### Scenario: 成功搜索返回混合结果

- **WHEN** 客户端发送 `GET /api/search?q=长城&size=20`
- **THEN** 系统返回 200
- **AND** 响应体包含 `{ request_id, items: [...], spots_count, posts_count, cities_count }`
- **AND** `items` 数组中每个元素包含 `{ type, id, slug, name, name_zh, summary, score }`
- **AND** `items` 按 RRF 分数降序排列

#### Scenario: 按类型过滤搜索结果

- **WHEN** 客户端发送 `GET /api/search?q=长城&type=spot`
- **THEN** 系统返回 200
- **AND** `items` 中仅包含 `type: "spot"` 的结果
- **AND** `spots_count` 等于 `items.length`
- **AND** `posts_count` 和 `cities_count` 均为 0

#### Scenario: 按城市过滤搜索结果

- **WHEN** 客户端发送 `GET /api/search?q=heritage&city=beijing`
- **THEN** 系统返回 200
- **AND** 向量检索和关键词检索均限定在北京范围

#### Scenario: 查询为空返回空结果

- **WHEN** 客户端发送 `GET /api/search?q=`（空查询）
- **THEN** 系统返回 200
- **AND** `items` 为空数组
- **AND** 各 count 字段均为 0

#### Scenario: 缺少 q 参数返回 422

- **WHEN** 客户端发送 `GET /api/search`（无 q 参数）
- **THEN** 系统返回 422
- **AND** 响应体包含 `error_code: "validation_error"`

---

### Requirement: 搜索建议 API 端点

系统 SHALL 暴露 `GET /api/search/suggest` 端点接受关键词查询，仅做 MySQL LIKE 检索返回 top-5 快速建议。该端点 SHALL 不调用 embedding API，延迟 < 50ms。

#### Scenario: 成功搜索建议

- **WHEN** 客户端发送 `GET /api/search/suggest?q=长城`
- **THEN** 系统返回 200
- **AND** 响应体包含 `{ request_id, items: [...] }`
- **AND** `items` 最多 5 条
- **AND** 每条包含 `{ type, slug, name, name_zh }`
- **AND** 不调用 DashScope embedding API

#### Scenario: 搜索建议为空查询

- **WHEN** 客户端发送 `GET /api/search/suggest?q=xyznotexist`
- **THEN** 系统返回 200
- **AND** `items` 为空数组

#### Scenario: 搜索建议查询为空

- **WHEN** 客户端发送 `GET /api/search/suggest?q=`
- **THEN** 系统返回 200
- **AND** `items` 为空数组

---

### Requirement: RRF 混合检索（向量 + 关键词）

系统 SHALL 通过 Reciprocal Rank Fusion (RRF, k=60) 融合向量检索结果与关键词检索结果，产出统一排名。

#### Scenario: 混合检索融合排序

- **GIVEN** 向量检索返回 [A(rank1), B(rank2), C(rank3)]
- **GIVEN** 关键词检索返回 [B(rank1), A(rank2), D(rank3)]
- **WHEN** 执行 RRF 融合
- **THEN** A 的 RRF 分数 = 1/(60+1) + 1/(60+2) = 0.03252
- **AND** B 的 RRF 分数 = 1/(60+2) + 1/(60+1) = 0.03252
- **AND** C 的 RRF 分数 = 1/(60+3) = 0.01587
- **AND** D 的 RRF 分数 = 1/(60+3) = 0.01587

#### Scenario: 按 slug 去重

- **GIVEN** 向量检索和关键词检索同时返回同一景点（slug 相同）
- **WHEN** 执行 RRF 融合
- **THEN** 该景点在最终结果中仅出现一次
- **AND** 分数为两路 RRF 分数之和

#### Scenario: 按 entity_type 分组计数

- **GIVEN** RRF 融合后包含 3 个 spot + 2 个 post + 1 个 city
- **WHEN** 构造 SearchResponse
- **THEN** `spots_count = 3`, `posts_count = 2`, `cities_count = 1`

---

### Requirement: 关键词检索与自定义打分

系统 SHALL 通过 MySQL LIKE 查询 Spot / Post / City 实体，基于匹配字段进行自定义打分以产出排名供 RRF 融合。

#### Scenario: Spot 关键词匹配打分

- **GIVEN** 查询词为 "Great Wall"
- **GIVEN** 数据库中存在 SpotEntity name="Great Wall", description="Ancient structure"
- **WHEN** KeywordSearchService 执行关键词检索
- **THEN** 该 Spot 的 name 字段命中 → 得分 3
- **AND** description 字段未包含查询词 → 不加分
- **AND** 总分为 3，排名靠前

#### Scenario: Post 关键词匹配打分

- **GIVEN** 查询词为 "Beijing"
- **GIVEN** PostEntity title="A Week in Beijing", tags=["beijing", "heritage"], content="Beijing is great..."
- **WHEN** KeywordSearchService 执行关键词检索
- **THEN** title 命中 → 得分 3
- **AND** tags 命中 → 得分 2
- **AND** content 命中 → 得分 1
- **AND** 总分为 6

#### Scenario: 仅检索已发布内容

- **GIVEN** PostEntity status=DRAFT
- **WHEN** 执行关键词检索
- **THEN** 该 Post 不出现在关键词结果中

#### Scenario: 关键词检索返回按分数降序排列

- **GIVEN** 查询词为 "heritage"
- **GIVEN** Spot A (name 命中, score=3), Spot B (description 命中, score=1)
- **WHEN** KeywordSearchService 返回结果
- **THEN** Spot A 排在 Spot B 之前

---

### Requirement: 向量检索复用

HybridSearchService SHALL 复用现有 `KnowledgeSearchService.search()` 方法执行向量检索，零改动。

#### Scenario: 向量检索调用 KnowledgeSearchService

- **WHEN** HybridSearchService 执行向量检索
- **THEN** 调用 `knowledgeSearchService.search(query)` 获取 Top-K 结果
- **AND** 结果按相似度降序排列
- **AND** 每条结果包含 metadata（entity_type, slug, name 等）

#### Scenario: Chroma 不可用时降级为纯关键词检索

- **GIVEN** Chroma 向量库不可用
- **WHEN** HybridSearchService 执行混合检索
- **THEN** 向量检索 try-catch 捕获异常
- **AND** 日志记录降级警告
- **AND** 仅使用关键词检索结果进行 RRF 融合
- **AND** 最终结果仍正常返回

---

### Requirement: 搜索结果页

系统 SHALL 提供 `/search?q=...` 搜索结果页，展示混合检索结果并按类型分组。

#### Scenario: 搜索结果页渲染

- **WHEN** 用户导航到 `/search?q=长城`
- **THEN** 页面渲染搜索框（回显查询词）+ Tab 栏（全部 / 景点 / 帖子 / 城市）+ 结果列表
- **AND** 结果列表使用 SpotCard（景点类型）和 PostCard（帖子类型）卡片

#### Scenario: Tab 切换过滤

- **GIVEN** 搜索结果显示 3 个景点 + 2 个帖子 + 1 个城市
- **WHEN** 用户点击"景点" Tab
- **THEN** 仅显示 3 个景点卡片

#### Scenario: 空搜索结果显示空状态

- **WHEN** 搜索返回 0 条结果
- **THEN** 页面显示空状态组件（居中图标 + "未找到相关结果" 提示 + 建议换关键词）

#### Scenario: 搜索加载状态

- **WHEN** 搜索请求发出但尚未返回
- **THEN** 页面显示 Skeleton 骨架屏加载状态

---

### Requirement: 搜索建议组件

HeroSlot 搜索框 SHALL 在用户输入时展示实时搜索建议 dropdown。

#### Scenario: 输入触发搜索建议

- **GIVEN** HeroSlot 搜索框已获得焦点
- **WHEN** 用户输入查询词
- **THEN** 等待 300ms debounce 后发送 `GET /api/search/suggest?q=...`
- **AND** 显示 dropdown 面板，列出最多 5 条建议
- **AND** 每条建议显示图标（按类型区分）+ 名称

#### Scenario: 点击建议跳转详情

- **GIVEN** 搜索建议 dropdown 显示结果
- **WHEN** 用户点击某条建议
- **THEN** 关闭 dropdown
- **AND** 导航到对应详情页（`/spots/{slug}` 或 `/posts/{slug}`）

#### Scenario: 提交表单跳转搜索页

- **GIVEN** 搜索框中有输入内容
- **WHEN** 用户按 Enter 或点击搜索按钮
- **THEN** 导航到 `/search?q={输入内容}`

#### Scenario: 清空输入关闭 dropdown

- **GIVEN** dropdown 正在显示
- **WHEN** 用户清空搜索框
- **THEN** dropdown 关闭
- **AND** 不发送请求
