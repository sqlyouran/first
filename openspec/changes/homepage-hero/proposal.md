## Why

`homepage-shell` 已落地骨架，`homepage-feature-nav` 验证了「区块内容注入」工作流（硬编码常量 + 至少 1 个可见子节点 + 占位 `#`）。本变更把同样模式应用到 `hero` region：让首屏从空容器变为含可见标题 + CTA 入口的最小可见形态，作为后续接入业务文案与设计的承载位。

## What Changes

- 新增最小化的 `HeroContent` 数据结构（`{ title, ctaLabel, ctaHref }`，硬编码 TS 常量单对象）
- 改写 `frontend/app/regions/HeroSlot.tsx`：从空 `<section>` 改为渲染 1 个 `<h1>` + 1 个 `<button>`（**BREAKING** 对 `homepage-shell` 中"HeroSlot 完全空容器"约束的契约变更）
- 新增 `frontend/app/regions/hero.data.ts`（硬编码常量来源）
- 单测覆盖：`HeroSlot` 渲染出 `<h1>` 与 `<button>`、CTA 占位 href 严格 `#`、未引入 fetch / 未改 `lib/backend.ts`
- BFF 边界守护：不引入 `app/api/**/route.ts`、不动 `package.json`

## Impact

- New capability spec: `homepage-hero`（4 条 Requirement）
- Modified capability spec: `homepage-shell`（解除 HeroSlot 的"完全空容器"约束）
- 影响代码（仅 frontend）：
  - 新增 `frontend/app/regions/hero.data.ts`
  - 改写 `frontend/app/regions/HeroSlot.tsx`
  - 新增 `frontend/app/regions/HeroSlot.test.tsx`
  - 更新 `frontend/README.md`（在《首页骨架》小节标注 hero 已注入）
- 后端、layout、page.tsx、其他 5 个 Slot 完全不动
