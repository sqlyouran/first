## 1. Mock 数据层

- [x] 1.1 新建 `lib/mock/spots.ts`：定义 `MockSpot` 类型 + 15 条 mock 数据（覆盖 8 个城市：Beijing/Shanghai/Chengdu/Xi'an/Hangzhou/Guilin/Lijiang/Xiamen），每条包含 id, name, name_zh, slug, cover_image, tags, city_id, city_name, rating(3.5-5.0), view_count, bookmark_count
- [x] 1.2 导出 `mockSpots` 数组 + `mockCities` 从 mockSpots 提取去重城市列表 `{ id, name }`
- [x] 1.3 新建 `lib/mock/spots.test.ts`：验证 mockSpots 长度 = 15、mockCities 覆盖 8 个城市、所有字段非空

## 2. API 类型定义 + mock fetchSpots

- [x] 2.1 新建 `lib/api/spots.ts`：定义 `SpotListItem` 接口（字段 snake_case 对齐后端 SpotResponse）、`SpotSortType` 类型、`SpotListData` 接口（items, total, page, size, has_more）、`SpotListParams` 接口（page?, size?, cityId?, sort?）
- [x] 2.2 实现 `fetchSpots(params: SpotListParams): Promise<ApiResponse<SpotListData>>`：内部从 mockSpots 筛选（cityId）+ 排序（sort）+ slice（offset 分页），模拟 300ms 延迟
- [x] 2.3 新建 `lib/api/spots.test.ts`：验证 fetchSpots 返回正确结构、cityId 筛选生效、sort 排序生效、分页 has_more 正确

## 3. SpotCard 组件

- [x] 3.1 新建 `app/spots/_components/SpotCard.tsx`：Card 容器 + 封面图 `aspect-[4/3] bg-cover bg-center bg-slate-100` + 评分浮层（图片右下角 `absolute bottom-2 right-2` 深色半透明背景 + Star 图标 + 数字）
- [x] 3.2 卡片内容区：城市 Badge（MapPin 图标 + cityName）、英文名 `text-lg font-semibold text-slate-900`、中文名 `text-sm text-slate-500`、标签 Badge 列表
- [x] 3.3 卡片底部统计：Eye 图标 + view_count + Bookmark 图标 + bookmark_count，`text-sm text-slate-500`，大数字格式化（>999 → 1.2k）
- [x] 3.4 卡片交互：`overflow-hidden transition-shadow hover:shadow-lg`
- [x] 3.5 新建 `app/spots/_components/SpotCard.test.tsx`：验证 DOM 结构（data-testid 或角色查询）、评分渲染、标签渲染、统计数字格式化

## 4. SpotCardSkeleton 骨架屏

- [x] 4.1 新建 `app/spots/_components/SpotCardSkeleton.tsx`：Card + Skeleton 组合（aspect-[4/3] 图片占位 + 文字占位 × 3 + Badge 占位 × 2）

## 5. 列表页

- [x] 5.1 新建 `app/spots/page.tsx`：`"use client"` 页面，状态 `items: SpotListItem[]` + `page: number` + `hasMore: boolean` + `isLoading: boolean` + `isLoadingMore: boolean` + `cityId: string | null` + `sort: SpotSortType`
- [x] 5.2 页面头部：标题"探索景点" + 副标题"发现中国最值得探索的目的地"
- [x] 5.3 城市筛选：shadcn `<Select>` 下拉框，选项 = "全部城市" + mockCities 列表，变化时触发 `loadFirst()`
- [x] 5.4 排序 Tab：4 个按钮（最新 / 评分最高 / 最热 / 最多收藏），选中态 `bg-blue-50 text-blue-700`，变化时触发 `loadFirst()`
- [x] 5.5 卡片网格：`grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3`，渲染 SpotCard
- [x] 5.6 无限滚动：IntersectionObserver 监听 sentinel div，触底调用 `loadMore()`（page++），新 items 追加
- [x] 5.7 四态覆盖：Loading 骨架屏 × 6 / Content 卡片网格 / Empty 居中图标 + 引导文案 / Error 错误描述 + 重试按钮
- [x] 5.8 底部 UI：`isLoadingMore` 显示 3 张骨架屏，`!hasMore && items.length > 0` 显示"已经到底啦"，sentinel div
- [x] 5.9 新建 `app/spots/page.test.tsx`：验证页面标题渲染、排序 Tab 存在（4个）、城市筛选 Select 存在、空列表提示

## 6. 验收

- [x] 6.1 `cd frontend && npm test` 全绿
- [ ] 6.2 手动验证：景点列表页城市筛选 + 排序切换 + 无限滚动 + 卡片视觉效果
