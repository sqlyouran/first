# homepage-hero Spec

> 首页骨架中 `hero` region 的内容契约。
> 本 spec 定义 `frontend/app/regions/HeroSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：渲染恰好 1 个 `<h1>` 与 1 个 `<button>` 子节点；数据来自硬编码 TS 常量单对象；CTA 占位 `data-cta-href` 严格为 `#`；不破坏 BFF 边界。视觉设计、背景图、响应式、真实业务跳转与弹窗交互均由后续独立 capability 承载。

## Requirements

### Requirement: hero region 必须渲染 1 个 `<h1>` 与至少 1 个 `<button>` 子节点

> **homepage-visual-v1 修正**：原骨架阶段约定“恰好 1 个 button”（CTA），visual-v1 引入搜索按钮后，button 数量变为 ≥ 1。h1 约束不变。

`HeroSlot` SHALL render a single root `<section data-region="hero">` containing exactly one `<h1>` element and at least one `<button>` element. The `<h1>` MUST carry non-empty `textContent` (the title); at least one `<button>` MUST carry a visible icon (SVG from lucide-react).

#### Scenario: hero region 容器仍存在

- **GIVEN** `HeroSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('[data-region="hero"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 1 个 `<h1>` 标题子节点

- **WHEN** RTL 渲染 `<HeroSlot />` 并查 `container.querySelectorAll('section[data-region="hero"] h1')`
- **THEN** NodeList 长度恰好为 `1`
- **AND** 该 `<h1>` 的 `textContent.trim().length > 0`

#### Scenario: 至少 1 个 `<button>` 子节点含 SVG 图标

- **WHEN** RTL 渲染 `<HeroSlot />` 并查 `container.querySelectorAll('section[data-region="hero"] button')`
- **THEN** NodeList 长度 ≥ `1`
- **AND** 至少 1 个 `<button>` 内含 `<svg>` 元素（lucide-react 图标）
- **AND** 该 `<svg>` 内含 `path` / `line` / `circle` / `polyline` / `rect` 子元素（非空图标）

---

### Requirement: hero 数据来源必须为硬编码 TS 常量单对象

The hero content SHALL be sourced from a hard-coded TypeScript constant at `frontend/app/regions/hero.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\\(|import.*lib/backend" frontend/app/regions/HeroSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 单对象

- **GIVEN** `frontend/app/regions/hero.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `HeroContent`（含字符串字段 `title`、`ctaLabel`、`ctaHref`）
- **AND** `title.trim().length > 0` 且 `ctaLabel.trim().length > 0`

---

### Requirement: CTA 占位锚点必须为严格 `#`

> **homepage-visual-v1 说明**：`ctaHref` / `ctaLabel` 字段保留在 data 中作为未来 CTA 按钮的预留，visual-v1 当前用搜索框替代 CTA，组件不渲染这两个字段，但数据契约仍然有效。

The hero CTA's placeholder link target SHALL be exactly the string `"#"`. This change MUST NOT introduce any business route path (e.g., `/search`, `/flights`).

#### Scenario: ctaHref 严格等于 `#`

- **GIVEN** `hero.data.ts` 已 import
- **WHEN** 读取 default export 的 `ctaHref` 字段
- **THEN** 值 `=== "#"`

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

### Requirement: Hero 容器必须渲染全幅风景摄影 + 大标题 + 搜索框（homepage-visual-v1 新增）

`HeroSlot` SHALL render a full-width section with a background image (picsum.photos placeholder), gradient overlay for text readability, a large display heading (Inter 48px+), subtitle, and a search input with icon button. The section MUST use `bg-cover` and `bg-center` classes for the background image.

#### Scenario: Hero 为全幅 section 含背景图

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('[data-region="hero"]')` 非 null
- **AND** 该 section 的 className 含 `bg-cover` 或 `bg-[url(...)]`
- **AND** section 高度 ≥ 500px（className 含 `h-[...]`）

#### Scenario: Hero 渲染 h1 标题

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('h1')` 非 null
- **AND** h1 的 className 含 `text-5xl` 或 `text-6xl`（48px+ 字号）
- **AND** h1 的 textContent 非空

#### Scenario: Hero 渲染搜索输入框

- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('input[type="text"]')` 非 null
- **AND** input 的 placeholder 属性非空
- **AND** input 旁有 `<button>` 含搜索图标（lucide-react Search）

---

### Requirement: Hero 数据来源必须包含背景图 URL 和搜索占位文本（homepage-visual-v1 新增）

The hero content SHALL be sourced from `frontend/app/regions/hero.data.ts` with expanded fields: `title`, `subtitle`, `ctaLabel`, `ctaHref`, `searchPlaceholder`, and `backgroundImage`. The `backgroundImage` MUST be a valid URL (picsum.photos placeholder).

#### Scenario: data 文件包含背景图 URL

- **WHEN** 静态 import `hero.data.ts` 的 default export
- **THEN** `backgroundImage` 字段为非空字符串
- **AND** `backgroundImage` 以 `http://` 或 `https://` 开头

#### Scenario: data 文件包含搜索占位文本

- **WHEN** 静态 import `hero.data.ts` 的 default export
- **THEN** `searchPlaceholder` 字段为非空字符串
- **AND** `searchPlaceholder.trim().length > 0`
