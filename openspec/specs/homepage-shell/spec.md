# homepage-shell Spec

> 首页骨架（Wanderchina 主页 6 region 容器契约）。本 spec 定义 `frontend/app/page.tsx` 与 `frontend/app/layout.tsx` 在「骨架阶段」必须满足的结构契约：5 个页内 region + 1 个 layout 常驻 ai-launcher，全部为完全空容器。后续每个 region 的内容、数据、样式由独立 capability（`homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher`）分别承载。

## Requirements

### Requirement: 首页 Page 必须渲染 5 个 region Slot 按文档顺序

`app/page.tsx` SHALL render exactly 5 region slots in document order: `hero`, `feature-nav`, `city-grid`, `hot-posts`, `hot-spots`. The page MUST NOT render any other region slot.

#### Scenario: 5 个 region 按文档顺序存在

- **GIVEN** `app/page.tsx` 已按 homepage-shell apply 重写
- **WHEN** RTL 渲染 `<Page />` 后取 `container.querySelectorAll('[data-region]')`
- **THEN** NodeList 长度等于 `5`
- **AND** 各节点 `data-region` 值依次为 `['hero','feature-nav','city-grid','hot-posts','hot-spots']`

#### Scenario: page 不渲染 ai-launcher（页内护栏）

- **WHEN** RTL 渲染 `<Page />` 后查 `container.querySelector('[data-region="ai-launcher"]')`
- **THEN** 返回 `null`

---

### Requirement: Layout 必须挂载 ai-launcher 常驻槽位

`app/layout.tsx` SHALL mount `<AiLauncherSlot />` after `{children}` inside `<body>`. The ai-launcher slot MUST appear in the rendered HTML on every route, after all page content.

#### Scenario: layout 渲染 ai-launcher 在 children 之后

- **GIVEN** layout 已按 homepage-shell apply 修改
- **WHEN** 测试以一个带 `data-testid="children-marker"` 的子节点作为 children 渲染 layout
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** DOM 顺序上 `[data-region="ai-launcher"]` 节点出现在 `[data-testid="children-marker"]` 之后

#### Scenario: 跨 SSR 链路 ai-launcher 槽位存在

- **GIVEN** 前端 dev server 已起
- **WHEN** `curl -s http://localhost:<port>/`
- **THEN** 响应 HTML 中存在恰好 1 个 `data-region="ai-launcher"` 元素
- **AND** 该元素位于 5 个页内 region 之后

---

### Requirement: 所有 Slot 必须为完全空容器

Every region slot component (HeroSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot / AiLauncherSlot) SHALL render a single empty container element with attributes `data-region="<name>"` and `aria-label="<name> placeholder"`. The container MUST have zero child nodes and MUST NOT carry any inline style or className. **FeatureNavSlot is excluded from this constraint**: its content contract is governed by the `homepage-feature-nav` capability spec.

#### Scenario: Slot 独立渲染产物为空（5 个 Slot）

- **GIVEN** 任意非 FeatureNavSlot 的 Slot 组件（HeroSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot / AiLauncherSlot）
- **WHEN** RTL 独立 `render(<HeroSlot />)`（其它 4 个 Slot 同理）
- **THEN** 渲染出唯一一个带 `data-region` + `aria-label` 的容器元素
- **AND** 容器 `childNodes.length === 0`
- **AND** 容器无 `style` 属性、无 `class` / `className` 属性

#### Scenario: 4 个仍空的页内 Slot 容器为 section，ai-launcher 容器为 div

- **GIVEN** 任意非 FeatureNavSlot 的 Slot 已渲染
- **THEN** HeroSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot 的根容器 tagName 为 `SECTION`
- **AND** AiLauncherSlot 的根容器 tagName 为 `DIV`

#### Scenario: FeatureNavSlot 不再受空容器约束

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** 根 section 仍带 `data-region="feature-nav"`，但 `childNodes.length` 可以 `> 0`
- **AND** 具体内容契约见 `openspec/specs/homepage-feature-nav/spec.md`

