# homepage-hot-spots Spec

> 首页骨架中 `hot-spots` region 的内容契约。
> 本 spec 定义 `frontend/app/regions/HotSpotsSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：渲染恰好 1 个 `<section data-region="hot-spots">` 根容器 + 至少 1 个 `<a>` 子节点，所有 href 为占位 `"#"`，数据来源为硬编码 TS 常量 `frontend/app/regions/hotSpots.data.ts`。本 spec 不引入任何业务路由 / 后端调用 / npm 依赖。

## Requirements

### Requirement: hot-spots region 必须渲染至少 1 个 `<a>` 子节点

`HotSpotsSlot` SHALL render a single root `<section data-region="hot-spots">` containing at least one `<a>` element as a child node. Each `<a>` MUST carry a non-empty `textContent` (the spot name) and a `href` attribute.

#### Scenario: hot-spots region 容器仍存在

- **GIVEN** `HotSpotsSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** `container.querySelector('[data-region="hot-spots"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 至少 1 个 `<a>` 子节点

- **WHEN** RTL 渲染 `<HotSpotsSlot />` 并查 `container.querySelectorAll('section[data-region="hot-spots"] a')`
- **THEN** NodeList 长度 `>= 1`
- **AND** 每个 `<a>` 的 `textContent.trim().length > 0`

---

### Requirement: hot-spots 数据来源必须为硬编码 TS 常量

The list of hot-spots items SHALL be sourced from a hard-coded TypeScript constant array at `frontend/app/regions/hotSpots.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/HotSpotsSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 数组

- **GIVEN** `frontend/app/regions/hotSpots.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `readonly HotSpotItem[]`，且 `length >= 1`
- **AND** 每个元素同时具备字符串 `label` 和字符串 `href` 字段

---

### Requirement: 占位链接必须为严格 `#`

Every hot-spots item's `href` SHALL be exactly the string `"#"`. This change MUST NOT introduce any business route path (e.g., `/spots/123`).

#### Scenario: 所有 href 严格等于 `#`

- **WHEN** RTL 渲染 `<HotSpotsSlot />` 并 map 出每个 `<a>` 的 `href` 属性
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

### Requirement: Hot-spots 容器必须渲染横向 carousel + 标签（homepage-visual-v1 新增）

`HotSpotsSlot` SHALL render 8 spot cards in a horizontal carousel (overflow-x-auto on mobile, 4-col grid on desktop). Each card MUST contain a background image (picsum.photos), English name, Chinese name subtitle, and tag Badges.

#### Scenario: Hot-spots 渲染 8 张卡片

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** `container.querySelectorAll('[data-region="hot-spots"] a')` 长度恰好为 `8`

#### Scenario: 每张卡片含图片、标题、标签

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** 每张卡片内含图片容器（`aspect-[4/3]` + `bg-cover` class）
- **AND** 每张卡片含 `<h3>` 标签（景点名）
- **AND** 每张卡片含至少 1 个 Badge 组件（标签）

#### Scenario: carousel 横向滚动（mobile）

- **WHEN** 检视 `HotSpotsSlot.tsx`
- **THEN** 外层容器 className 含 `overflow-x-auto` 和 `snap-x`
- **AND** 在 desktop（≥ 768px）使用 `md:grid md:grid-cols-4` 替代滚动

---

### Requirement: Hot-spots 数据来源必须为 8 个含标签的景点（homepage-visual-v1 新增）

The hot-spots content SHALL be sourced from `frontend/app/regions/hotSpots.data.ts` with 8 items, each containing `name` (English), `nameZh` (Chinese), `href`, `image` (picsum.photos URL), and `tags` (string array).

#### Scenario: data 文件包含 8 个景点

- **WHEN** 静态 import `hotSpots.data.ts` 的 default export
- **THEN** 数组长度恰好为 `8`

#### Scenario: 每个景点含标签数组

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `tags` 字段，为非空字符串数组（如 `["Nature", "Thrill"]`）

#### Scenario: 每个景点含图片 URL

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `image` 字段，以 `https://picsum.photos/` 开头
