## 1. API 封装层

- [x] 1.1 在 `frontend/lib/api/spots.ts` 中新增 `RankingType` 类型（`"heat" | "rating" | "bookmark"`）和 `RankingData` 接口（`{ type, items: SpotListItem[], request_id }`）
- [x] 1.2 在 `frontend/lib/api/spots.ts` 中新增 `fetchRanking(type, top?)` 函数，调用 `GET /api/spots/ranking`，返回 `ApiResponse<RankingData>`，处理 network/server error

## 2. 排行榜页面 — 测试先行

- [x] 2.1 创建 `frontend/app/spots/ranking/page.test.tsx`，编写排行榜页面核心测试用例：渲染页面标题、三个 Tab 按钮存在、默认激活热门 Tab
- [x] 2.2 添加测试用例：Tab 切换行为（点击高分/收藏 Tab 后激活对应 Tab 并请求对应 type）
- [x] 2.3 添加测试用例：前三名金银铜高亮（第 1/2/3 项有奖牌图标和对应颜色，第 4 项无）
- [x] 2.4 添加测试用例：当前排序维度高亮（热门 Tab 时 view_count 高亮，高分 Tab 时 rating 高亮，收藏 Tab 时 bookmark_count 高亮）
- [x] 2.5 添加测试用例：四态覆盖（loading 骨架屏、empty 空态、error 错误 + 重试按钮）
- [x] 2.6 添加测试用例：点击列表项跳转 `/spots/{slug}`、返回链接指向 `/spots`

## 3. 排行榜页面 — 实现

- [x] 3.1 创建 `frontend/app/spots/ranking/page.tsx`（`"use client"`），实现页面骨架：背景渐变 + max-w-5xl 容器 + 页面标题"景点排行榜" + 返回 `/spots` 导航链接
- [x] 3.2 实现三 Tab 切换 UI（热门/高分/收藏），使用 useState 管理 activeTab，Tab 按钮样式区分激活/未激活
- [x] 3.3 实现 fetchRanking 调用 + Map 缓存逻辑：按需请求，切回已缓存 Tab 不重复请求
- [x] 3.4 实现排行榜列表渲染：排名序号 + 封面图（aspect-[4/3]）+ 景点中文名 + 城市名 + 三项指标数据
- [x] 3.5 实现前三名高亮：第 1 名 Trophy 图标 + text-yellow-500，第 2/3 名 Medal 图标 + text-slate-400/text-amber-700，第 4+ 名纯数字 + text-slate-600
- [x] 3.6 实现当前排序维度高亮：根据 activeTab 决定哪个指标使用 font-semibold text-blue-700，其余用 text-slate-500
- [x] 3.7 实现四态覆盖：Loading（5+ 个 Skeleton 行）、Empty（居中图标 + "暂无排行数据"）、Error（错误文案 + 重试按钮）、Content（列表）
- [x] 3.8 每个列表项使用 Next.js `<Link>` 组件跳转至 `/spots/{slug}`

## 4. 首页 HotSpots 导航入口更新

- [x] 4.1 更新 `frontend/app/regions/HotSpotsSlot.tsx`：将 "See all →" 链接 href 从 `#all-spots` 改为 `/spots/ranking`
- [x] 4.2 更新 `frontend/app/regions/HotSpotsSlot.test.tsx`：将 "See all" 链接断言从 `#all-spots` 改为 `/spots/ranking`

## 5. 验证

- [x] 5.1 全部前端测试通过（`cd frontend && npm test`）
