# homepage-ai-launcher Spec

> 路径：`openspec/specs/homepage/homepage-ai-launcher.md`
> 承接挂载位：`homepage-shell` 在 `app/layout.tsx` 内 `{children}` 之后提供的 `data-region="ai-launcher"` 槽位
> 实现位置：`frontend/app/regions/AiLauncherSlot.tsx`（替换骨架阶段的空 div）
> 范围：**仅 UI 入口**，不接真实对话能力

## 0. 前置依赖

依赖 `frontend-styling-stack`（待 propose）引入 Tailwind + shadcn/ui，使用 shadcn `<Button />` 与 `<Sheet />`（移动端）/ `<Dialog />`（桌面端）。

---

## 1. 模块边界

### 1.1 In Scope

- **常驻悬浮按钮**：fixed 定位于视口右下角，跨页面常驻（挂在 `app/layout.tsx` 内）
- **点击展开占位面板**：移动端用 shadcn `<Sheet side="bottom">`（半屏或全屏），桌面端用 shadcn `<Dialog>`（右下浮窗约 400×600）
- **占位面板内容**：友好提示文案 + 一段说明 + 一个 disabled 状态的"输入框样式占位"，明确告知"AI 对话能力开发中"
- **关闭交互**：右上 ✕ 按钮、ESC 键、点击遮罩、移动端下滑手势均可关闭
- **a11y**：`aria-haspopup` / `aria-expanded` / 焦点陷阱 / 关闭后焦点回到悬浮按钮
- **响应式**：移动端面板贴合底部全宽 / 桌面端右下浮窗

### 1.2 Out of Scope

- **真实 AI 对话能力**：消息流式输出、上下文记忆、多轮对话、工具调用——属独立单元 `ai-chat-core`
- 输入框真实可输入、回车发送
- 历史会话、聊天记录持久化
- 任何 LLM API 调用、任何 SSE / WebSocket 连接
- 用户登录态相关展示
- 多语言切换
- 主题切换 / 暗色模式适配（沿用项目默认）

---

## 2. 核心场景

### Scenario 1：默认渲染悬浮按钮（happy path）

- **WHEN** 任意页面加载
- **THEN** 视口右下角渲染 1 个 shadcn `<Button>` 圆形 FAB，含 `<Sparkles />` 图标
- **AND** 按钮有 `aria-label="唤起 AI 助手"`、`aria-haspopup="dialog"`、`aria-expanded="false"`
- **AND** 按钮位于 `data-region="ai-launcher"` 容器内

### Scenario 2：点击打开面板

- **WHEN** 用户点击悬浮按钮
- **THEN** 占位面板从底部（移动端）或右下（桌面）滑入显示
- **AND** 按钮 `aria-expanded` 切换为 `"true"`
- **AND** 焦点自动落在面板第一个可聚焦元素（关闭按钮）
- **AND** 面板内容包含标题"AI 助手"、说明文案"AI 对话能力开发中，敬请期待"、disabled 输入框

### Scenario 3：ESC 关闭

- **GIVEN** 面板已打开
- **WHEN** 用户按下 `Escape` 键
- **THEN** 面板关闭
- **AND** 焦点回到悬浮按钮
- **AND** `aria-expanded` 切回 `"false"`

### Scenario 4：点击遮罩关闭

- **GIVEN** 面板已打开
- **WHEN** 用户点击面板外的遮罩区域
- **THEN** 面板关闭

### Scenario 5：✕ 按钮关闭

- **GIVEN** 面板已打开
- **WHEN** 用户点击面板右上角 ✕
- **THEN** 面板关闭
- **AND** 焦点回到悬浮按钮

### Scenario 6：移动端面板形态（响应式）

- **WHEN** 视口 `< 768px` 时打开面板
- **THEN** 使用 shadcn `<Sheet side="bottom">` 形态
- **AND** 面板宽度 `w-full`、高度 `h-[80vh]`
- **AND** 顶部含拖拽指示条（shadcn 默认）

