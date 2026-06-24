# homepage-shell Spec

> 首页骨架（Wanderchina 主页 6 region 容器契约）。本 spec 定义 `frontend/app/page.tsx` 与 `frontend/app/layout.tsx` 在「骨架阶段」必须满足的结构契约：6 个页内 region（含 ai-launcher）。各 region 的具体内容、数据、样式由独立 capability（`homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher`）分别承载。

## Requirements

### Requirement: 首页 Page 必须渲染 6 个 region Slot 按文档顺序

`app/page.tsx` SHALL render exactly 6 region slots in document order: `hero`, `feature-nav`, `city-grid`, `hot-posts`, `hot-spots`, `ai-launcher`.

#### Scenario: 6 个 region 按文档顺序存在

- **GIVEN** `app/page.tsx` 已按 homepage-shell apply 重写
- **WHEN** RTL 渲染 `<Page />` 后取 `container.querySelectorAll('[data-region]')`
- **THEN** NodeList 长度等于 `6`
- **AND** 各节点 `data-region` 值依次为 `['hero','feature-nav','city-grid','hot-posts','hot-spots','ai-launcher']`

#### Scenario: AiLauncherSlot 作为最后 region 渲染

- **WHEN** RTL 渲染 `<Page />` 后查 `container.querySelector('[data-region="ai-launcher"]')`
- **THEN** 返回非 null
- **AND** DOM 顺序上 `[data-region="ai-launcher"]` 节点出现在 `[data-region="hot-spots"]` 之后

---

### Requirement: Layout 必须挂载 SiteHeader 与 AuthProvider

`app/layout.tsx` SHALL mount `<SiteHeader />` and `<AuthProvider>` wrapping `{children}` inside `<body>`. The layout no longer mounts AiLauncherSlot (moved to page.tsx in homepage-visual-v2).

#### Scenario: layout 渲染 ai-launcher 在 children 之后

- **GIVEN** layout 已按 homepage-shell apply 修改
- **WHEN** 测试以一个带 `data-testid="children-marker"` 的子节点作为 children 渲染 layout
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** DOM 顺序上 `[data-region="ai-launcher"]` 节点出现在 `[data-testid="children-marker"]` 之后

#### Scenario: ai-launcher 容器内含至少 2 个 button（visual-v1 修正）

> **homepage-visual-v1 修正**：原骨架阶段约定“恰好 1 个 button”，visual-v1 引入 Dialog/Sheet 双形态后变为 2 个 button（desktop trigger + mobile trigger）。

- **GIVEN** layout 已按 homepage-shell apply 修改 + AiLauncherSlot 已按 homepage-ai-launcher 改写 + homepage-visual-v1 已应用
- **WHEN** 测试渲染 layout 后查 `container.querySelectorAll('[data-region="ai-launcher"] button')`
- **THEN** NodeList 长度 ≥ `2`
- **AND** 每个 `<button>` 的 `textContent.trim().length > 0`

#### Scenario: 跨 SSR 链路 ai-launcher 槽位存在

- **GIVEN** 前端 dev server 已起
- **WHEN** `curl -s http://localhost:<port>/`
- **THEN** 响应 HTML 中存在恰好 1 个 `data-region="ai-launcher"` 元素
- **AND** 该元素位于 5 个页内 region 之后
- **AND** 该元素内含 1 个 `<button>` 节点

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
- **THEN** 该 spec 中“通过前端 Next.js SSR 调后端访问”场景的断言不再要求首页 HTML 含 `<h1>hello`
- **AND** spec 中显式声明 HelloMessage 链路由 `HelloMessage.test.tsx` 单测覆盖

---

### Requirement: 页面级视觉契约（homepage-visual-v1 新增）

All region slots SHALL conform to a shared page-level visual contract defined in `app/globals.css`. This contract includes: font stack (Inter for body, Plus Jakarta Sans for display headings), primary color (indigo / blue-700), section spacing (96px desktop / 64px mobile), and responsive 3-breakpoint system (mobile < 768 / tablet 768-1023 / desktop ≥ 1024).

#### Scenario: 字体 stack 正确

- **WHEN** 检视 `app/layout.tsx` 和 `app/globals.css`
- **THEN** `next/font/google` 引入 Inter 和 Plus Jakarta Sans
- **AND** `@theme inline` CSS 变量定义 `--font-sans` 和 `--font-heading`
- **AND** `body` 使用 `--font-sans`，`h1-h6` 使用 `--font-heading`

#### Scenario: 主色为靛青

- **WHEN** 检视 `app/globals.css`
- **THEN** `:root` CSS 变量定义 `--color-brand: #1d4ed8`（Tailwind blue-700）
- **AND** shadcn `--primary` token 映射为 `oklch(0.488 0.243 264.376)`（靛青色相）

#### Scenario: section 间距正确

- **WHEN** 检视 `app/globals.css`
- **THEN** `section[data-region]` 的 `padding-block` 在 mobile（< 1024px）为 64px，desktop（≥ 1024px）为 96px

#### Scenario: 响应式 3 断点

- **WHEN** 检视所有 Slot 组件的 Tailwind class
- **THEN** 布局使用 `grid-cols-2` / `md:grid-cols-4` 等断点类名
- **AND** 断点符合 mobile < 768 / tablet 768-1023 / desktop ≥ 1024 分段
