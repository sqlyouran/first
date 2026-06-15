## Context

后端景点排行榜 API（`GET /api/spots/ranking?type={heat|rating|bookmark}&top={top}`）已完成，通过 `RankingCacheService` 接入 Redis 缓存（TTL 5min，固定缓存 top=50）。前端目前没有对应的排行榜页面。首页 HotSpots 区域的"See all →"链接仍指向占位 `#all-spots`。

前端现有模式可复用：
- `lib/api/client.ts`：`ApiResponse<T>` + `parseResponse` / `networkError` / `serverError` 工具
- `lib/api/spots.ts`：已有 `SpotListItem` 类型和 `fetchSpots` 函数，可复用类型
- `spots/page.tsx`：景点列表页，可参考页面结构和四态处理模式
- `spots/_components/SpotCard.tsx`：`formatCount()` 工具函数可复用

## Goals / Non-Goals

**Goals:**
- 实现排行榜页面，三 Tab 切换，展示 top=50 排行数据
- 前三名视觉高亮（奖牌图标 + 序号颜色）
- 当前排序维度指标高亮
- 按需请求 + 本地缓存数据策略
- 更新 HotSpots 区域导航入口

**Non-Goals:**
- 不做后端 API 改动
- 不做分页/无限滚动（top=50 一次展示）
- 不做排序切换动画
- 不做暗色模式适配

## Decisions

### D1: 页面组件类型 — "use client"

**选择**：排行榜页面标记为 `"use client"`。

**理由**：需要 Tab 切换交互状态（`useState`）、本地缓存 Map、loading/error 状态管理，无法作为 Server Component 实现。

### D2: 数据缓存策略 — 按需请求 + Map 缓存

**选择**：使用 `Map<RankingType, SpotListItem[]>` 做本地缓存。切换 Tab 时检查缓存，有则直接渲染，无则请求。

**备选**：
- A) 每次切换都请求 → 浪费网络，体验差
- B) 页面加载时并行请求三种 → 浪费数据，用户可能只看一个 Tab
- C) **选中**：按需 + 缓存 → 平衡方案

**理由**：后端已有 Redis 缓存，即使重复请求也很快，但前端避免无谓请求更优。Map 缓存简单可靠，无需引入额外状态管理。

### D3: 排行榜列表项组件 — 内联在 page.tsx 中

**选择**：排行榜列表项直接写在 `page.tsx` 中，不单独抽取 `_components/RankingItem.tsx`。

**理由**：列表项结构简单（一行卡片），且只在此页面使用，DRY 规则下第一次不抽。如未来有第二处使用再提炼。

### D4: 复用 SpotListItem 类型

**选择**：`fetchRanking` 返回 `SpotListItem[]`，直接复用 `lib/api/spots.ts` 中已有类型。

**理由**：后端 `SpotResponse` 比 `SpotListItem` 多了 `description`、`gallery` 等字段，但 TypeScript 结构类型系统允许多余字段存在。排行榜只展示列表所需字段，无需新建类型。

### D5: formatCount 复用

**选择**：从 `spots/_components/SpotCard.tsx` 导入已有的 `formatCount` 函数来格式化浏览量和收藏数。

**理由**：函数已 export，功能完全匹配（数字 → "12.5k" 格式），无需重复实现。

## Risks / Trade-offs

- **[风险] 后端返回的 SpotResponse 字段比 SpotListItem 多** → TypeScript 结构类型兼容，多余字段不影响。若未来 SpotListItem 新增必填字段，fetchRanking 需同步更新。
- **[取舍] top=50 一次渲染 50 个列表项** → 数据量小（每项约 200 bytes），DOM 节点约 50 行，不需要虚拟滚动。
- **[风险] HotSpotsSlot "See all" 链接更新后现有测试可能失败** → 检查并更新 `HotSpotsSlot.test.tsx` 中对 href 的断言。
