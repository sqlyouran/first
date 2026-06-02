## Context

本变更是"区块内容注入"工作流的第四个目标。完全复用 feature-nav / city-grid 模式：硬编码 TS 常量数组 + 至少 1 个 `<a>` 子节点 + 占位 `#`。语义差别仅在"攻略标题"标签集合（如"东京 5 日游 / 北海道滑雪攻略"）。

文章详情、缩略图、作者、热度数据均不在本变更范围。

## Goals / Non-Goals

**Goals:**
- 用最少的代码（≤ 30 行 component + ≤ 10 行 data）让 hot-posts region 从空变为含至少 1 个可见 `<a>` 子节点
- 数据来源：硬编码 TS 常量数组；不引入任何依赖、不动 `lib/backend`
- 测试覆盖：HotPostsSlot 渲染出至少 1 个 `<a>`、所有 href 严格 `#`、不引入 fetch / lib/backend
- BFF 边界守护：仍无 `app/api/**/route.ts`、`lib/backend.ts` 与 `package.json` 字节级不变

**Non-Goals:**
- 文章正文 / 详情页
- 缩略图 / 作者头像 / 发布时间
- 热度排序、点赞、评论数
- 接入后端或本地 JSON / Markdown 数据源
- 创建 `/posts/*` 业务路由

## Decisions

### D1: 数据结构同形 city-grid / feature-nav — `{ label, href }`

完全复用现有最小字段。后续若要加 `excerpt` / `coverUrl` / `publishedAt` 等，独立 propose。

### D2: 数量下限 = 1，无上限

spec 不规定具体攻略清单，data 文件可放 1 项也可放 6 项。

### D3: 占位 href 严格 `#`

与 feature-nav / city-grid 同形。本变更不引入 `/posts/*` 业务路由。

### D4: MODIFIED delta 仅解除 HotPostsSlot 的空容器约束

排除清单追加 HotPostsSlot。

### D5: 测试策略 — 三个独立用例

- 渲染出 `<section data-region="hot-posts">`
- 至少 1 个 `<a>` 子节点（textContent 非空）
- 所有 `<a>` 的 href 属性严格 `#`

### D6: data 文件命名 — `hotPosts.data.ts`（camelCase + .data.ts）

延续现有命名约定。

## Risks / Trade-offs

- **风险**：占位的攻略标签可能让本地 UI 看起来"内容稀疏"。可接受 — 本变更目标是契约而非视觉。
- **Trade-off**：spec 不约束具体攻略数量与排序，给 data 文件最大自由度。
