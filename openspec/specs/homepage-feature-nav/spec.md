# homepage-feature-nav Spec

> 首页骨架中 `feature-nav` region 的内容契约。本 spec 定义 `frontend/app/regions/FeatureNavSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：至少渲染 1 个带 `href` 与非空 label 的 `<a>` 子节点；数据来自硬编码 TS 常量；占位链接严格为 `#`；不破坏 BFF 边界。视觉设计、icon、真实数据、业务路由均由后续独立 capability 承载。

## Purpose

`FeatureNavSlot` 渲染首页 feature-nav region：一组指向主要内容页的功能入口卡片（Cities / Stories / Hidden Spots）与 "Plan with AI" 面板触发按钮。数据来自硬编码 TS 常量，不依赖后端。
## Requirements
### Requirement: feature-nav region 必须渲染至少 1 个 `<a>` 子节点

`FeatureNavSlot` SHALL render a single root `<section data-region="feature-nav">` containing exactly 4 feature items. The first 3 items (Cities / Stories / Hidden Spots) MUST each be an `<a>` element carrying a non-empty `textContent` (the item label) and a real business-route `href`. The 4th item ("Plan with AI") MUST be a `<button>` element (not an `<a>`) that triggers the global AI panel. Every item MUST carry a non-empty label.

#### Scenario: feature-nav region 容器仍存在

- **GIVEN** `FeatureNavSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `container.querySelector('[data-region="feature-nav"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 前 3 项为链接、第 4 项为按钮

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `section[data-region="feature-nav"] a` NodeList 长度为 `3`
- **AND** `section[data-region="feature-nav"] button` NodeList 长度为 `1`
- **AND** 4 个 item 的 label 依次为 `["Cities", "Stories", "Hidden Spots", "Plan with AI"]`
- **AND** 每个 item 的 `textContent.trim().length > 0`

---

### Requirement: feature-nav 数据来源必须为硬编码 TS 常量

The list of feature-nav items SHALL be sourced from a hard-coded TypeScript constant array at `frontend/app/regions/featureNav.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\\(|import.*lib/backend" frontend/app/regions/FeatureNavSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 数组

- **GIVEN** `frontend/app/regions/featureNav.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `readonly FeatureNavItem[]`，且 `length >= 1`
- **AND** 每个元素同时具备字符串 `label` 和字符串 `href` 字段

---

### Requirement: 占位链接必须为严格 `#`

The first 3 feature-nav links SHALL point to real, existing business routes: Cities → `/spots`, Stories → `/posts`, Hidden Spots → `/spots/ranking`. No feature-nav item's `href` may be `"#"`. This change MUST NOT introduce a link to a non-existent route.

> **homepage-nav-wiring MODIFIED**：占位阶段结束，`href === "#"` 契约作废。前 3 张功能卡改为指向已存在的真实业务列表页；第 4 张 "Plan with AI" 不再是链接。

#### Scenario: 前 3 张卡指向真实路由

- **WHEN** RTL 渲染 `<FeatureNavSlot />` 并 map 出每个 `<a>` 的 `href` 属性
- **THEN** href 集合为 `["/spots", "/posts", "/spots/ranking"]`
- **AND** 没有任何 `<a>` 的 `href` 等于 `"#"`

#### Scenario: data 文件不再包含占位 `#`

- **WHEN** 静态 import `frontend/app/regions/featureNav.data.ts` 的 default export
- **THEN** 前 3 项的 `href` 字段分别为 `/spots`、`/posts`、`/spots/ranking`
- **AND** 无任何项的 `href` 字段等于 `"#"`

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

### Requirement: Feature-nav 容器必须渲染 4 个带图标的 chip（homepage-visual-v1 新增）

`FeatureNavSlot` SHALL render exactly 4 feature chips (Cities / Stories / Hidden Spots / Plan with AI), each containing a lucide-react icon and English label. The chips MUST be arranged in a responsive grid (2 cols mobile, 4 cols desktop) with hover effect.

#### Scenario: Feature-nav 渲染 4 个 chip

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `container.querySelectorAll('[data-region="feature-nav"] a')` 长度恰好为 `4`
- **AND** 各 `<a>` 的 textContent 依次为 `['Cities', 'Stories', 'Hidden Spots', 'Plan with AI']`

#### Scenario: 每个 chip 含 lucide-react 图标

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** 每个 `<a>` 内含一个 `<svg>`（lucide-react 图标渲染为 SVG）
- **AND** 4 个图标依次为 MapPin / BookOpen / Compass / Sparkles

#### Scenario: chip 有 hover 效果

- **WHEN** 检视 `FeatureNavSlot.tsx`
- **THEN** 每个 `<a>` 的 className 含 `hover:` 前缀的 Tailwind 类（如 `hover:shadow-md`）

#### Scenario: 响应式布局

- **WHEN** 检视 `FeatureNavSlot.tsx`
- **THEN** 外层容器 className 含 `grid-cols-2` 和 `md:grid-cols-4`

---

### Requirement: Feature-nav 数据来源必须为 4 个含图标的入口（homepage-visual-v1 新增）

The feature-nav content SHALL be sourced from `frontend/app/regions/featureNav.data.ts` with 4 items, each containing `label` (English), `href`, and `icon` (lucide-react icon name).

#### Scenario: data 文件包含 4 个入口

- **WHEN** 静态 import `featureNav.data.ts` 的 default export
- **THEN** 数组长度恰好为 `4`

#### Scenario: 每个入口含图标字段

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `icon` 字段，值为 `'MapPin'` / `'BookOpen'` / `'Compass'` / `'Sparkles'` 之一

### Requirement: "Plan with AI" 卡片必须触发全局 AI 面板

The 4th feature-nav item ("Plan with AI") SHALL be a `<button>` that, when clicked, opens the same global AI chat panel used by `AiLauncherSlot`. The trigger MUST call the shared AI-panel UI store's open action. It MUST NOT navigate to any route and MUST NOT mount a duplicate `<AiChatPanel />` instance inside `FeatureNavSlot`.

#### Scenario: 点击 "Plan with AI" 打开 AI 面板

- **GIVEN** 全局 AI 面板 store 初始为关闭
- **WHEN** 点击 feature-nav 中 label 为 "Plan with AI" 的 `<button>`
- **THEN** 全局 AI 面板 store 的 open 状态变为 `true`

#### Scenario: 触发逻辑不引入路由或重复面板

- **WHEN** 检视 `FeatureNavSlot.tsx` 及其 "Plan with AI" 子组件
- **THEN** 该按钮无 `href`、不调用 `router.push`
- **AND** `FeatureNavSlot` 内不 import `AiChatPanel`

#### Scenario: no-fetch 守护保持

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/FeatureNavSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

