## MODIFIED Requirements

### Requirement: AI Launcher 必须渲染浮按钮 + Dialog/Sheet 双形态（homepage-visual-v1 新增）

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
