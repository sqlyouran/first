# Proposal: 首页骨架（homepage-shell）

## Why

首页要拆成 6 个区块（hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher）并行实施，缺一份**先行冻结挂载位与命名契约**的骨架 change。否则 6 个区块单元各自决定挂载方式，容易出现：

1. **挂载位漂移**：A 单元把 hero 挂在 `<main>`，B 单元把 feature-nav 挂在 `<section>`，骨架不一致
2. **跨页面常驻无锚点**：ai-launcher 需要挂在 `app/layout.tsx` 的 `{children}` 之后才能跨路由常驻；不预留这个槽位，ai-launcher 单元就要自己改 layout，跟其它 5 个区块的"只改 page.tsx"模式割裂
3. **6 区块无法并行**：6 个 change 同时改 `page.tsx` 必冲突；先把 page.tsx 拆成 5 个 Slot 渲染位，6 个区块单元改自己的 Slot 文件即可零冲突并行

本变更的产物是**纯结构骨架**——6 个空 Slot 组件 + 一份重写的 page.tsx + 一处 layout.tsx 注入。**不引入任何样式、数据、交互**——这些留给 6 个区块各自的 change。

## What Changes

### `frontend/` 子仓
- **重写** `app/page.tsx`：改为 Server Component，依次渲染 `<HeroSlot />` `<FeatureNavSlot />` `<CityGridSlot />` `<HotPostsSlot />` `<HotSpotsSlot />`（**不**渲染 ai-launcher）
- **修改** `app/layout.tsx`：在 `<body>` 内 `{children}` 之后挂 `<AiLauncherSlot />`，使其跨页面常驻
- **新建** `app/regions/` 目录，含 6 个 Slot 组件：`HeroSlot.tsx` / `FeatureNavSlot.tsx` / `CityGridSlot.tsx` / `HotPostsSlot.tsx` / `HotSpotsSlot.tsx` / `AiLauncherSlot.tsx`
- 每个 Slot 渲染**单一空容器**，带 `data-region="<name>"` + `aria-label="<name> placeholder"`
- 5 个页内 Slot 容器为 `<section>`，ai-launcher 容器为 `<div>`
- **新增** `app/page.test.tsx`：单测覆盖 5 region 按文档顺序、不出现 ai-launcher
- **保留** `app/HelloMessage.tsx`（含其测试）与 `lib/backend.ts`：BFF 链路活体探针，**page.tsx 不再 import 它们**

### 治理文档
- `openspec/specs/http-server/spec.md`："通过前端 Next.js SSR 调后端访问"场景同步调整断言：HelloMessage 链路存在性由 `HelloMessage.test.tsx` 单测保住，不再依赖首页 UI

## Out of Scope

- 任何区块**内部**内容（文案、图片、数据、样式、交互、组件）——属各区块独立 change
- 任何 CSS 框架引入（Tailwind / shadcn 等）——属 `frontend-styling-stack` change
- 删除 `HelloMessage.tsx` 或 `lib/backend.ts`——保留为 BFF 链路活体探针（见 design D3）
- 任何 mock 数据 / API 调用 / BFF 新逻辑
- `backend/` 任何修改

## 前置依赖

**强依赖**：本变更必须在 `frontend-styling-stack` 完成 archive 之后才进入 apply 阶段。

理由：`frontend-styling-stack` 的 tasks 2a.1 / 5.4 假设 page.tsx 仍是 HelloMessage 形态（探针注入位 + 视觉无破坏验收）。若 shell 先 apply，styling-stack 的探针无处可插、验收语义失效，需回头改其 4 件套。详见 design.md 的 D1。

> 本 change 可与 styling-stack **同时存在为 active proposal**（OpenSpec 允许），但不可早于 styling-stack archive 进入 apply。

## Open Questions

1. **AI 入口跨页面边界何时收敛**：当前 `<AiLauncherSlot />` 直挂 root layout，意味着未来任何路由（含 `/admin` / `/login`）都会渲染 AI 助手悬浮按钮。trigger：第 2 条非 `/` 路由出现时，需 propose 把 launcher 从 root layout 提到 `app/(public)/layout.tsx` 路由组。当前 YAGNI 不预留。
2. **HelloMessage 长期归宿**：本期保留为 BFF 链路活体探针；当 `homepage-hero` 接入真实数据并通过 `lib/backend.ts` 完成 SSR 链路覆盖后，HelloMessage 的"探针"角色可由 hero 测试接管，届时可在 hero 的 change 中一并清理。本期不动。
