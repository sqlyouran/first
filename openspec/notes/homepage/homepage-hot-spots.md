# homepage-hot-spots Spec

> 路径：`openspec/specs/homepage/homepage-hot-spots.md`
> 承接挂载位：`homepage-shell` 在 `app/page.tsx` 第 5 个 region 提供的 `data-region="hot-spots"` 槽位
> 实现位置：`frontend/app/regions/HotSpotsSlot.tsx`
> 数据：本期 mock，TS 类型同时作为后续 `api-hot-spots` 单元的契约占位

## 0. 前置依赖

依赖 `frontend-styling-stack`（待 propose）引入 Tailwind + shadcn/ui。封面图使用 `next/image`，资产置于 `frontend/public/images/spots/`。

---

## 1. 模块边界

### 1.1 In Scope

- 渲染 **6–8 张景点城市卡片**，按 **浏览量** 降序
- 每张卡片：**封面图（next/image）** + **城市名** + **浏览量数字** + **跳转链接** `/spots/<slug>`
- 响应式：`< 768px` 1 列 / `≥ 768px` 2 列 / `≥ 1024px` 3 或 4 列
- 区域顶部 `<h2>` 小标题"热门景点"
- mock 数据驱动，TS 类型作为后续 API 契约
- 数据为空 / 不足 6 条的降级展示

### 1.2 Out of Scope

- **真实后端 API**（属独立单元 `api-hot-spots`）
- 景点详情页（`/spots/<slug>` 路由本身）
- 分页 / 加载更多
- 卡片收藏 / 计数交互
- 浏览量实时刷新
- 个性化推荐 / 用户维度排序
- 城市筛选 / 地图视图

---

## 2. 核心场景

### Scenario 1：渲染 6–8 张按浏览量降序（happy path）

- **GIVEN** mock 数组长度 ∈ `[6, 8]`
- **WHEN** 渲染 `HotSpotsSlot`
- **THEN** 区域内含 6 / 7 / 8 张卡片（与输入长度一致）
- **AND** 顺序按 `viewCount` 字段降序
- **AND** 第 1 张的 `viewCount` ≥ 最后 1 张

### Scenario 2：mock 多于 8 条（截断）

- **GIVEN** mock 数组长度 ≥ 9
- **WHEN** 渲染
- **THEN** 仅渲染前 8 张（按 `viewCount` 降序排序后取前 8）

### Scenario 3：mock 少于 6 条（降级）

- **GIVEN** mock 数组长度 ∈ `[1, 5]`
- **WHEN** 渲染
- **THEN** 全部展示，按降序
- **AND** 不出现占位骨架或"加载中"

### Scenario 4：数据为空（空态）

- **GIVEN** mock 为 `[]`
- **WHEN** 渲染
- **THEN** 区域显示空态文案 `"还没有景点数据，先去看城市攻略吧"` + 跳转 `/spots` 链接
- **AND** 不渲染任何卡片
- **AND** `<h2>` 仍渲染

### Scenario 5：响应式

- **WHEN** 视口 `< 768px`
- **THEN** 单列纵排（`grid-cols-1`）
- **WHEN** 视口 `768px–1023px`
- **THEN** 双列（`md:grid-cols-2`）
- **WHEN** 视口 `≥ 1024px`
- **THEN** 4 列（`lg:grid-cols-4`），数据 < 4 时左对齐不撑满

### Scenario 6：封面加载失败（异常）

- **GIVEN** 某 `coverSrc` 404
- **WHEN** 浏览器渲染
- **THEN** next/image fallback 行为：保留占位尺寸，朗读 `alt`
- **AND** 卡片其余信息仍可见
- **AND** 卡片仍可点击

### Scenario 7：SSR 真实存在

- **WHEN** `curl /`
- **THEN** HTML 直接包含 ≥ 6 个城市名文本与对应 `<img>`

### Scenario 8：mock 数据自检（构建期）

- **GIVEN** mock 中存在 `viewCount < 0` 或 `slug` 重复
- **WHEN** 单元测试执行
- **THEN** 用例失败

---

## 3. 数据结构

### 3.1 类型定义（同时作为后续 API 契约）

```ts
// frontend/lib/mocks/hot-spots.ts
export type HotSpot = {
  /** URL slug，全小写 */
  slug: string;
  /** 城市/景点中文名 */
  cityName: string;
  /** 封面图路径，相对 public/，如 /images/spots/guilin.webp */
  coverSrc: string;
  /** 封面 alt 文本 */
  coverAlt: string;
  /** 浏览量（累计），整数 ≥ 0 */
  viewCount: number;
};
```

### 3.2 mock 数据约束

```ts
export const HOT_SPOTS_MOCK: readonly HotSpot[] = [
  // 建议 6–8 条；超过 8 时由组件截断
];
```

