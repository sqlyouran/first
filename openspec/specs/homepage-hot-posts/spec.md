# homepage-hot-posts Spec

> 首页骨架中 `hot-posts` region 的内容契约。
> 本 spec 定义 `frontend/app/regions/HotPostsSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：渲染恰好 1 个 `<section data-region="hot-posts">` 根容器 + 至少 1 个 `<a>` 子节点，所有 href 为占位 `"#"`，数据来源为硬编码 TS 常量 `frontend/app/regions/hotPosts.data.ts`。本 spec 不引入任何业务路由 / 后端调用 / npm 依赖。

## Requirements

### Requirement: hot-posts region 必须渲染至少 1 个 `<a>` 子节点

`HotPostsSlot` SHALL render a single root `<section data-region="hot-posts">` containing at least one `<a>` element as a child node. Each `<a>` MUST carry a non-empty `textContent` (the post title) and a `href` attribute.

#### Scenario: hot-posts region 容器仍存在

- **GIVEN** `HotPostsSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<HotPostsSlot />`
- **THEN** `container.querySelector('[data-region="hot-posts"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 至少 1 个 `<a>` 子节点

- **WHEN** RTL 渲染 `<HotPostsSlot />` 并查 `container.querySelectorAll('section[data-region="hot-posts"] a')`
- **THEN** NodeList 长度 `>= 1`
- **AND** 每个 `<a>` 的 `textContent.trim().length > 0`

---

### Requirement: hot-posts 数据来源必须为硬编码 TS 常量

The list of hot-posts items SHALL be sourced from a hard-coded TypeScript constant array at `frontend/app/regions/hotPosts.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/HotPostsSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 数组

- **GIVEN** `frontend/app/regions/hotPosts.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `readonly HotPostItem[]`，且 `length >= 1`
- **AND** 每个元素同时具备字符串 `label` 和字符串 `href` 字段

---

### Requirement: 占位链接必须为严格 `#`

Every hot-posts item's `href` SHALL be exactly the string `"#"`. This change MUST NOT introduce any business route path (e.g., `/posts/123`).

#### Scenario: 所有 href 严格等于 `#`

- **WHEN** RTL 渲染 `<HotPostsSlot />` 并 map 出每个 `<a>` 的 `href` 属性
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
