## MODIFIED Requirements

### Requirement: AI Launcher 必须渲染浮按钮 + Dialog/Sheet 双形态

`AiLauncherSlot` SHALL render a fixed-position floating button with "Plan with AI" text and lucide-react Sparkles icon. Clicking the button MUST open a Dialog on desktop (≥ 1024px) or a Sheet on mobile (< 1024px). Both Dialog and Sheet MUST contain placeholder text "AI Trip Planner coming soon".

#### Scenario: AI Launcher 渲染浮按钮

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"] button')` 非 null
- **AND** button 的 textContent 含 "Plan with AI"
- **AND** button 的 className 含 `fixed` 和 `bottom-6` 和 `right-6`

#### Scenario: 浮按钮含 Sparkles 图标

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** button 内含一个 `<svg>`（lucide-react Sparkles 图标）

#### Scenario: 点击打开 Dialog（desktop）

- **GIVEN** 视口宽度 ≥ 1024px（desktop）
- **WHEN** 点击 "Plan with AI" 按钮
- **THEN** shadcn Dialog 组件可见
- **AND** Dialog 内含文本 "AI Trip Planner" 或 "coming soon"

#### Scenario: 点击打开 Sheet（mobile）

- **GIVEN** 视口宽度 < 1024px（mobile）
- **WHEN** 点击 "Plan with AI" 按钮
- **THEN** shadcn Sheet 组件可见（从底部弹出）
- **AND** Sheet 内含文本 "AI Trip Planner" 或 "coming soon"

#### Scenario: Dialog 和 Sheet 通过 CSS 媒体查询切换

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** Dialog 的 trigger 容器 className 含 `hidden md:block`
- **AND** Sheet 的 trigger 容器 className 含 `md:hidden`
- **AND** 不使用 React state 监听窗口尺寸（仅用 CSS 媒体查询）

---

### Requirement: AI Launcher 容器必须为 div（无变化）

（此 Requirement 保持 homepage-ai-launcher archive 后的状态，无新增 Scenario）

---

### Requirement: AI Launcher 数据来源必须为硬编码 TS 常量（无变化）

（此 Requirement 保持 homepage-ai-launcher archive 后的状态，无新增 Scenario）

---

### Requirement: 占位 button 必须不绑定业务逻辑（MODIFIED）

The placeholder `<button>` SHALL NOT carry any `onClick` handler that invokes business logic, navigation, or backend calls. It MAY open a Dialog / Sheet with placeholder content. This change MUST NOT introduce any business route path.

#### Scenario: button 仅打开 Dialog/Sheet（无业务逻辑）

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** button 的 `onClick` 仅调用 `setOpen(true)` 打开 Dialog/Sheet
- **AND** Dialog/Sheet 内容为占位文本，无真实业务逻辑

#### Scenario: 未引入业务路由文件

- **WHEN** `find frontend/app -mindepth 2 -name 'page.tsx'`（排除 `app/page.tsx`）
- **THEN** 输出为空

---

### Requirement: BFF 边界守护必须保持（无变化）

（此 Requirement 保持 homepage-ai-launcher archive 后的状态，无新增 Scenario）
