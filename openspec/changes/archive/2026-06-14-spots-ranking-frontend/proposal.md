## Why

后端景点排行榜接口（`GET /api/spots/ranking?type={heat|rating|bookmark}&top={top}`）已完成并带 Redis 缓存，但前端尚无对应的排行榜页面，用户无法浏览完整的景点榜单。同时首页 HotSpots 区域的"See all"链接仍指向占位 `#`，需要接入真实路由。

## What Changes

- 新增 `frontend/app/spots/ranking/page.tsx`：景点排行榜页面，三 Tab 切换（热门/高分/收藏），top=50 列表，前三名金银铜高亮，点击跳转景点详情
- 新增 `frontend/lib/api/spots.ts` 中的 `fetchRanking()` API 封装函数，调用后端 `GET /api/spots/ranking`
- 新增 `frontend/app/spots/ranking/page.test.tsx`：排行榜页面单元测试
- 更新 `frontend/app/regions/HotSpotsSlot.tsx`：将"See all →"链接的 `href` 从占位 `#` 改为 `/spots/ranking`

## Capabilities

### New Capabilities

- `spots-ranking-frontend`: 景点排行榜前端页面，包含三 Tab 切换、排名列表（前三名高亮）、按需请求 + 本地缓存数据策略、点击跳转详情

### Modified Capabilities

- `homepage-hot-spots`: 将"See all →"链接 href 从占位 `#` 更新为 `/spots/ranking`

## Impact

- **前端新增文件**：`app/spots/ranking/page.tsx`、`app/spots/ranking/page.test.tsx`
- **前端修改文件**：`lib/api/spots.ts`（新增 `fetchRanking` 函数）、`app/regions/HotSpotsSlot.tsx`（更新链接）
- **后端**：无改动，已有 `GET /api/spots/ranking` 接口可直接消费
- **依赖**：不引入新 npm 依赖（复用现有 lucide-react、shadcn/ui 组件）