### Scenario 7：桌面端面板形态（响应式）

- **WHEN** 视口 `≥ 768px` 时打开面板
- **THEN** 使用 shadcn `<Dialog>` 形态，浮动于右下角
- **AND** 面板尺寸约 `w-[400px] h-[600px]`，距右下边距 `bottom-6 right-6`

### Scenario 8：跨页面常驻（挂载位守护）

- **WHEN** 检查 `app/page.tsx` 渲染结果
- **THEN** `<Page />` 内**不**包含 `data-region="ai-launcher"` 元素
- **AND** `data-region="ai-launcher"` 元素仅由 `app/layout.tsx` 注入

### Scenario 9：不发起任何网络请求（守护）

- **GIVEN** 单测中 mock `fetch` 计数器
- **WHEN** 用户点击悬浮按钮、在 disabled 输入框尝试输入、按 Enter
- **THEN** `fetch` 调用次数为 `0`
- **AND** 无 `EventSource` / `WebSocket` 实例化

### Scenario 10：disabled 输入框守护

- **GIVEN** 面板已打开
- **WHEN** 用户尝试在输入框中输入
- **THEN** 输入框为 `disabled` 状态，不接受输入
- **AND** 输入框旁有 placeholder 文案"AI 对话能力开发中，敬请期待"

### Scenario 11：焦点陷阱

- **GIVEN** 面板已打开
- **WHEN** 用户连续按 `Tab`
- **THEN** 焦点在面板内的可聚焦元素之间循环
- **AND** 不会跳出面板到背后的页面元素

---

## 3. 数据结构

### 3.1 客户端组件签名

```ts
// frontend/app/regions/AiLauncherSlot.tsx
'use client';

export type AiLauncherSlotProps = {
  /** 按钮 aria-label，默认"唤起 AI 助手" */
  buttonAriaLabel?: string;
  /** 面板标题，默认"AI 助手" */
  panelTitle?: string;
  /** 面板说明文案，默认"AI 对话能力开发中，敬请期待" */
  panelDescription?: string;
  /** 输入框 placeholder，默认"AI 对话能力开发中，敬请期待" */
  inputPlaceholder?: string;
};
```

### 3.2 默认常量

```ts
// frontend/app/regions/ai-launcher.constants.ts
export const AI_LAUNCHER_DEFAULTS = {
  buttonAriaLabel: '唤起 AI 助手',
  panelTitle: 'AI 助手',
  panelDescription:
    'Hi！AI 对话能力开发中，敬请期待。届时你可以问我"明天去成都怎么穿？""桂林两天一夜怎么玩？"等问题。',
  inputPlaceholder: 'AI 对话能力开发中，敬请期待',
} as const satisfies Required<AiLauncherSlotProps>;
```

### 3.3 内部状态（hooks）

```ts
const [isOpen, setIsOpen] = useState(false);
// 使用 shadcn <Sheet> / <Dialog> 自带的 open / onOpenChange 即可，无需自定义 reducer
```

### 3.4 约束摘要

| 字段 | 类型 | 必填 | 长度 | 备注 |
|---|---|---|---|---|
| `buttonAriaLabel` | `string` | 否（有默认） | 4–30 | 动词起首 |
| `panelTitle` | `string` | 否（有默认） | 2–10 | 单行 |
| `panelDescription` | `string` | 否（有默认） | 10–200 | 可多行 |
| `inputPlaceholder` | `string` | 否（有默认） | ≤ 40 | 单行 |

### 3.5 数据来源

- **静态常量**：`ai-launcher.constants.ts` 编译期定值
- **不接 API**、**不引入 mock**、**不依赖 BFF**

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 结构与挂载位

- [ ] `AiLauncherSlot.tsx` 顶部含 `'use client'` 指令
- [ ] 根容器 `<div data-region="ai-launcher">` 保留（替换骨架阶段空 div 的内部）
- [ ] `app/layout.tsx` 中渲染 `<AiLauncherSlot />` 的位置不变（`{children}` 之后）
- [ ] `app/page.tsx` 内**未**出现 `data-region="ai-launcher"`（守护测试 GREEN）

