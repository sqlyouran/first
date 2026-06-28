# homepage-ai-launcher Spec

> Wanderchina 首页骨架的 AI 助手入口（ai-launcher）capability spec。本 spec 定义 `frontend/app/regions/AiLauncherSlot.tsx` 的容器形态、内容契约与数据来源。挂载位（layout 而非 page）由 `homepage-shell` 主 spec 负责。

## Purpose

`AiLauncherSlot` 是首页 6 个 region 中唯一**挂在 layout 而非 page** 的常驻槽位。该 Slot 渲染固定浮按钮 "Plan with AI"，点击后打开 Dialog（桌面）或 Sheet（移动），内嵌 `<AiChatPanel />` 提供 AI 旅行助手聊天功能。

## Requirements

### Requirement: ai-launcher 容器必须为 div 且渲染至少 1 个 `<button>` 子节点

> **homepage-visual-v1 修正**：原骨架阶段约定"恰好 1 个 button"，visual-v1 引入 Dialog/Sheet 双形态后变为 2 个 button（desktop trigger + mobile trigger）。容器约束不变。

`AiLauncherSlot` SHALL render a single root `<div data-region="ai-launcher">` containing at least one `<button>` element. Each `<button>` MUST carry non-empty `textContent` (the button label). The container MUST NOT carry the `aria-label="ai-launcher placeholder"` attribute that existed under the empty-container contract.

#### Scenario: ai-launcher 容器仍存在且为 div

- **GIVEN** `AiLauncherSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** 该节点 tagName 为 `DIV`

#### Scenario: 至少 1 个 `<button>` 子节点

- **WHEN** RTL 渲染 `<AiLauncherSlot />` 并查 `container.querySelectorAll('div[data-region="ai-launcher"] button')`
- **THEN** NodeList 长度 ≥ `1`
- **AND** 每个 `<button>` 的 `textContent.trim().length > 0`

#### Scenario: aria-label placeholder 属性已移除

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** 根容器的 `getAttribute('aria-label')` 返回 `null`（或不为 `"ai-launcher placeholder"`）

---

### Requirement: ai-launcher 数据来源必须为硬编码 TS 常量单对象

The ai-launcher content SHALL be sourced from a hard-coded TypeScript constant at `frontend/app/regions/aiLauncher.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/AiLauncherSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 单对象

- **GIVEN** `frontend/app/regions/aiLauncher.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `AiLauncherContent`（含字符串字段 `buttonLabel`）
- **AND** `buttonLabel.trim().length > 0`

---

### Requirement: AI Launcher 必须渲染浮按钮 + Dialog/Sheet 双形态（ai-chat-frontend UPDATED）

`AiLauncherSlot` SHALL render a fixed-position floating button with "Plan with AI" text and lucide-react Sparkles icon. Clicking the button MUST open a Dialog on desktop (≥ 1024px) or a Sheet on mobile (< 1024px). Both Dialog and Sheet MUST contain `<AiChatPanel />` 聊天组件（替代原 "coming soon" 占位文本）。Desktop Dialog 尺寸 SHALL 为 `sm:max-w-lg h-[70vh]`，Mobile Sheet 尺寸 SHALL 为 `h-[85vh]`。

#### Scenario: AI Launcher 渲染浮按钮

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"] button')` 非 null
- **AND** button 的 textContent 含 "Plan with AI"
- **AND** button 的 className 含 `fixed` 和 `bottom-6` 和 `right-6`

#### Scenario: 浮按钮含 Sparkles 图标

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** button 内含一个 `<svg>`（lucide-react Sparkles 图标）

#### Scenario: 点击打开 Dialog 显示聊天面板（desktop）

- **GIVEN** 视口宽度 ≥ 1024px（desktop）
- **WHEN** 点击 "Plan with AI" 按钮
- **THEN** shadcn Dialog 组件可见
- **AND** Dialog 内包含 `<AiChatPanel />` 组件（不再显示 "coming soon"）

