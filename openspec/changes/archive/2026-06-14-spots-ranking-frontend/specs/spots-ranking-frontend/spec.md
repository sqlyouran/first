## ADDED Requirements

### Requirement: 排行榜页面路由存在

The system SHALL provide a route at `/spots/ranking` that renders the spots ranking page. The page component SHALL be located at `frontend/app/spots/ranking/page.tsx` and MUST be a `"use client"` component (requires Tab interaction state).

#### Scenario: 排行榜页面可访问

- **WHEN** 用户导航至 `/spots/ranking`
- **THEN** 页面正常渲染，不出现 404

#### Scenario: 页面含"景点排行榜"标题

- **WHEN** 渲染排行榜页面
- **THEN** 页面包含文本"景点排行榜"

---

### Requirement: 三 Tab 切换（热门/高分/收藏）

The ranking page SHALL render exactly 3 tab buttons: 热门 (heat), 高分 (rating), 收藏 (bookmark). The default active tab SHALL be 热门 (heat). Clicking a tab SHALL switch the displayed ranking list to the corresponding type.

#### Scenario: 默认展示热门 Tab

- **WHEN** 用户首次访问 `/spots/ranking`
- **THEN** 热门 Tab 处于激活状态
- **AND** 调用 `GET /api/spots/ranking?type=heat&top=50`

#### Scenario: 点击高分 Tab 切换列表

- **WHEN** 用户点击"高分"Tab
- **THEN** 高分 Tab 变为激活状态
- **AND** 页面发起 `GET /api/spots/ranking?type=rating&top=50` 请求（若无缓存）

#### Scenario: 点击收藏 Tab 切换列表

- **WHEN** 用户点击"收藏"Tab
- **THEN** 收藏 Tab 变为激活状态
- **AND** 页面发起 `GET /api/spots/ranking?type=bookmark&top=50` 请求（若无缓存）

---

### Requirement: Tab 数据按需请求 + 本地缓存

The ranking page SHALL cache fetched ranking data per tab type in component state. When switching to a tab whose data is already cached, the page SHALL render the cached data immediately WITHOUT making a new API request.

#### Scenario: 切回已请求过的 Tab 不重复请求

- **GIVEN** 用户已访问过热榜（heat）并切换到高分榜（rating）
- **WHEN** 用户再次点击"热门"Tab
- **THEN** 页面立即展示已缓存的热榜数据
- **AND** 不发起新的 heat 类型 API 请求

#### Scenario: 首次切换到未请求过的 Tab 发起请求

- **GIVEN** 用户仅访问过热榜（heat）
- **WHEN** 用户首次点击"收藏"Tab
- **THEN** 页面发起 `GET /api/spots/ranking?type=bookmark&top=50` 请求
- **AND** 展示 loading 状态直至数据返回

---

### Requirement: 排行榜列表展示 top=50

The ranking page SHALL request and display up to 50 ranking items (`top=50`). Each item SHALL display: rank number, cover image, spot name (Chinese), city name, and all three metrics (rating, view count, bookmark count).

#### Scenario: 请求 top=50 数据

- **WHEN** 排行榜页面发起 API 请求
- **THEN** 请求参数包含 `top=50`

#### Scenario: 每项展示排名 + 封面 + 名称 + 城市 + 指标

- **WHEN** 排行榜列表渲染完成
- **THEN** 每个列表项包含排名序号、封面图（`cover_image`）、景点中文名（`name_zh`）、城市名（`city_name`）
- **AND** 同时展示评分（`rating`）、浏览量（`view_count`）、收藏数（`bookmark_count`）

---

### Requirement: 前三名金银铜色高亮

The top 3 ranked items SHALL be visually distinguished with medal icons and rank number colors: 1st place gold (`text-yellow-500` + Trophy icon), 2nd place silver (`text-slate-400` + Medal icon), 3rd place bronze (`text-amber-700` + Medal icon). Items ranked 4th and below SHALL use default text color with plain number.

#### Scenario: 第一名显示金牌样式

- **WHEN** 排行榜渲染完成
- **THEN** 排名第 1 的项序号区域使用金色（`text-yellow-500`）并展示 Trophy 图标

#### Scenario: 第二名显示银牌样式

- **WHEN** 排行榜渲染完成
- **THEN** 排名第 2 的项序号区域使用银色（`text-slate-400`）并展示 Medal 图标

#### Scenario: 第三名显示铜牌样式

- **WHEN** 排行榜渲染完成
- **THEN** 排名第 3 的项序号区域使用铜色（`text-amber-700`）并展示 Medal 图标

