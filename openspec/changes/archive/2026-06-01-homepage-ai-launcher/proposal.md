## Why

继 5 个页内 region 全部完成内容注入后，最后一个区块 `ai-launcher` 也按"区块内容注入"模式落地：让 layout 常驻槽位从空 div 容器变为含 1 个可见 `<button>` 触发按钮的最小可见形态。本变更同时收敛 `homepage-shell` 中"完全空容器"约束的最后一个适用对象，自此该约束从主 spec 中移除。

## What Changes

- 新增最小化的 `AiLauncherContent` 数据结构（`{ buttonLabel }`，硬编码 TS 常量单对象）
- 改写 `frontend/app/regions/AiLauncherSlot.tsx`：从空 `<div>` 改为渲染 1 个 `<button>`（**BREAKING** 对 `homepage-shell` 中"AiLauncherSlot 完全空容器"约束的契约变更）
- 新增 `frontend/app/regions/aiLauncher.data.ts`（硬编码常量来源）
- 单测覆盖：`AiLauncherSlot` 渲染出 1 个 `<button>`、按钮 textContent 非空、未引入 fetch / 未改 `lib/backend.ts`
- BFF 边界守护：不引入 `app/api/**/route.ts`、不动 `package.json`
- **同步 layout 集成测试**：`frontend/app/layout.test.tsx` 中"ai-launcher 在 children 之后"用例调整，从查 `[data-region="ai-launcher"]` 容器存在升级为查容器内含 `<button>`

## Impact

- New capability spec: `homepage-ai-launcher`（4 条 Requirement）
- Modified capability spec: `homepage-shell`（解除 AiLauncherSlot 的"完全空容器"约束 — 自此该约束的所有 6 个 Slot 全部解除，主 spec 中"完全空容器"那条 Requirement 整体退役）
- 影响代码（仅 frontend）：
  - 新增 `frontend/app/regions/aiLauncher.data.ts`
  - 改写 `frontend/app/regions/AiLauncherSlot.tsx`
  - 新增 `frontend/app/regions/AiLauncherSlot.test.tsx`
  - 调整 `frontend/app/layout.test.tsx`（仅断言强化，不改变 layout 结构）
  - 更新 `frontend/README.md`（在《首页骨架》小节标注 ai-launcher 已注入）
- 后端、layout.tsx 结构、page.tsx、其他 5 个 Slot 完全不动
