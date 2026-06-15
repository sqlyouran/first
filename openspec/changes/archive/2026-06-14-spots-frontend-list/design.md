## Context

后端 `spots-backend-api` 变更已完成，提供：
- `GET /api/spots?page=&size=&city_id=&sort=` — offset 分页列表，sort 支持 `latest` / `rating` / `viewCount` / `bookmarkCount`
- `SpotResponse` 字段：id, name, name_zh, slug, description, description_zh, cover_image, gallery, tags, city_id, city_name, status, rating, view_count, bookmark_count, created_at, updated_at

前端已有类似模式可参考：
- `app/posts/page.tsx`：IntersectionObserver 无限滚动 + 排序 Tab
- `app/regions/HotSpotsSlot.tsx`：景点卡片布局（但仅静态展示）

约束：Next.js 16 + React 19 + TypeScript；Tailwind + shadcn/ui + lucide-react；mock 先行，后续无缝切换真实 API。

## Goals / Non-Goals

**Goals:**
- 定义 Spot TypeScript 接口，字段对齐后端 SpotResponse
- 提供 15 条高质量 mock 数据，覆盖 8 个城市
- 列表页支持城市筛选 + 4 种排序 + 无限滚动
- SpotCard 展示封面图、评分、城市、中英文名、标签、统计数据
- 四态覆盖：Loading / Content / Empty / Error

**Non-Goals:**
- 不实现景点详情页（mock 阶段卡片不做跳转）
- 不调用真实后端 API（纯 mock）
- 不实现"回到顶部"按钮
- 不引入虚拟滚动

## Decisions

### D1: 城市筛选数据源 — 从 mockSpots 提取

**决策**：城市筛选器的选项从 `mockSpots` 数据中 `reduce` 出唯一城市列表，而非单独维护城市 mock 数据。

```typescript
// lib/mock/spots.ts
export const mockCities = Array.from(
  new Map(mockSpots.map(s => [s.city_id, { id: s.city_id, name: s.city_name }])).values()
);
```

**理由**：数据只有一份来源，筛选选项自动适配 mock 数据覆盖的城市，避免两份 mock 不一致。

**替代方案**：调用真实 `/api/cities` → 混合 mock 和真实 API 增加复杂度，mock 阶段不必要。

### D2: 分页模式 — offset 模拟无限滚动

**决策**：mock 函数模拟 offset 分页行为（page++），前端使用 IntersectionObserver 触发加载下一页。

```typescript
// lib/api/spots.ts
export async function fetchSpots(params: SpotListParams): Promise<ApiResponse<SpotListData>> {
  const { page = 1, size = 12, cityId, sort = "latest" } = params;
  // 模拟网络延迟
  await new Promise(r => setTimeout(r, 300));
  // 从 mockSpots 筛选 + 排序 + slice
  let filtered = [...mockSpots];
  if (cityId) filtered = filtered.filter(s => s.city_id === cityId);
  filtered = sortBy(filtered, sort);
  const start = (page - 1) * size;
  const items = filtered.slice(start, start + size);
  return {
    status: 200,
    data: {
      items,
      total: filtered.length,
      page,
      size,
      has_more: start + size < filtered.length,
      request_id: "mock",
    },
  };
}
```

**理由**：贴近后端真实行为，后续切 API 只需替换函数体，页面逻辑不动。

### D3: SpotCard 评分浮层位置

**决策**：评分显示在封面图右下角，深色半透明背景 + Star 图标 + 数字。

```
┌──────────────────────┐
│                      │
│     封面图            │
│                      │
│            ┌───────┐ │
│            │ ★ 4.8 │ │
│            └───────┘ │
├──────────────────────┤
```

**理由**：评分是景点最重要的指标，放在图片区域视觉突出，不干扰下方文字信息。

### D4: 排序选项映射

**决策**：前端 4 个排序 Tab，值对齐后端 sort 参数。

```typescript
const SORT_OPTIONS = [
  { value: "latest", label: "最新" },
  { value: "rating", label: "评分最高" },
  { value: "viewCount", label: "最热" },
  { value: "bookmarkCount", label: "最多收藏" },
] as const;
```

### D5: 卡片点击行为

**决策**：mock 阶段卡片不做跳转（详情页不存在），仅展示静态信息。后续 `spots-frontend-detail` 变更时添加 `<Link>` 包裹。

**理由**：YAGNI，当前只需列表页，详情页是独立变更。

### D6: 默认 PAGE_SIZE

**决策**：`PAGE_SIZE = 12`，每页 12 条，3 列网格下恰好 4 行。

**理由**：视觉整齐，首次加载不会过多数据。

## Risks / Trade-offs

- **[mock 数据与后端不一致]** → mock 字段名和类型需严格对齐 `SpotResponse` JSON 格式（snake_case）。Mitigation：类型定义统一从 `lib/api/spots.ts` 导出，mock 数据使用该类型约束。
- **[无限滚动状态复杂]** → 筛选 + 排序组合变化时需正确重置分页状态。Mitigation：`cityId` 或 `sort` 变化时统一触发 `loadFirst()` 清空重载。
- **[图片加载失败白块]** → picsum.photos 可能加载失败。Mitigation：图片容器设置 `bg-slate-100` 兜底色。