#### Scenario: 点击打开 Sheet 显示聊天面板（mobile）

- **GIVEN** 视口宽度 < 1024px（mobile）
- **WHEN** 点击 "Plan with AI" 按钮
- **THEN** shadcn Sheet 组件可见（从底部弹出）
- **AND** Sheet 内包含 `<AiChatPanel />` 组件（不再显示 "coming soon"）

#### Scenario: Dialog 和 Sheet 通过 CSS 媒体查询切换

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** Dialog 的 trigger 容器 className 含 `hidden md:block`
- **AND** Sheet 的 trigger 容器 className 含 `md:hidden`
- **AND** 不使用 React state 监听窗口尺寸（仅用 CSS 媒体查询）
# homepage-ai-launcher Spec

> Wanderchina 首页骨架的 AI 助手入口（ai-launcher）capability spec。本 spec 定义 `frontend/app/regions/AiLauncherSlot.tsx` 在「骨架阶段」的容器形态、内容契约与数据来源。挂载位（layout 而非 page）由 `homepage-shell` 主 spec 负责。

## Purpose

`AiLauncherSlot` 是首页骨架阶段 6 个 region 中唯一**挂在 layout 而非 page** 的常驻槽位（D4 trigger 来到前持续如此）。从 `homepage-ai-launcher` 变更交付起，该 Slot 不再是空容器：渲染 1 个占位 `<button>`，文本来自硬编码 TS 常量 `aiLauncher.data.ts`。骨架阶段不绑业务 onClick / 不引入路由 / 不引入状态管理，留给后续独立 propose 接入真实 AI 浮层。

## Requirements

### Requirement: ai-launcher 容器必须为 div 且渲染至少 1 个 `<button>` 子节点

> **homepage-visual-v1 修正**：原骨架阶段约定“恰好 1 个 button”，visual-v1 引入 Dialog/Sheet 双形态后变为 2 个 button（desktop trigger + mobile trigger）。容器约束不变。

`AiLauncherSlot` SHALL render a single root `<div data-region="ai-launcher">` containing at least one `<button>` element. Each `<button>` MUST carry non-empty `textContent` (the button label). The container MUST NOT carry the `aria-label="ai-launcher placeholder"` attribute that existed under the empty-container contract.

#### Scenario: ai-launcher 容器仍存在且为 div

- **GIVEN** `AiLauncherSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** 该节点 tagName 为 `DIV`

#### Scenario: 至少 1 个 `<button>` 子节点

- **WHEN** RTL 渲染 `<AiLauncherSlot />` 并查 `container.querySelectorAll('div[data-region="ai-launcher"] button')`
- **THEN** NodeList 长度 ≥ `1`
- **AND** 每个 `<button>` 的 `textContent.trim().length > 0`

#### Scenario: aria-label placeholder 属性已移除

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** 根容器的 `getAttribute('aria-label')` 返回 `null`（或不为 `"ai-launcher placeholder"`）

---

### Requirement: ai-launcher 数据来源必须为硬编码 TS 常量单对象

The ai-launcher content SHALL be sourced from a hard-coded TypeScript constant at `frontend/app/regions/aiLauncher.data.ts`. The component MUST NOT fetch data from `lib/backend.ts`, any HTTP endpoint, or any local JSON / config file.

#### Scenario: 不存在 fetch / lib/backend 引用

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/AiLauncherSlot.tsx`
- **THEN** 输出为空（无任何匹配行）

#### Scenario: data 文件 default-export 单对象

- **GIVEN** `frontend/app/regions/aiLauncher.data.ts` 存在
- **WHEN** 静态 import 其 default export
- **THEN** 类型为 `AiLauncherContent`（含字符串字段 `buttonLabel`）
- **AND** `buttonLabel.trim().length > 0`

---

### Requirement: 占位 button 必须不绑定业务逻辑

