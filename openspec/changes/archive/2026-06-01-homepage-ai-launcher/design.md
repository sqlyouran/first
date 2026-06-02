## Context

本变更是"区块内容注入"工作流的**收尾变更**（第六个，也是最后一个）。同形于 hero 的"单对象数据 + 单可见子节点"模式，但有两点本质差异：

1. **容器形态**：ai-launcher 容器是 `<div>`（layout 直接挂 `<AiLauncherSlot />`），不是 `<section>`。
2. **唯一可见子节点**：`<button>`（不是 `<h1>` / `<a>`）—— 业务真实场景中 ai-launcher 是触发 AI 助手浮层的按钮，用 `<button>` 语义正确，避免后续二次迁移。

完成本变更后，`homepage-shell` 中"所有 Slot 必须为完全空容器"约束的 6 个适用对象（hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher）全部解除，**该 Requirement 整条退役**（archive 时通过 REMOVED delta 从主 spec 中移除）。

AI 助手的浮层 UI、对话能力、后端集成均不在本变更范围。本变更只让 ai-launcher 从空容器升级为含 1 个可见 `<button>` 的最小可见形态。

## Goals / Non-Goals

**Goals:**
- 用最少代码（≤ 25 行 component + ≤ 8 行 data）让 ai-launcher 槽位从空 div 变为含 1 个可见 `<button>` 的最小形态
- 数据来源：硬编码 TS 常量单对象 `{ buttonLabel }`；不引入任何依赖、不动 `lib/backend`
- 测试覆盖：`AiLauncherSlot` 容器仍为 div + 渲染恰好 1 个 `<button>` + buttonLabel 非空
- 同步加固 layout 集成测试（`layout.test.tsx` 的 ai-launcher 断言从"容器存在"升级为"容器内含 button"）
- BFF 边界守护：仍无 `app/api/**/route.ts`、`lib/backend.ts` 与 `package.json` 字节级不变
- 最终收尾：通过 REMOVED delta 让 `homepage-shell` 中"完全空容器"约束整条退役

**Non-Goals:**
- AI 浮层 UI（弹窗 / 抽屉 / 对话流）
- onClick 业务行为（绑定真实业务逻辑）
- 后端集成 / WebSocket / SSE
- 创建 `/ai/*` 业务路由
- 视觉布局 / 响应式 / 浮层定位
- 国际化 / a11y 增强（aria-* 属性扩展）

## Decisions

### D1: 数据结构 — 单对象 `{ buttonLabel }`

最简化字段。不引入 `onClick` / `href` / `icon`：
- 不是链接，不需要 `href`
- 占位阶段不绑业务逻辑，不需要 `onClick`
- icon 是视觉范畴，本变更非视觉

```ts
export type AiLauncherContent = { buttonLabel: string };
const aiLauncher: AiLauncherContent = { buttonLabel: "占位 AI 助手" };
export default aiLauncher;
```

### D2: 用 `<button>` 不用 `<a>`

语义正确性 > 占位简单性：
- ai-launcher 真实业务是触发浮层（非页面跳转），`<button>` 是正确语义
- 避免未来从 `<a>` 改回 `<button>` 的二次成本
- 与 hero CTA 的决策（D3）保持一致

### D3: 容器仍为 div（不改 layout 挂载位置）

`AiLauncherSlot` 由 `app/layout.tsx` 直接挂载在 `<body>` 中 `{children}` 之后。本变更**不改变** layout 结构，仅改变 Slot 内部实现：
- 容器仍为 `<div data-region="ai-launcher">`
- 仅在容器内追加 1 个 `<button>` 子节点
- 移除原"完全空容器"占位的 `aria-label="ai-launcher placeholder"` 属性（占位语义已由 button 自身承载）

### D4: 删除 `aria-label="ai-launcher placeholder"` 属性

原 placeholder 形态下 `aria-label` 用于无内容时的可访问性兜底。现在容器内有可读 `<button>`，aria-label 反而冗余且语义错位（容器不再是占位）。本变更删除该属性。

### D5: MODIFIED delta — REMOVED 整条"完全空容器" Requirement

完成本变更后，"所有 Slot 必须为完全空容器" 这条 Requirement 已无适用对象（6 个 Slot 全部解除）。直接 REMOVED 整条，避免空骨架污染主 spec。

迁移路径：6 个 Slot 的容器形态契约分别由 6 份 capability spec 接管（`homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher`）。

### D6: 测试策略 — 3 个独立用例 + 1 个 layout 集成强化

**单元测试** `AiLauncherSlot.test.tsx`：
- `renders div container with data-region="ai-launcher"`（容器形态）
- `renders exactly one button with non-empty text`（button 渲染）
- `data file default-export is { buttonLabel: string }`（数据契约）

**集成测试调整** `layout.test.tsx`：
- 原断言：`container.querySelector('[data-region="ai-launcher"]')` 非 null
- 新断言：`container.querySelector('[data-region="ai-launcher"] button')` 非 null（容器内含 button）

### D7: data 文件命名 — `aiLauncher.data.ts`

延续现有命名约定（驼峰 + `.data.ts` 后缀）。

### D8: 占位 button 不绑定 onClick

占位阶段 button 不挂任何 handler。真实业务逻辑由后续独立 propose（`ai-launcher-overlay` / `ai-launcher-dialog` 等）承担。spec 中显式约束"button 不应包含 onClick handler 调用业务逻辑"，避免提前耦合。

## Risks / Trade-offs

- **风险**：删除 `aria-label="ai-launcher placeholder"` 后，若 button 文本为空将丢失可访问性兜底。已通过 R3（buttonLabel 非空）+ 单测断言闭环防御。
- **风险**：layout 集成测试断言强化后，若有人误将 button 移走（譬如改回 placeholder div）会立即 RED。这是预期效果。
- **Trade-off**：REMOVED 整条 Requirement 而非保留空骨架。理由：spec 应反映当前真实契约，无适用对象的 Requirement 是噪音；如果未来再次需要"空容器"约束，可重新 ADDED 而非保留无用框架。
- **Trade-off**：button 不绑 onClick 让占位"看起来不可点击"。可接受 —— 占位本就不应承载业务行为。