---

### Requirement: HelloMessage 与 lib/backend 链路必须保留

`app/HelloMessage.tsx`, `app/HelloMessage.test.tsx`, and `lib/backend.ts` SHALL remain present and unchanged after homepage-shell apply. `app/page.tsx` MUST NOT import `HelloMessage` or `fetchFromBackend` after apply.

#### Scenario: HelloMessage 测试不被打断

- **WHEN** `cd frontend && npm test`
- **THEN** `HelloMessage.test.tsx` 仍 GREEN
- **AND** 测试输出含 `HelloMessage > renders hello message from backend` 用例通过

#### Scenario: lib/backend 边界守护未失效

- **WHEN** `head -1 frontend/lib/backend.ts`
- **THEN** 输出 `import "server-only";`

#### Scenario: page.tsx 不再 import HelloMessage 链路

- **WHEN** `grep -E "HelloMessage|fetchFromBackend" frontend/app/page.tsx`
- **THEN** 输出为空（无任何匹配行）

---

### Requirement: 首页必须不依赖后端运行

`app/page.tsx` SHALL NOT make any backend HTTP call. The home route MUST return HTTP 200 with full markup even when the Spring Boot backend (port 8080) is unreachable.

#### Scenario: 后端未启动时首页仍可访问

- **GIVEN** Spring Boot 后端未启动（8080 不通）
- **WHEN** `curl -i http://localhost:<port>/`
- **THEN** 响应状态码为 `200`
- **AND** HTML 含 6 个 `data-region` 元素

---

### Requirement: BFF 边界守护必须保持

The `frontend/app/` directory SHALL NOT contain any `route.ts` or `route.tsx` file after homepage-shell apply. No business logic shall be introduced into the BFF layer by this change.

#### Scenario: 无 Route Handler 文件

- **WHEN** `find frontend/app -name 'route.ts' -o -name 'route.tsx'`
- **THEN** 输出为空

#### Scenario: 未引入新 npm 依赖

- **WHEN** 比对 apply 前后的 `frontend/package.json` 的 `dependencies` 与 `devDependencies`
- **THEN** 两份列表完全一致

---

### Requirement: regions 目录必须恰好包含 6 个 Slot 文件

`frontend/app/regions/` SHALL contain exactly 6 `.tsx` files: `HeroSlot.tsx`, `FeatureNavSlot.tsx`, `CityGridSlot.tsx`, `HotPostsSlot.tsx`, `HotSpotsSlot.tsx`, `AiLauncherSlot.tsx`. Each file MUST default-export a React component returning the corresponding empty container.

#### Scenario: 文件清单完整且仅有 6 个

- **WHEN** `ls frontend/app/regions/*.tsx | wc -l`
- **THEN** 输出 `6`
- **AND** 6 个文件名严格匹配上述清单

#### Scenario: 每个 Slot 默认导出可调用的 React 组件

- **GIVEN** 任一 Slot 文件
- **WHEN** import 其 default export 并 RTL render 之
- **THEN** 渲染成功，无报错

---

### Requirement: 治理文档必须随 archive 同步更新

When this change is archived, `openspec/specs/http-server/spec.md` SHALL be updated so that the "通过前端 Next.js SSR 调后端访问" scenario no longer asserts the homepage UI contains the hello text. The HelloMessage SSR linkage MUST instead be guarded by `HelloMessage.test.tsx` unit test.

#### Scenario: http-server spec 同步更新

- **WHEN** archive 完成后查 `openspec/specs/http-server/spec.md`
- **THEN** 该 spec 中"通过前端 Next.js SSR 调后端访问"场景的断言不再要求首页 HTML 含 `<h1>hello`
- **AND** spec 中显式声明 HelloMessage 链路由 `HelloMessage.test.tsx` 单测覆盖
