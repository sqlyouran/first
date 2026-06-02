## Context

本变更是"区块内容注入"工作流的第三个目标（feature-nav → hero → city-grid）。完全复用 feature-nav 模式：硬编码 TS 常量数组 + 至少 1 个 `<a>` 子节点 + 占位 `#`。语义差别仅在"城市"标签集合（如"北京 / 上海 / 广州"），不引入额外字段。

视觉 grid 布局、城市图片、分类、行政区切换均不在本变更范围。

## Goals / Non-Goals

**Goals:**
- 用最少的代码（≤ 30 行 component + ≤ 10 行 data）让 city-grid region 从空变为含至少 1 个可见 `<a>` 子节点
- 数据来源：硬编码 TS 常量数组；不引入任何依赖、不动 `lib/backend`
- 测试覆盖：CityGridSlot 渲染出至少 1 个 `<a>`、所有 href 严格 `#`、不引入 fetch / lib/backend
- BFF 边界守护：仍无 `app/api/**/route.ts`、`lib/backend.ts` 与 `package.json` 字节级不变

**Non-Goals:**
- 视觉 grid 布局 / 间距 / 响应式
- 城市图片 / icon
- 行政区切换、热门 / 全部分类切换
- 接入后端或本地 JSON 数据源
- 创建 `/cities/*` 业务路由

## Decisions

### D1: 数据结构同形 feature-nav — `{ label, href }`

完全复用 feature-nav 的最小字段。后续若要加 `imageUrl` / `provinceCode` 等，独立 propose。

### D2: 数量下限 = 1，无上限

本契约只关心"至少 1 项可见"，不规定具体城市清单。data 文件可放 1 项也可放 8 项，spec 不约束。

### D3: 占位 href 严格 `#`

与 feature-nav 同形。本变更不引入业务路由 `page.tsx`（如 `/cities/beijing/page.tsx`）。

### D4: MODIFIED delta 仅解除 CityGridSlot 的空容器约束

把 `homepage-shell` 中"所有 Slot 必须为完全空容器"那条 Requirement 的排除清单追加 CityGridSlot。其他 Slot 约束不变。

### D5: 测试策略 — 三个独立用例

- 渲染出 `<section data-region="city-grid">`
- 至少 1 个 `<a>` 子节点（textContent 非空）
- 所有 `<a>` 的 href 属性严格 `#`

### D6: data 文件命名 — `cityGrid.data.ts`（camelCase + .data.ts）

延续 `featureNav.data.ts` 的命名约定。

## Risks / Trade-offs

- **风险**：占位的 1 项城市标签可能让本地 UI 看起来"没准备好"。可接受 — 本变更目标是契约而非视觉。
- **Trade-off**：spec 不约束具体城市清单，给 data 文件最大自由度；实施者可写 1 项也可写 8 项，不影响 spec 通过。