> **homepage-visual-v1 MODIFIED**：原 R3 约束“未引入客户端状态管理”，visual-v1 引入 `useState` 用于 Dialog/Sheet 开关状态，不违反业务逻辑约束。button 的 onClick 仅调用 `setOpen(true)` 打开占位 Dialog/Sheet，无业务导航。

The placeholder `<button>` SHALL NOT carry any `onClick` handler that invokes business logic, navigation, or backend calls. It MAY open a Dialog / Sheet with placeholder content. This change MUST NOT introduce any business route path (e.g., `/ai`, `/assistant`).

#### Scenario: button 无业务 onClick

- **WHEN** 检视 `frontend/app/regions/AiLauncherSlot.tsx`
- **THEN** 文件中 `<button>` / `<DialogTrigger>` / `<SheetTrigger>` 的 `onClick` 仅调用 `setOpen(true)` 或无 onClick（由 shadcn Trigger 内部处理）
- **AND** Dialog/Sheet 内容为占位文本，无真实业务导航

#### Scenario: 未引入业务路由文件

- **WHEN** `find frontend/app -mindepth 2 -name 'page.tsx'`（排除 `app/page.tsx`）
- **THEN** 输出为空

#### Scenario: 未引入客户端状态管理依赖（已废弃）

> 此 Scenario 已被 visual-v1 废弃。`useState` 仅用于 Dialog/Sheet open 状态，不属于业务状态管理。不再断言 package.json 无变化。

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

### Requirement: AI Launcher 必须渲染浮按钮 + Dialog/Sheet 双形态（homepage-visual-v1 新增）

`AiLauncherSlot` SHALL render a fixed-position floating button with “Plan with AI” text and lucide-react Sparkles icon. Clicking the button MUST open a Dialog on desktop (≥ 1024px) or a Sheet on mobile (< 1024px). Both Dialog and Sheet MUST contain placeholder text “AI Trip Planner coming soon”.

#### Scenario: AI Launcher 渲染浮按钮

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"] button')` 非 null
- **AND** button 的 textContent 含 “Plan with AI”
- **AND** button 的 className 含 `fixed` 和 `bottom-6` 和 `right-6`

#### Scenario: 浮按钮含 Sparkles 图标

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** button 内含一个 `<svg>`（lucide-react Sparkles 图标）

#### Scenario: 点击打开 Dialog（desktop）

- **GIVEN** 视口宽度 ≥ 1024px（desktop）
- **WHEN** 点击 “Plan with AI” 按钮
- **THEN** shadcn Dialog 组件可见
- **AND** Dialog 内含文本 “AI Trip Planner” 或 “coming soon”

#### Scenario: 点击打开 Sheet（mobile）

- **GIVEN** 视口宽度 < 1024px（mobile）
- **WHEN** 点击 “Plan with AI” 按钮
- **THEN** shadcn Sheet 组件可见（从底部弹出）
- **AND** Sheet 内含文本 “AI Trip Planner” 或 “coming soon”

#### Scenario: Dialog 和 Sheet 通过 CSS 媒体查询切换

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** Dialog 的 trigger 容器 className 含 `hidden md:block`
- **AND** Sheet 的 trigger 容器 className 含 `md:hidden`
- **AND** 不使用 React state 监听窗口尺寸（仅用 CSS 媒体查询）

---

### Requirement: 占位 button 必须不绑定业务逻辑（homepage-visual-v1 MODIFIED）

The placeholder `<button>` SHALL NOT carry any `onClick` handler that invokes business logic, navigation, or backend calls. It MAY open a Dialog / Sheet with placeholder content. This change MUST NOT introduce any business route path.

#### Scenario: button 仅打开 Dialog/Sheet（无业务逻辑）

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** button 的 `onClick` 仅调用 `setOpen(true)` 打开 Dialog/Sheet
- **AND** Dialog/Sheet 内容为占位文本，无真实业务逻辑

#### Scenario: 未引入业务路由文件

- **WHEN** `find frontend/app -mindepth 2 -name 'page.tsx'`（排除 `app/page.tsx`）
- **THEN** 输出为空
