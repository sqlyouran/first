# homepage-city-grid Spec

> 路径：`openspec/specs/homepage/homepage-city-grid.md`
> 承接挂载位：`homepage-shell` 在 `app/page.tsx` 第 3 个 region 提供的 `data-region="city-grid"` 槽位
> 实现位置：`frontend/app/regions/CityGridSlot.tsx`

## 0. 前置依赖

依赖 `frontend-styling-stack`（待 propose）引入 Tailwind + shadcn/ui。城市图标使用 `next/image` 优化的 PNG/WebP 资产，置于 `frontend/public/images/cities/`。

---

## 1. 模块边界

### 1.1 In Scope

- 渲染恰好 **8 个 MVP 城市图标项**
- 每个城市项：**图标（next/image）** + **城市名** + **跳转链接** `/city/<slug>`
- 响应式网格：`< 640px` 4 列 / `≥ 768px` 4 列加大间距 / `≥ 1024px` 8 列单行
- 整图标块可键盘聚焦，整块作为可点击链接（`<a>` 包裹）
- next/image 显式宽高，启用 lazy loading（首屏外的城市卡片）

### 1.2 Out of Scope

- 城市攻略页（`/city/<slug>`）本身的内容渲染
- 城市搜索 / 筛选 / 排序切换
- 用户自定义"我的常去城市"
- 城市数据动态拉取（本单元 8 城为静态常量）
- 多语言城市名

---

## 2. 核心场景

### Scenario 1：桌面端单行 8 列（happy path）

- **WHEN** 视口 `≥ 1024px`
- **THEN** `data-region="city-grid"` 区域含 8 个 `<a>` 包裹的城市项
- **AND** 8 项以 `grid grid-cols-8` 单行排列
- **AND** 每项 `aspect-square`，图标居中

### Scenario 2：移动端 4×2 网格

- **WHEN** 视口 `< 640px`
- **THEN** 城市项以 `grid grid-cols-4` 排列，第 5–8 项换行
- **AND** 项目间距 `gap-3`

### Scenario 3：链接 href 形如 `/city/<slug>`

- **WHEN** 渲染完成
- **THEN** 8 个 `<a>` 的 href 分别为 `/city/<slug>`，slug 来自常量数组
- **AND** slug 与城市名一一对应（如 `beijing` ↔ 北京）

### Scenario 4：图标加载失败（异常路径）

- **GIVEN** 某城市图标资产 404
- **WHEN** 浏览器渲染
- **THEN** next/image fallback 行为：保留容器尺寸，朗读 `alt`
- **AND** 城市名文本仍可见
- **AND** 整块仍可点击跳转

### Scenario 5：键盘可达

- **WHEN** 用户连续按 `Tab`
- **THEN** 焦点依次落到 8 个 `<a>` 上
- **AND** focus ring 可见
- **AND** `Enter` 触发跳转

### Scenario 6：SSR 真实存在

- **WHEN** `curl /`
- **THEN** HTML 直接包含 8 个城市名文本
- **AND** 包含 8 个 `<img>`（next/image 服务端 emit）

### Scenario 7：常量长度守护（构建期）

- **GIVEN** 城市常量数组长度不为 `8`
- **THEN** TypeScript 类型 `readonly CityEntry[8]`（用 tuple 类型或 length-checked）编译失败

---

## 3. 数据结构

### 3.1 类型定义

```ts
// frontend/app/regions/city-grid.constants.ts
export type CityEntry = {
  /** URL slug，全小写英文 */
  slug: string;
  /** 城市中文名 */
  name: string;
  /** 图标资产路径，相对 public/，如 /images/cities/beijing.webp */
  iconSrc: string;
  /** 图标 alt 文本，无障碍必填 */
  iconAlt: string;
};

/** 长度恰好 8 的元组 */
export type CityGridConfig = readonly [
  CityEntry, CityEntry, CityEntry, CityEntry,
  CityEntry, CityEntry, CityEntry, CityEntry,
];
```

### 3.2 默认常量