#### Scenario: 第 4 名及以后使用默认样式

- **WHEN** 排行榜渲染完成
- **THEN** 排名第 4 及之后的项序号使用默认文本色（`text-slate-600`），无奖牌图标

---

### Requirement: 当前排序维度高亮

Each ranking item displays all three metrics (rating, view count, bookmark count). The metric corresponding to the current active tab SHALL be visually emphasized (bold + brand color `text-blue-700`), while other metrics use muted style (`text-slate-500`).

#### Scenario: 热榜中浏览量高亮

- **WHEN** 热门 Tab 激活
- **THEN** 每项的浏览量（view_count）数字使用 `font-semibold text-blue-700`
- **AND** 评分和收藏数使用 `text-slate-500`

#### Scenario: 高分榜中评分高亮

- **WHEN** 高分 Tab 激活
- **THEN** 每项的评分（rating）使用 `font-semibold text-blue-700`
- **AND** 浏览量和收藏数使用 `text-slate-500`

#### Scenario: 收藏榜中收藏数高亮

- **WHEN** 收藏 Tab 激活
- **THEN** 每项的收藏数（bookmark_count）使用 `font-semibold text-blue-700`
- **AND** 评分和浏览量使用 `text-slate-500`

---

### Requirement: 点击列表项跳转景点详情

Each ranking list item SHALL be a clickable link (`<a>` or `<Link>`) that navigates to the spot detail page at `/spots/{slug}`.

#### Scenario: 点击景点跳转详情页

- **WHEN** 用户点击排行榜中某个景点项
- **THEN** 导航至 `/spots/{slug}`（使用该景点的 slug）

#### Scenario: 列表项使用 Link 组件

- **WHEN** 检视排行榜页面源码
- **THEN** 每个列表项使用 Next.js `<Link>` 组件（非 `<a>` 标签），确保客户端导航

---

### Requirement: 四态覆盖（Loading / Content / Empty / Error）

The ranking page SHALL cover 4 UI states: Loading (Skeleton placeholders), Content (ranking list), Empty (centered message + icon), Error (error message + retry button).

#### Scenario: Loading 状态展示骨架屏

- **WHEN** 排行榜数据加载中
- **THEN** 页面展示 Skeleton 占位（至少 5 个列表项骨架）

#### Scenario: Empty 状态展示空态提示

- **WHEN** API 返回空列表（`items.length === 0`）
- **THEN** 页面展示"暂无排行数据"文案 + 图标

#### Scenario: Error 状态展示错误提示和重试

- **WHEN** API 请求失败（network error 或 server error）
- **THEN** 页面展示错误描述文案
- **AND** 展示"重试"按钮，点击后重新发起请求

---

### Requirement: fetchRanking API 封装

The `frontend/lib/api/spots.ts` module SHALL export a `fetchRanking(type, top?)` function that calls `GET /api/spots/ranking` and returns `ApiResponse<RankingData>`. The function SHALL handle network errors and server errors per the existing API client conventions.

#### Scenario: 成功请求返回 200

- **WHEN** 调用 `fetchRanking("heat", 50)` 且后端返回 200
- **THEN** 返回 `{ status: 200, data: { type, items, request_id } }`

#### Scenario: 服务端错误返回 5xx

- **WHEN** 调用 `fetchRanking("rating")` 且后端返回 500
- **THEN** 返回 `{ status: 500, error: { error_code: "server_error", ... } }`

#### Scenario: 网络错误

- **WHEN** 调用 `fetchRanking("bookmark")` 且 fetch 抛出网络异常
- **THEN** 返回 `{ status: 0, error: { error_code: "network_error", ... } }`

---

### Requirement: 页面遵循全局样式规范

The ranking page SHALL follow the global page structure: `min-h-screen bg-gradient-to-b from-slate-50 to-white` background, `mx-auto max-w-5xl` container, `px-8 py-16 sm:px-12 lg:px-16` padding. Page header SHALL include back navigation link to `/spots`.

#### Scenario: 页面背景与容器符合规范

- **WHEN** 检视排行榜页面根元素
- **THEN** 包含 `min-h-screen bg-gradient-to-b from-slate-50 to-white` class
- **AND** 内容容器包含 `max-w-5xl` class

#### Scenario: 页面含返回景点列表的导航链接

- **WHEN** 渲染排行榜页面
- **THEN** 页面包含指向 `/spots` 的返回链接（含 ArrowLeft 图标）
