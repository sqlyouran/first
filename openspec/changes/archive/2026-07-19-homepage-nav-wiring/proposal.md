## Why

首页已上线，但多个入口是"死链"：FeatureNav 四张功能卡 `href` 全是 `"#"`，HotPosts 区块缺少"查看全部"入口，SiteHeader 顶栏没有任何跳转到主内容页的主导航。目标页（`/posts`、`/spots`、`/spots/ranking`）均已存在——这是一次"接线"而非"造页"，把已建成的列表页与首页入口连起来，消除样板间观感。

## What Changes

- **FeatureNav 四卡接线**：Cities → `/spots`、Stories → `/posts`、Hidden Spots → `/spots/ranking`；第四张 "Plan with AI" 不再是链接，改为触发全局 AI 对话面板。
- **Plan with AI 触发全局 AI 面板**：把 AiLauncher 的 Dialog/Sheet 开关状态从组件本地（非受控）提升为全局 UI store，使 FeatureNav 卡片可远程打开同一面板。**BREAKING**：`homepage-ai-launcher` 从"非受控 open"改为"受控 open（store 驱动）"。
- **FeatureNav 第四卡由 `<a>` 变 `<button>`**：**BREAKING**：`homepage-feature-nav` 原契约要求所有 item 为 `href === "#"` 的 `<a>`；本变更后 3 张为真实路由 `<a>`、第 4 张为触发 AI 面板的 `<button>`。
- **HotPosts 增加 "See all → /posts" 入口**：对齐 HotSpots 的 "See all → /spots/ranking" 模式（标题行右侧链接）。
- **SiteHeader 桌面主导航**：在 Logo 与工具图标之间加入 `hidden md:flex` 的主导航链接（Cities / Stories / Spots）。移动端导航本次不做，显式延后。

## Capabilities

### New Capabilities
<!-- 无新增 capability：本变更修改既有首页 region 的需求契约 -->

### Modified Capabilities
- `homepage-feature-nav`: 占位 `href === "#"` 契约作废，改为真实业务路由；第 4 张卡由链接改为触发 AI 面板的按钮。
- `homepage-ai-launcher`: Dialog/Sheet 开关状态从组件本地非受控改为全局 UI store 受控，支持被 FeatureNav 等外部入口远程打开。
- `homepage-hot-posts`: 新增标题行 "See all → /posts" 链接契约（卡片计数断言需与 See-all 链接解耦）。
- `homepage-shell`: SiteHeader 新增桌面端（`md:` 及以上）主导航链接契约；移动端保持现状。

## Impact

- **前端组件**：`frontend/app/regions/FeatureNavSlot.tsx`、`featureNav.data.ts`、`HotPostsSlot.tsx`、`AiLauncherSlot.tsx`、`frontend/app/_components/SiteHeader.tsx`。
- **新增文件**：全局 AI 面板 UI store（`frontend/lib/stores/aiPanel.ts`）+ FeatureNav "Plan with AI" 客户端子组件（触发按钮，`"use client"`）。
- **测试**：`FeatureNavSlot.test.tsx`（`href === "#"` 与 4 个 `<a>` 断言需更新）、`HotPostsSlot.test.tsx`（卡片计数 selector 需收敛到 `.grid > a`，另加 See-all 断言）、`AiLauncherSlot.test.tsx`（受控 open）、`SiteHeader` 新增导航测试。
- **约束**：不引入新 npm 依赖；不新增 `app/api/**/route.ts`；不修改 `lib/backend.ts`；Region-Slot 的 no-fetch 守护保持不变。
- **不影响**：后端、目标列表页本身（`/posts`、`/spots`、`/spots/ranking` 均已存在，不改动）。
