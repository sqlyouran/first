## Context

本变更是"区块内容注入"工作流的第五个目标。完全复用 feature-nav / city-grid / hot-posts 模式：硬编码 TS 常量数组 + 至少 1 个 `<a>` 子节点 + 占位 `#`。语义差别仅在"景点名称"标签集合（如"故宫 / 西湖 / 黄山"）。

景点详情页、地理坐标、门票价格、营业时间均不在本变更范围。

## Goals / Non-Goals

**Goals:**
- 用最少的代码（≤ 30 行 component + ≤ 10 行 data）让 hot-spots region 从空变为含至少 1 个可见 `<a>` 子节点
- 数据来源：硬编码 TS 常量数组；不引入任何依赖、不动 `lib/backend`
- 测试覆盖：HotSpotsSlot 渲染出至少 1 个 `<a>`、所有 href 严格 `#`、不引入 fetch / lib/backend
- BFF 边界守护：仍无 `app/api/**/route.ts`、`lib/backend.ts` 与 `package.json` 字节级不变

**Non-Goals:**
- 景点图片 / 地图坐标
- 门票价格 / 营业时间 / 评分
- 接入后端或本地 JSON 数据源
- 创建 `/spots/*` 业务路由
- 视觉布局 / 响应式

## Decisions

### D1: 数据结构同形 — `{ label, href }`

完全复用 hot-posts / city-grid / feature-nav 的最小字段。

### D2: 数量下限 = 1，无上限

spec 不规定具体景点清单。

### D3: 占位 href 严格 `#`

不引入 `/spots/*` 业务路由。

### D4: MODIFIED delta 仅解除 HotSpotsSlot 的空容器约束

排除清单追加 HotSpotsSlot。本次 MODIFIED 之后，`homepage-shell` 中"完全空容器"约束的剩余适用对象只剩 AiLauncherSlot 一个。

### D5: 测试策略 — 三个独立用例

- 渲染出 `<section data-region="hot-spots">`
- 至少 1 个 `<a>` 子节点（textContent 非空）
- 所有 `<a>` 的 href 属性严格 `#`

### D6: data 文件命名 — `hotSpots.data.ts`

延续现有命名约定。

## Risks / Trade-offs

- **风险**：占位的景点标签可能让本地 UI 看起来"内容稀疏"。可接受。
- **Trade-off**：spec 不约束景点清单与排序，给 data 文件最大自由度。