```ts
export const CITIES: CityGridConfig = [
  { slug: 'beijing',   name: '北京', iconSrc: '/images/cities/beijing.webp',   iconAlt: '北京天安门图标' },
  { slug: 'shanghai',  name: '上海', iconSrc: '/images/cities/shanghai.webp',  iconAlt: '上海东方明珠图标' },
  { slug: 'xian',      name: '西安', iconSrc: '/images/cities/xian.webp',      iconAlt: '西安钟楼图标' },
  { slug: 'chengdu',   name: '成都', iconSrc: '/images/cities/chengdu.webp',   iconAlt: '成都熊猫图标' },
  { slug: 'guilin',    name: '桂林', iconSrc: '/images/cities/guilin.webp',    iconAlt: '桂林山水图标' },
  { slug: 'lijiang',   name: '丽江', iconSrc: '/images/cities/lijiang.webp',   iconAlt: '丽江古城图标' },
  { slug: 'hangzhou',  name: '杭州', iconSrc: '/images/cities/hangzhou.webp',  iconAlt: '杭州西湖图标' },
  { slug: 'zhangjiajie', name: '张家界', iconSrc: '/images/cities/zhangjiajie.webp', iconAlt: '张家界山峰图标' },
] as const;
```

### 3.3 组件 Props

```ts
// frontend/app/regions/CityGridSlot.tsx
export type CityGridSlotProps = {
  /** 可选注入用于测试；默认使用 CITIES 常量 */
  cities?: CityGridConfig;
};
```

### 3.4 约束摘要

| 字段 | 类型 | 必填 | 约束 |
|---|---|---|---|
| `slug` | `string` | 是 | `^[a-z][a-z0-9-]{1,30}$`，全数组内唯一 |
| `name` | `string` | 是 | CJK 2–6 字，单行 |
| `iconSrc` | `string` | 是 | 必须以 `/images/cities/` 起首，扩展名 `.webp` 或 `.png` |
| `iconAlt` | `string` | 是 | 非空，长度 ≤ 30 |

### 3.5 数据来源

- **静态常量**：编译期定值，构建后不再变更
- **不接 API**、**不引入 mock**

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 结构

- [ ] `CityGridSlot.tsx` 是 Server Component，根节点 `<section data-region="city-grid">`
- [ ] section 内含 8 个 `<a>` 包裹的图标项
- [ ] 项顺序与 `CITIES` 数组一致

### 4.2 视觉与响应式

- [ ] 容器 class：`grid grid-cols-4 md:grid-cols-4 lg:grid-cols-8 gap-3 md:gap-4 lg:gap-6`
- [ ] 每项 `aspect-square`，图标尺寸约 `h-12 w-12 md:h-16 md:w-16 lg:h-20 lg:w-20`
- [ ] 城市名 `text-xs md:text-sm`，居中于图标下方
- [ ] hover 态：图标轻微放大或颜色加深（无 transform 动画）

### 4.3 next/image 使用

- [ ] 8 张图标均通过 `next/image` 渲染，显式 `width` `height`
- [ ] `alt` 来自常量 `iconAlt`，非空
- [ ] 头 4 张（视口可见）`priority`（如 `loading="eager"`）；后 4 张默认 lazy

### 4.4 链接与交互

- [ ] 整块由单个 `<a>` 包裹，`<a>` 上有 `aria-label="进入<城市名>攻略页"`
- [ ] 8 个 href 等于 `/city/<slug>`，与常量 slug 严格匹配

### 4.5 无障碍

- [ ] 焦点态可见 focus ring
- [ ] alt 文本被屏幕阅读器朗读
- [ ] 颜色对比度 WCAG AA 通过

### 4.6 测试（TDD）

- [ ] `CityGridSlot.test.tsx`：
  - [ ] RED → GREEN：渲染恰好 8 项
  - [ ] 用例：href 与常量一一对应
  - [ ] 用例：每项含 `<img>` 且 `alt` 非空
  - [ ] 用例：`cities` props 注入时覆盖默认
- [ ] `app/page.test.tsx` 仍 GREEN

### 4.7 端到端

- [ ] `npm run build` 通过
- [ ] `npm test` 全绿
- [ ] `curl /` HTML 含 8 个城市名文本与 8 个 `<img>`
- [ ] Lighthouse a11y ≥ 95，Performance（LCP 元素若为 hero 不受影响）≥ 80

### 4.8 资产与边界守护

- [ ] `frontend/public/images/cities/` 下存在 8 张对应图标资产
- [ ] 未新增 `route.ts` / `route.tsx`
- [ ] `backend/` submodule 指针未变

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `data-region="city-grid"` 挂载位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | Tailwind + shadcn/ui |
| **本单元先于** | 后续 `city-detail-page`（待 propose） | 跳转目标 `/city/<slug>` 页面由其承接，本单元只占 href |
| **与本单元正交** | `homepage-hero` / `homepage-feature-nav` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher` | 各自独立 Slot |
| **本单元不依赖** | 任何后端 API、任何 mock | 全静态 |
