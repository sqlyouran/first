## Why

继 `homepage-feature-nav` 之后，把"区块内容注入"模式应用到 `city-grid` region：让首页城市卡片网格从空容器变为含至少 1 个可见 `<a>` 子节点的最小可见形态。复用 feature-nav 同形契约（硬编码 TS 常量数组 + 至少 1 个 `<a>` + 占位 `#`）。

## What Changes

- 新增最小化的 `CityGridItem` 数据结构（`{ label, href }`，硬编码 TS 常量数组）
- 改写 `frontend/app/regions/CityGridSlot.tsx`：从空 `<section>` 改为渲染至少 1 个 `<a>` 子节点（**BREAKING** 对 `homepage-shell` 中"CityGridSlot 完全空容器"约束的契约变更）
- 新增 `frontend/app/regions/cityGrid.data.ts`（硬编码常量来源）
- 单测覆盖：`CityGridSlot` 渲染出至少 1 个 `<a>`、所有 href 严格 `#`、未引入 fetch / 未改 `lib/backend.ts`
- BFF 边界守护：不引入 `app/api/**/route.ts`、不动 `package.json`

## Impact

- New capability spec: `homepage-city-grid`（4 条 Requirement）
- Modified capability spec: `homepage-shell`（解除 CityGridSlot 的"完全空容器"约束）
- 影响代码（仅 frontend）：
  - 新增 `frontend/app/regions/cityGrid.data.ts`
  - 改写 `frontend/app/regions/CityGridSlot.tsx`
  - 新增 `frontend/app/regions/CityGridSlot.test.tsx`
  - 更新 `frontend/README.md`（在《首页骨架》小节标注 city-grid 已注入）
- 后端、layout、page.tsx、其他 5 个 Slot 完全不动