### 4.2 视觉

- [ ] 悬浮按钮 fixed 定位 `fixed bottom-6 right-6 z-50`
- [ ] 按钮尺寸 `h-12 w-12 md:h-14 md:w-14`，圆角 `rounded-full`
- [ ] 按钮含 lucide `<Sparkles />` 图标，`aria-hidden="true"`
- [ ] 移动端面板使用 `<Sheet side="bottom">`
- [ ] 桌面端面板使用 `<Dialog>` 并通过 `className` 浮于右下

### 4.3 交互

- [ ] 点击按钮打开面板，`aria-expanded` 切换正确
- [ ] ESC、遮罩点击、✕ 按钮均可关闭
- [ ] 关闭后焦点回到悬浮按钮
- [ ] 输入框 `disabled` 属性存在
- [ ] 焦点陷阱（shadcn `<Dialog>` / `<Sheet>` 自带 Radix 实现）

### 4.4 无障碍

- [ ] 按钮 `aria-label` / `aria-haspopup="dialog"` / `aria-expanded` 正确
- [ ] 面板有 `role="dialog"` 与 `aria-labelledby` 指向标题
- [ ] focus-visible ring 可见
- [ ] 颜色对比度 WCAG AA

### 4.5 守护（无网络）

- [ ] 测试中验证 `fetch` 调用计数为 0
- [ ] 代码中未出现 `fetch(` / `EventSource(` / `WebSocket(` 在 launcher 链路上
- [ ] `lib/backend.ts` 未被本单元 import

### 4.6 测试（TDD）

- [ ] `AiLauncherSlot.test.tsx`：
  - [ ] RED → GREEN：默认渲染悬浮按钮
  - [ ] 用例：点击按钮 → 面板出现 `role="dialog"`
  - [ ] 用例：按 ESC → 面板消失
  - [ ] 用例：点击 ✕ → 面板消失，焦点回按钮
  - [ ] 用例：输入框 disabled
  - [ ] 用例：用户事件不触发 fetch（mock fetch 计数为 0）
  - [ ] 用例：`buttonAriaLabel` 等 props 注入覆盖默认
- [ ] `app/page.test.tsx` 中"page 不渲染 ai-launcher"护栏仍 GREEN
- [ ] `HelloMessage.test.tsx` 仍 GREEN

### 4.7 端到端

- [ ] `npm run build` 通过
- [ ] `npm test` 全绿
- [ ] `curl /` HTML 含 1 个 `data-region="ai-launcher"` 元素 + 悬浮按钮的 `aria-label` 文本（SSR 阶段按钮已 emit）
- [ ] 浏览器手动验证：3 种关闭路径（ESC / 遮罩 / ✕）均可用

### 4.8 边界守护

- [ ] 未新增 `route.ts` / `route.tsx`
- [ ] 未新增任何 API 调用
- [ ] `backend/` submodule 指针未变
- [ ] 未引入 LLM SDK / SSE 库

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `app/layout.tsx` 中的 `data-region="ai-launcher"` 槽位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | Tailwind + shadcn/ui（`<Button>` `<Sheet>` `<Dialog>`） + lucide-react |
| **行为关联但不强依赖** | `homepage-feature-nav` | feature-nav 中的"AI 助手"卡片 href 为 `#ai-launcher`，本单元负责响应锚点（在客户端读取 hash 后自动打开面板，可选；本期不强制） |
| **本单元先于** | `ai-chat-core`（未来 propose） | 真实 AI 对话能力。届时只替换面板内部内容，悬浮按钮与开/关交互不变 |
| **与本单元正交** | `homepage-hero` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` | 各自独立 Slot |
| **本单元不依赖** | `backend/` 改动、任何 mock 数据 | 全静态 |
