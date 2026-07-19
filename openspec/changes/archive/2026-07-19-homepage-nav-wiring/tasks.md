## 1. aiPanel 全局 UI store（新建）

- [x] 1.1 RED：写 `frontend/lib/stores/aiPanel.test.ts`——断言 store 初始 `isOpen === false`；调用 open 后为 `true`，close 后为 `false`；确认无 `messages`/`sendMessage`/`conversationId` 字段。看它失败。
- [x] 1.2 GREEN：新建 `frontend/lib/stores/aiPanel.ts`（Zustand `create`），暴露 `isOpen` + `open()` / `close()` / `setOpen(bool)`。跑测试转绿。

## 2. AiLauncherSlot 改受控

- [x] 2.1 RED：更新 `frontend/app/regions/AiLauncherSlot.test.tsx`——mock/使用 `aiPanel` store，断言点击浮按钮后 store `isOpen` 变 `true`；断言外部把 `isOpen` 置真后 Dialog/Sheet 打开并含 `<AiChatPanel />`；保留 `hidden md:block`/`md:hidden` 与 Sparkles/`fixed bottom-6 right-6` 断言。看它失败。
- [x] 2.2 GREEN：改 `AiLauncherSlot.tsx`，Dialog/Sheet 用 `open={isOpen} onOpenChange={setOpen}` 绑定 `aiPanel` store，移除本地开关；trigger 保持双形态。跑测试转绿。
- [x] 2.3 验证 no-fetch 守护仍通过（grep 不到 `fetch(`/`lib/backend`）。

## 3. FeatureNav 四卡接线

- [x] 3.1 RED：更新 `frontend/app/regions/FeatureNavSlot.test.tsx`——改断言为「3 个 `<a>` + 1 个 `<button>`」；前 3 个 `<a>` 的 href 依次为 `/spots`、`/posts`、`/spots/ranking`；无任何 href 为 `"#"`；点击 "Plan with AI" 按钮后 `aiPanel` store `isOpen` 变真；保留 no-fetch 断言、label 顺序、grid/hover class 断言；`data` 文件断言改为前 3 项真实路由、无 `"#"`。看它失败。
- [x] 3.2 GREEN：更新 `featureNav.data.ts`——前 3 项 `href` 改为真实路由；第 4 项去掉链接语义（缺 href 或加动作标记，取最小满足 spec 的形状）。
- [x] 3.3 GREEN：新建 `frontend/app/regions/PlanWithAiCard.tsx`（`"use client"`）渲染 `<button>`，`onClick` 调 `aiPanel.open()`，视觉与其余卡片一致（icon + label + description + border-l/hover class）。
- [x] 3.4 GREEN：改 `FeatureNavSlot.tsx`——前 3 项渲染 `<a>`，第 4 项渲染 `<PlanWithAiCard />`；确保 `FeatureNavSlot` 不 import `AiChatPanel`、无 fetch。跑测试转绿。

## 4. HotPosts "See all → /posts"

- [x] 4.1 RED：更新 `frontend/app/regions/HotPostsSlot.test.tsx`——卡片计数 selector 收敛为 `[data-region="hot-posts"] .grid > a`（=3）；新增断言 `a[href="/posts"]` 存在且文本为 `See all →`，且位于含 `flex items-center justify-between` 的标题行、不在故事卡内。看它失败。
- [x] 4.2 GREEN：改 `HotPostsSlot.tsx`——标题行改 `flex items-center justify-between`，右侧加 `<a href="/posts">See all →</a>`，复用 HotSpots 样式（`font-medium text-blue-700 hover:text-blue-800`）。跑测试转绿。

## 5. SiteHeader 桌面主导航

- [x] 5.1 RED：新增/更新 `frontend/app/_components/SiteHeader.test.tsx`——断言存在指向 `/spots`(Cities)、`/posts`(Stories)、`/spots/ranking`(Spots) 的导航链接；导航容器 className 含 `hidden` + `md:flex`；Logo 与 5 个工具图标仍在；header 仍 `sticky top-0`。看它失败。
- [x] 5.2 GREEN：改 `SiteHeader.tsx`——在 Logo 与工具图标簇之间插入 `<nav className="hidden md:flex ...">` 含 3 个 `<Link>`。跑测试转绿。

## 6. 收尾验证

- [x] 6.1 `cd frontend && npm test` 全绿（含既有未改动测试不回归）。
- [x] 6.2 `openspec validate homepage-nav-wiring` 通过。
- [x] 6.3 手动/E2E 抽查：首页点 4 卡 + See-all + 顶栏导航跳转正确；"Plan with AI"（卡片与浮按钮）都能打开同一 AI 面板。
- [x] 6.4 确认未新增 npm 依赖、未新增 `app/api/**/route.ts`、`lib/backend.ts` 未变。