| 字段 | 约束 |
|---|---|
| `slug` | `^[a-z][a-z0-9-]{1,40}$`，全数组唯一 |
| `cityName` | CJK 2–8 字 |
| `coverSrc` | 必须以 `/images/spots/` 起首，扩展名 `.webp` 或 `.jpg` |
| `coverAlt` | 非空，长度 ≤ 60 |
| `viewCount` | 整数 ≥ 0 |

### 3.3 组件 Props

```ts
// frontend/app/regions/HotSpotsSlot.tsx
export type HotSpotsSlotProps = {
  /** 可选注入；默认使用 HOT_SPOTS_MOCK */
  spots?: readonly HotSpot[];
  /** 最多渲染数；默认 8 */
  maxCount?: number;
};
```

### 3.4 排序与截断契约

```ts
// frontend/app/regions/hot-spots.utils.ts
export function sortAndTruncate(
  spots: readonly HotSpot[],
  maxCount: number,
): HotSpot[] {
  return [...spots]
    .sort((a, b) => {
      if (b.viewCount !== a.viewCount) return b.viewCount - a.viewCount;
      return a.slug.localeCompare(b.slug);
    })
    .slice(0, maxCount);
}
```

### 3.5 数据来源

- **本期**：`frontend/lib/mocks/hot-spots.ts` 静态 mock
- **后续**：`api-hot-spots` 落地后改为 `await fetchFromBackend('/api/hot-spots')`，返回 JSON 即 `HotSpot[]`
- 本单元**不**改 `lib/backend.ts`、**不**新增 Route Handler

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 结构

- [ ] `HotSpotsSlot.tsx` 是 Server Component，根节点 `<section data-region="hot-spots">`
- [ ] section 含 `<h2>` 小标题"热门景点"
- [ ] 数据非空时含 ≤8 张卡片，每张为 `<a>` 包裹的 shadcn `<Card>`
- [ ] 数据为空时含空态文案 + `<a href="/spots">`

### 4.2 排序与截断

- [ ] `sortAndTruncate` 单元测试：
  - [ ] 长度 ≥ 9 截到前 8
  - [ ] 长度 ∈ [6,8] 全保留
  - [ ] 长度 < 6 全保留
  - [ ] viewCount 相同时按 slug 升序

### 4.3 视觉与响应式

- [ ] 容器 class：`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6`
- [ ] 卡片宽高比 `aspect-[4/3]` 或 `aspect-square`
- [ ] 封面 next/image `fill` + `sizes`
- [ ] 城市名叠加在封面底部，半透明黑色渐变层保证文字对比度
- [ ] 浏览量带 `<Eye />` 图标 + 数字（用 `Intl.NumberFormat` 格式化，如 `12.3k`）

### 4.4 next/image 使用

- [ ] 所有封面 `next/image` 渲染，`fill` 模式
- [ ] `alt` 来自 `coverAlt`，非空
- [ ] 头 2 张 `priority`，其余默认 lazy

### 4.5 链接与 a11y

- [ ] 整张卡片由单个 `<a href="/spots/<slug>">` 包裹
- [ ] `<a>` 上 `aria-label="查看<cityName>攻略，浏览量<viewCount>"`
- [ ] focus-visible ring 可见
- [ ] WCAG AA 文字对比度通过

### 4.6 测试（TDD）

- [ ] `hot-spots.utils.test.ts`：覆盖 4 条排序/截断用例
- [ ] `HotSpotsSlot.test.tsx`：
  - [ ] 用例：mock 8 条 → 渲染 8 张
  - [ ] 用例：mock 4 条 → 渲染 4 张
  - [ ] 用例：mock 12 条 → 仅渲染前 8 张
  - [ ] 用例：mock 为空 → 空态文案 + 跳转链接
  - [ ] 用例：每张 href === `/spots/<slug>`
  - [ ] 用例：每张含 `<img>` 且 `alt` 非空
- [ ] `app/page.test.tsx` 仍 GREEN

### 4.7 端到端

- [ ] `npm run build` 通过
- [ ] `npm test` 全绿
- [ ] `curl /` HTML 含 ≥ 6 个城市名文本与 `<img>`
- [ ] Lighthouse a11y ≥ 95、Performance ≥ 80

### 4.8 资产与边界守护

- [ ] `frontend/public/images/spots/` 下存在 mock 引用的全部封面资产
- [ ] 未新增 `route.ts` / `route.tsx`
- [ ] `lib/backend.ts` 未被本单元修改
- [ ] `backend/` submodule 指针未变
- [ ] 未引入网络请求库

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `data-region="hot-spots"` 挂载位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | Tailwind + shadcn/ui + lucide-react |
| **本单元定义、后续单元消费** | `api-hot-spots`（未来 propose） | 共享 `HotSpot` 类型；mock 替换为 `await fetchFromBackend('/api/hot-spots')` |
| **本单元先于** | `spot-detail-page`（未来 propose） | 跳转目标 `/spots/<slug>` 由其承接 |
| **与本单元正交** | `homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-ai-launcher` | 各自独立 Slot |
