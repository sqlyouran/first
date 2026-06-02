# homepage-hero Spec

> 首页骨架中 `hero` region 的内容契约。
> 本 spec 定义 `frontend/app/regions/HeroSlot.tsx` 在「区块内容注入」阶段必须满足的最小契约：渲染恰好 1 个 `<h1>` 与 1 个 `<button>` 子节点；数据来自硬编码 TS 常量单对象；CTA 占位 `data-cta-href` 严格为 `#`；不破坏 BFF 边界。视觉设计、背景图、响应式、真实业务跳转与弹窗交互均由后续独立 capability 承载。

## Requirements

### Requirement: hero region 必须渲染 1 个 `<h1>` 与 1 个 `<button>` 子节点

`HeroSlot` SHALL render a single root `<section data-region="hero">` containing exactly one `<h1>` element and exactly one `<button>` element. The `<h1>` MUST carry non-empty `textContent` (the title); the `<button>` MUST carry non-empty `textContent` (the CTA label).

#### Scenario: hero region 容器仍存在

- **GIVEN** `HeroSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<HeroSlot />`
- **THEN** `container.querySelector('[data-region="hero"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 1 个 `<h1>` 标题子节点

- **WHEN** RTL 渲染 `<HeroSlot />` 并查 `container.querySelectorAll('section[data-region="hero"] h1')`
- **THEN** NodeList 长度恰好为 `1`
- **AND** 该 `<h1>` 的 `textContent.trim().length > 0`

#### Scenario: 1 个 `<button>` CTA 子节点

- **WHEN** RTL 渲染 `<HeroSlot />` 并查 `container.querySelectorAll('section[data-region="hero"] button')`
- **THEN** NodeList 长度恰好为 `1`
- **AND** 该 `<button>` 的 `textContent.trim().length > 0`

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
