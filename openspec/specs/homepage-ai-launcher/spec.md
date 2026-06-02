# homepage-ai-launcher Spec

> Wanderchina 首页骨架的 AI 助手入口（ai-launcher）capability spec。本 spec 定义 `frontend/app/regions/AiLauncherSlot.tsx` 在「骨架阶段」的容器形态、内容契约与数据来源。挂载位（layout 而非 page）由 `homepage-shell` 主 spec 负责。

## Purpose

`AiLauncherSlot` 是首页骨架阶段 6 个 region 中唯一**挂在 layout 而非 page** 的常驻槽位（D4 trigger 来到前持续如此）。从 `homepage-ai-launcher` 变更交付起，该 Slot 不再是空容器：渲染 1 个占位 `<button>`，文本来自硬编码 TS 常量 `aiLauncher.data.ts`。骨架阶段不绑业务 onClick / 不引入路由 / 不引入状态管理，留给后续独立 propose 接入真实 AI 浮层。

## Requirements

### Requirement: ai-launcher 容器必须为 div 且渲染恰好 1 个 `<button>` 子节点

`AiLauncherSlot` SHALL render a single root `<div data-region="ai-launcher">` containing exactly one `<button>` element as its child node. The `<button>` MUST carry non-empty `textContent` (the button label). The container MUST NOT carry the `aria-label="ai-launcher placeholder"` attribute that existed under the empty-container contract.

#### Scenario: ai-launcher 容器仍存在且为 div

- **GIVEN** `AiLauncherSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** 该节点 tagName 为 `DIV`

#### Scenario: 1 个 `<button>` 子节点

- **WHEN** RTL 渲染 `<AiLauncherSlot />` 并查 `container.querySelectorAll('div[data-region="ai-launcher"] button')`
- **THEN** NodeList 长度恰好为 `1`
- **AND** 该 `<button>` 的 `textContent.trim().length > 0`

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

The placeholder `<button>` SHALL NOT carry any `onClick` handler that invokes business logic, navigation, or backend calls. It MAY remain unbound or carry a no-op handler. This change MUST NOT introduce any business route path (e.g., `/ai`, `/assistant`) and MUST NOT introduce any new client-side state management.

#### Scenario: button 无业务 onClick

- **WHEN** 检视 `frontend/app/regions/AiLauncherSlot.tsx`
- **THEN** 文件中 `<button>` 节点不绑定任何 `onClick={...}`，或仅绑定 `onClick={() => {}}` 形式的 noop

#### Scenario: 未引入业务路由文件

- **WHEN** `find frontend/app -mindepth 2 -name 'page.tsx'`（排除 `app/page.tsx`）
- **THEN** 输出为空

#### Scenario: 未引入客户端状态管理依赖

- **WHEN** 比对本变更前后的 `frontend/package.json` 的 `dependencies` 与 `devDependencies` 字段
- **THEN** 两份列表完全一致（无 zustand / jotai / redux 等新引入）

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
