## ADDED Requirements

### Requirement: AI 面板开关状态必须由全局 UI store 管理

The open/close state of the AI chat panel (Dialog on desktop, Sheet on mobile) SHALL be held in a shared client-side UI store at `frontend/lib/stores/aiPanel.ts`, exposing `isOpen` state plus `open()` / `close()` (or `setOpen`) actions. `AiLauncherSlot` MUST read and write this store instead of local `useState`, so that other entry points (e.g. FeatureNav "Plan with AI") can open the same panel. The store MUST NOT hold chat message state (that remains in `aiChat.ts`).

#### Scenario: store 暴露 open 状态与动作

- **GIVEN** `frontend/lib/stores/aiPanel.ts` 存在
- **WHEN** 静态 import 其 store hook
- **THEN** store 暴露布尔 `isOpen`（初始 `false`）
- **AND** 暴露可将 `isOpen` 置为 `true` 的 open 动作与置为 `false` 的 close 动作

#### Scenario: 外部调用 open 后面板打开

- **GIVEN** `AiLauncherSlot` 已渲染且 store `isOpen` 为 `false`
- **WHEN** 通过 store 的 open 动作把 `isOpen` 置为 `true`
- **THEN** 桌面 Dialog（或移动 Sheet）进入打开态并渲染 `<AiChatPanel />`

#### Scenario: store 不承载消息状态

- **WHEN** 检视 `frontend/lib/stores/aiPanel.ts`
- **THEN** 该 store 不含 `messages` / `sendMessage` / `conversationId` 等聊天状态字段
- **AND** 聊天状态仍由 `frontend/lib/stores/aiChat.ts` 承载

## MODIFIED Requirements

### Requirement: AI Launcher 必须渲染浮按钮 + Dialog/Sheet 双形态（ai-chat-frontend UPDATED）

`AiLauncherSlot` SHALL render a fixed-position floating button with "Plan with AI" text and lucide-react Sparkles icon. Clicking the button MUST open a Dialog on desktop (≥ 1024px) or a Sheet on mobile (< 1024px). The Dialog/Sheet open state MUST be controlled via the `aiPanel` store (`open` + `onOpenChange` bound to the store), NOT local `useState`. Both Dialog and Sheet MUST contain `<AiChatPanel />`. Desktop Dialog 尺寸 SHALL 为 `sm:max-w-lg h-[70vh]`，Mobile Sheet 尺寸 SHALL 为 `h-[85vh]`。

> **homepage-nav-wiring MODIFIED**：Dialog/Sheet 由非受控（`DialogTrigger` 内部 state）改为受控——`open` / `onOpenChange` 绑定全局 `aiPanel` store。浮按钮点击仍打开面板，行为对用户不变；新增支持被外部入口远程打开。

#### Scenario: AI Launcher 渲染浮按钮

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** `container.querySelector('[data-region="ai-launcher"] button')` 非 null
- **AND** button 的 textContent 含 "Plan with AI"
- **AND** button 的 className 含 `fixed` 和 `bottom-6` 和 `right-6`

#### Scenario: 浮按钮含 Sparkles 图标

- **WHEN** RTL 渲染 `<AiLauncherSlot />`
- **THEN** button 内含一个 `<svg>`（lucide-react Sparkles 图标）

#### Scenario: 点击浮按钮打开面板（desktop）

- **GIVEN** 视口宽度 ≥ 1024px（desktop）且 store `isOpen` 为 `false`
- **WHEN** 点击 "Plan with AI" 浮按钮
- **THEN** store `isOpen` 变为 `true` 且 Dialog 可见并含 `<AiChatPanel />`

#### Scenario: 点击浮按钮打开面板（mobile）

- **GIVEN** 视口宽度 < 1024px（mobile）且 store `isOpen` 为 `false`
- **WHEN** 点击 "Plan with AI" 浮按钮
- **THEN** store `isOpen` 变为 `true` 且 Sheet 从底部弹出并含 `<AiChatPanel />`

#### Scenario: Dialog 和 Sheet 通过 CSS 媒体查询切换

- **WHEN** 检视 `AiLauncherSlot.tsx`
- **THEN** Dialog 的 trigger 容器 className 含 `hidden md:block`
- **AND** Sheet 的 trigger 容器 className 含 `md:hidden`
- **AND** 不使用 React state 监听窗口尺寸（仅用 CSS 媒体查询）
