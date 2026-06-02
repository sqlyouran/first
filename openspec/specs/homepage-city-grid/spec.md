# homepage-city-grid Spec

> 首页骨架中 `city-grid` region 的内容契约。
> 本 spec 定义 `frontend/app/regions/CityGridSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：至少渲染 1 个带 `href` 与非空 label 的 `<a>` 子节点；数据来自硬编码 TS 常量数组；占位链接严格为 `#`；不破坏 BFF 边界。视觉布局、城市图片、真实业务路由均由后续独立 capability 承载。

## Requirements

### Requirement: city-grid region 必须渲染至少 1 个 `<a>` 子节点

`CityGridSlot` SHALL render a single root `<section data-region="city-grid">` containing at least one `<a>` element as a child node. Each `<a>` MUST carry a non-empty `textContent` (the city label) and a `href` attribute.

#### Scenario: city-grid region 容器仍存在

- **GIVEN** `CityGridSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** `container.querySelector('[data-region="city-grid"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 至少 1 个 `<a>` 子节点

- **WHEN** RTL 渲染 `<CityGridSlot />` 并查 `container.querySelectorAll('section[data-region="city-grid"] a')`
- **THEN** NodeList 长度 `>= 1`
- **AND** 每个 `<a>` 的 `textContent.trim().length > 0`

---

### Requirement: city-grid 数据来源必须为硬编码 TS 常量

The list of city-grid items SHALL be sourced from a hard-coded TypeScript constant array at `frontend/app/regions/cityGrid.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\\(|import.*lib/backend" frontend/app/regions/CityGridSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 数组

- **GIVEN** `frontend/app/regions/cityGrid.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `readonly CityGridItem[]`，且 `length >= 1`
- **AND** 每个元素同时具备字符串 `label` 和字符串 `href` 字段

---

### Requirement: 占位链接必须为严格 `#`

Every city-grid item's `href` SHALL be exactly the string `"#"`. This change MUST NOT introduce any business route path (e.g., `/cities/beijing`).

#### Scenario: 所有 href 严格等于 `#`

- **WHEN** RTL 渲染 `<CityGridSlot />` 并 map 出每个 `<a>` 的 `href` 属性
- **THEN** 所有元素 `=== "#"`

#### Scenario: 未引入业务路由文件

- **WHEN** `find frontend/app -mindepth 2 -name 'page.tsx'`（排除 `app/page.tsx`）
- **THEN** 输出为空

---

### Requirement: BFF 边界守护必须保持

This change SHALL NOT introduce `app/api/**/route.ts` files, MUST NOT modify `lib/backend.ts`, and MUST NOT introduce new npm dependencies.

#### Scenario: 仍无 Route Handler

- **WHEN** `find frontend/app -name 'route.ts' -o -name 'route.tsx'`
- **THEN** 输出为空

#### Scenario: lib/backend 未变更

- **WHEN** 比对 `git show main:frontend/lib/backend.ts` 与本变更工作树同文件
- **THEN** 内容字节级一致

#### Scenario: package.json 依赖未变

- **WHEN** 比对本变更前后的 `frontend/package.json` 的 `dependencies` 与 `devDependencies` 字段
- **THEN** 两份列表完全一致

---

### Requirement: City-grid 容器必须渲染 8 张带季节标签的城市卡片（homepage-visual-v1 新增）

`CityGridSlot` SHALL render 8 city cards in a responsive grid (2 cols mobile, 4 cols desktop). Each card MUST contain a background image (picsum.photos), English city name, Chinese location subtitle, description, and a Badge showing best season.

#### Scenario: City-grid 渲染 8 张卡片

- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** `container.querySelectorAll('[data-region="city-grid"] a')` 长度恰好为 `8`

#### Scenario: 每张卡片含图片、标题、Badge

- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** 每张卡片内含一个 `aspect-[4/3]` 的图片容器（`bg-cover` class）
- **AND** 每张卡片含 `<h3>` 标签（城市名）
- **AND** 每张卡片含一个 Badge 组件（季节标签）

#### Scenario: 响应式布局

- **WHEN** 检视 `CityGridSlot.tsx`
- **THEN** grid 容器 className 含 `grid-cols-2` 和 `md:grid-cols-4`

---

### Requirement: City-grid 数据来源必须为 8 个含季节标签的城市（homepage-visual-v1 新增）

The city-grid content SHALL be sourced from `frontend/app/regions/cityGrid.data.ts` with 8 items, each containing `label` (English name), `labelZh` (Chinese name), `href`, `image` (picsum.photos URL), `description`, and `bestSeason`.

#### Scenario: data 文件包含 8 个城市

- **WHEN** 静态 import `cityGrid.data.ts` 的 default export
- **THEN** 数组长度恰好为 `8`

#### Scenario: 每个城市含季节字段

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `bestSeason` 字段，值为 `'Spring'` / `'Summer'` / `'Autumn'` / `'Winter'` 之一

#### Scenario: 每个城市含图片 URL

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `image` 字段，以 `https://picsum.photos/` 开头
