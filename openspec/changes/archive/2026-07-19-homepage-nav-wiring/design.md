## Context

首页已上线，`/posts`、`/spots`、`/spots/ranking` 三个列表页均已建成并可访问。本变更是"接线"——把首页三处死入口连到既有页面，不新建业务页面。

现状要点（已核实）：
- `FeatureNavSlot` 是 Server Component，4 张卡数据来自 `featureNav.data.ts`，`href` 全为 `"#"`。
- `AiLauncherSlot` 用**非受控** Radix Dialog（桌面）/ Sheet（移动）承载 `<AiChatPanel />`，开关状态在组件内部（`DialogTrigger`），无共享 open 状态；`aiChat` store 只管消息。
- `HotPostsSlot` 标题区无 "See all"；`HotSpotsSlot` 已有 "See all → /spots/ranking" 可作模板。
- `SiteHeader` 挂在 `layout.tsx`（全局），仅 Logo + 工具图标。
- Region-Slot 测试守护 no-fetch（grep `fetch(` / `lib/backend`），且 `FeatureNavSlot.test.tsx` / `HotPostsSlot.test.tsx` 存在把当前状态写死的断言。

约束：不引入新 npm 依赖；不新增 `app/api/**/route.ts`；不改 `lib/backend.ts`；遵守 TDD 与 Region-Slot 约定。

## Goals / Non-Goals

**Goals:**
- FeatureNav 前 3 卡指向真实路由，第 4 卡触发全局 AI 面板。
- AI 面板开关状态提升为全局 UI store，支持多入口打开同一面板。
- HotPosts 增加 "See all → /posts"，与 HotSpots 模式一致。
- SiteHeader 增加桌面端主导航（Cities / Stories / Spots）。

**Non-Goals:**
- 移动端主导航（汉堡/Sheet）——显式延后。
- 不改动 `/posts`、`/spots`、`/spots/ranking` 页面本身。
- 不新建 `/cities` 路由（城市浏览沿用 `/spots`）。
- 不改动 AI 对话的业务逻辑与 `aiChat` store。

## Decisions

### D1：新建独立 `aiPanel` UI store，而非扩展 `aiChat` store

新建 `frontend/lib/stores/aiPanel.ts`（Zustand），仅持 `isOpen` + `open()` / `close()` / `setOpen(bool)`。
- **为何独立**：`aiChat.ts` 是领域状态（消息/会话），open/close 是纯 UI 状态，混入会污染领域 store。符合 frontend-conventions"一个领域一个 store"。
- **备选**：塞进 `aiChat` store（否决：耦合 UI 与领域）；用 React Context（否决：项目已用 Zustand，无需新增模式）。

### D2：`AiLauncherSlot` 从非受控改受控

Dialog/Sheet 改为 `open={isOpen} onOpenChange={setOpen}`，浮按钮 trigger 保持不变（仍在 `hidden md:block` / `md:hidden` 双形态）。点击 trigger 通过 `onOpenChange` 或显式 `open()` 置真。
- **为何**：受控后任意入口调 `open()` 即可打开同一面板实例，无需重复挂载 `<AiChatPanel />`。
- **风险点**：桌面/移动两套 Dialog+Sheet 共享同一 `isOpen`；因二者靠 CSS 媒体查询互斥显示，同一时刻只有一个可见，语义正确。

### D3：FeatureNav 第 4 卡拆出 `"use client"` 子组件

`FeatureNavSlot` 保持 Server Component。新增一个小的客户端子组件（如 `PlanWithAiCard`）渲染 `<button>`，`onClick` 调 `aiPanel.open()`。前 3 卡仍是 `<a>`（Server 可渲染）。
- **为何拆分**：仅第 4 卡需要交互，遵守"默认 Server Component，仅需要时加 use client"。整体转 client 会牺牲 SSR 且无必要。
- **data 结构**：`featureNav.data.ts` 第 4 项语义从"链接"变为"动作"。为最小改动，保留数组结构，第 4 项 `href` 去掉（或标记 `action: "ai"`），由 Slot 依 label/标记判定渲染 `<a>` 还是 `<button>`。具体字段形状在实现时以最小满足 spec 为准（YAGNI，不预设多余动作类型）。

### D4：HotPosts "See all" 复用 HotSpots 布局 + 收敛卡片计数 selector

标题行改为 `flex items-center justify-between`，右侧加 `<a href="/posts">See all →</a>`。
- **测试联动**：`HotPostsSlot.test.tsx` 现用 `[data-region="hot-posts"] a` 数全部 anchor（=3）。加 See-all 会变 4。按 HotSpots 已验证的做法，把卡片计数 selector 收敛到 `.grid > a`（只数故事卡），See-all 单独断言。这是预期内的 TDD 更新。

### D5：SiteHeader 桌面导航用 `hidden md:flex`

在 Logo 与工具图标簇之间插入 `<nav className="hidden md:flex ...">`，含 3 个 `<Link>`（`/spots` Cities、`/posts` Stories、`/spots/ranking` Spots）。
- **为何 desktop-only**：56px 高的 bar 在移动端已被工具图标占满，桌面才有横向空间。移动端导航单独立项。

## Risks / Trade-offs

- [改 `href` / 卡结构会打断写死现状的既有测试] → 这是 TDD RED 的正常部分；spec 已把新契约固化，实现时先改测试到 RED 再实现到 GREEN。
- [受控 Dialog+Sheet 共享 `isOpen` 可能在断点切换瞬间出现两处都想渲染] → CSS 媒体查询保证容器互斥可见，Radix Portal 只渲染 open 且可见的那个；测试覆盖 desktop/mobile 两路。
- [FeatureNav 转 client 子组件可能被误改为整槽 `use client`，破坏 SSR] → spec 明确 `FeatureNavSlot` 不 import `AiChatPanel`、no-fetch 守护保留；仅第 4 卡子组件带 `use client`。
- [Cities 与 Hidden Spots 都落在 spots 域（`/spots` vs `/spots/ranking`）语义重叠] → 二者分别对齐首页 CityGrid（浏览）与 HotSpots（榜单）语义，接受此重叠，不新建 `/cities`。

## Migration Plan

纯前端渐进式改动，无数据迁移、无 API 变更。分步：
1. 新建 `aiPanel` store（先 RED 单测：初始 `isOpen=false`，`open()` 置真）。
2. 改 `AiLauncherSlot` 受控（更新 `AiLauncherSlot.test.tsx`）。
3. FeatureNav：更新 `featureNav.data.ts` + Slot + `PlanWithAiCard` 子组件（更新 `FeatureNavSlot.test.tsx`）。
4. HotPosts See-all（更新 `HotPostsSlot.test.tsx` selector + See-all 断言）。
5. SiteHeader 桌面导航（新增/更新 SiteHeader 测试）。

回滚：改动集中在 5 个前端文件 + 1 新 store + 1 新子组件，`git revert` 即可；不影响后端与既有页面。

## Open Questions

- FeatureNav 第 4 项 data 形状用 `action` 标记还是"缺 href 即按钮"——实现时取最小满足 spec 的方案即可，不阻塞。
