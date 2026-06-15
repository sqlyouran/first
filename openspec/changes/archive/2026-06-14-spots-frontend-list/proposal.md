## Why

后端景点 API 已完备（列表、详情、排行榜），但前端景点页面完全空白。需要先搭建景点列表页，让用户能浏览、筛选、排序景点。采用 mock 数据先行策略，确保前端开发不依赖后端运行，后续切换真实 API 只需替换 fetch 函数实现。

## What Changes

- **TypeScript 接口定义**：`lib/api/spots.ts` 新增 `SpotListItem`、`SpotSortType`、`SpotListData` 类型和 `fetchSpots()` 函数（mock 阶段）
- **Mock 数据**：`lib/mock/spots.ts` 新增 15 条景点假数据，覆盖 8 个城市，导出 `mockCities` 提取去重城市列表
- **列表页**：`app/spots/page.tsx` 实现城市筛选 + 排序 Tab + 卡片网格 + IntersectionObserver 无限滚动
- **SpotCard 组件**：封面图 + 评分浮层 + 城市位置 + 中英文名 + 标签 + 浏览/收藏统计

## Capabilities

### New Capabilities

- `spots-frontend-list`：景点列表页（mock 先行），包含筛选、排序、卡片网格、无限滚动

### Modified Capabilities

（无修改）

## Impact

**后端代码**：无变化

**前端代码**：
- `lib/api/spots.ts` — 新增 Spot 相关类型定义 + fetchSpots mock 函数
- `lib/mock/spots.ts` — 新增 15 条 mock 景点数据 + mockCities 提取逻辑
- `app/spots/page.tsx` — 新增景点列表页
- `app/spots/_components/SpotCard.tsx` — 新增景点卡片组件
- `app/spots/_components/SpotCardSkeleton.tsx` — 新增骨架屏组件

**API 契约**：
- 当前 mock 阶段不调用真实 API
- 后续切换时调用 `GET /api/spots?page=&size=&city_id=&sort=`
