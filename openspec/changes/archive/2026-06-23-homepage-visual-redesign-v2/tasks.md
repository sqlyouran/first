## 1. page.tsx — 挂载 AiLauncherSlot

- [x] 1.1 在 `frontend/app/page.tsx` 中添加 `import AiLauncherSlot from "./regions/AiLauncherSlot"` 并在 JSX 末尾插入 `<AiLauncherSlot />`

## 2. featureNav.data.ts — 新增 description 字段

- [x] 2.1 在 `frontend/app/regions/featureNav.data.ts` 的 `FeatureNavItem` 类型中新增 `description: string` 字段
- [x] 2.2 为 4 个 item 各填写一句英文描述（Cities: "Browse iconic and off-map destinations"，Stories: "Deep-dive itineraries from real travelers"，Hidden Spots: "Discover places no guidebook mentions"，Plan with AI: "Build your perfect itinerary in minutes"）

## 3. HeroSlot — 品牌感提升（TDD）

- [x] 3.1 在 `HeroSlot.test.tsx` 中新增失败测试：验证 section 存在 CTA 按钮（通过 `hero.ctaLabel` 文字匹配），以及容器 className 包含 `px-8`
- [x] 3.2 修改 `HeroSlot.tsx`：容器高度改为 `min-h-[520px] h-[70vh]`，内容容器侧边距改为 `px-8 sm:px-12 lg:px-16`，`max-w-5xl` 改为 `max-w-6xl`
- [x] 3.3 在 `HeroSlot.tsx` 搜索框行下方（`mt-4`）新增 `<a href={hero.ctaHref}>`，样式 `inline-block rounded-md bg-blue-700 hover:bg-blue-800 px-6 py-3 text-sm font-semibold text-white transition-colors`，文字使用 `hero.ctaLabel`
- [x] 3.4 运行 `npm test -- HeroSlot` 验证测试通过（GREEN）

## 4. FeatureNavSlot — 探索感强化（TDD）

- [x] 4.1 在 `FeatureNavSlot.test.tsx` 中新增失败测试：验证每个卡片展示 `description` 文字（取 data 中任一 item 的 description 文本匹配），以及 className 包含 `border-l-4`（hover 边框存在于 DOM）
- [x] 4.2 修改 `FeatureNavSlot.tsx`：卡片 `<a>` className 新增 `border-l-4 border-l-transparent hover:border-l-blue-700` 以实现 hover 左边框
- [x] 4.3 在 `FeatureNavSlot.tsx` 的 `<span>` 下方新增 `<span className="text-sm text-slate-500 text-center">{item.description}</span>`
- [x] 4.4 运行 `npm test -- FeatureNavSlot` 验证测试通过（GREEN）

## 5. CityGridSlot — 背景层次与图片 overlay（TDD）

- [x] 5.1 在 `CityGridSlot.test.tsx` 中新增失败测试：验证 section className 包含 `from-slate-50`，以及 Badge 在图片容器内（通过 DOM 层级关系或 `within` 验证）
- [x] 5.2 修改 `CityGridSlot.tsx`：section 新增 `bg-gradient-to-b from-slate-50 to-white`，侧边距改为 `px-8 sm:px-12 lg:px-16`
- [x] 5.3 在城市图片 div 上新增 `relative`，内部添加绝对定位 Badge：`<span className="absolute top-3 right-3 rounded-full bg-white/90 px-2 py-0.5 text-xs font-medium text-slate-700">{item.bestSeason}</span>`
- [x] 5.4 移除文字区 `<div className="p-5">` 中的 `<Badge variant="secondary">` bestSeason 元素及其 flex 容器行（保留城市名 h3、中文名 p、描述 p）
- [x] 5.5 运行 `npm test -- CityGridSlot` 验证测试通过（GREEN）

## 6. HotPostsSlot — 摄影感增强（TDD）

- [x] 6.1 在 `HotPostsSlot.test.tsx` 中新增失败测试：验证大卡片图片容器内存在 `from-transparent` 类名的 overlay 元素，以及小卡片图片容器使用 `aspect-square`
- [x] 6.2 修改 `HotPostsSlot.tsx` 大卡片：图片容器 div 新增 `relative`，内部添加 `<div className="absolute inset-0 bg-gradient-to-b from-transparent to-black/40" aria-hidden="true" />`
- [x] 6.3 修改 `HotPostsSlot.tsx` 小卡片：图片容器从 `h-24 w-24 flex-shrink-0 rounded` 改为 `aspect-square w-24 flex-shrink-0 rounded overflow-hidden`
- [x] 6.4 内容容器侧边距改为 `px-8 sm:px-12 lg:px-16`
- [x] 6.5 运行 `npm test -- HotPostsSlot` 验证测试通过（GREEN）

## 7. HotSpotsSlot — 标题文案与背景（TDD）

- [x] 7.1 在 `HotSpotsSlot.test.tsx` 中新增失败测试：验证标题文字为 `"Hidden Gems"`，以及 section className 包含 `bg-white`
- [x] 7.2 修改 `HotSpotsSlot.tsx`：section 新增 `bg-white`，侧边距改为 `px-8 sm:px-12 lg:px-16`，标题文字改为 `"Hidden Gems"`
- [x] 7.3 运行 `npm test -- HotSpotsSlot` 验证测试通过（GREEN）

## 8. 全量测试验证

- [x] 8.1 在 `frontend/` 目录运行 `npm test` 确认所有测试通过（无红灯）
- [x] 8.2 运行 `npm run build` 确认前端构建无报错
