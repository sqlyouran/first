## ADDED Requirements

### Requirement: Hero 区域响应式高度与双 CTA
HeroSlot 的容器高度 SHALL 使用 `min-h-[520px] h-[70vh]` 自适应方案（移动端不低于 520px，桌面端占视口 70%），内容区侧边距 SHALL 为 `px-8 sm:px-12 lg:px-16`。HeroSlot SHALL 同时展示搜索框（原有）和品牌 CTA 按钮（来自 `hero.data.ts` 的 `ctaLabel` / `ctaHref` 字段），CTA 按钮样式 SHALL 为 `bg-blue-700 hover:bg-blue-800 text-white`。

#### Scenario: 双 CTA 同时渲染
- **WHEN** 用户打开首页
- **THEN** 页面中同时存在搜索输入框和"Start Exploring"按钮

#### Scenario: 移动端高度自适应
- **WHEN** 视口宽度小于 768px
- **THEN** Hero 区域高度不低于 520px，不因内容被截断

---

### Requirement: FeatureNavSlot 副标题与 hover 品牌色
FeatureNavSlot 中每个功能卡片 SHALL 展示来自 `featureNav.data.ts` 的 `description` 字段作为副标题（`text-sm text-slate-500`）。卡片 hover 状态 SHALL 在左侧增加品牌色边框（`border-l-4 border-l-blue-700`），以替代原有单一阴影增强。

#### Scenario: 副标题渲染
- **WHEN** 用户浏览 FeatureNav 区域
- **THEN** 每个功能卡片均展示 icon、标题和 description 副标题三层内容

#### Scenario: hover 品牌色反馈
- **WHEN** 用户悬停在任一功能卡片上
- **THEN** 卡片左侧显示 4px 品牌蓝色边框

---

### Requirement: CityGridSlot 背景层次与图片 overlay Badge
CityGridSlot 的 section 元素 SHALL 包含 `bg-gradient-to-b from-slate-50 to-white` 背景渐变。城市卡片图片容器 SHALL 使用 `relative` 定位，`bestSeason` Badge SHALL 以绝对定位覆盖于图片右上角（`absolute top-3 right-3`），Badge 样式 SHALL 保障 WCAG AA 对比度（`bg-white/90 text-slate-700`）。文字区域中不再重复展示 `bestSeason` 信息。

#### Scenario: 背景渐变存在
- **WHEN** 用户浏览城市网格区域
- **THEN** section 元素带有 `from-slate-50 to-white` 渐变背景类名

#### Scenario: bestSeason badge 在图片上
- **WHEN** 城市卡片渲染完成
- **THEN** bestSeason badge 位于图片容器内（绝对定位），文字区域中没有独立的 badge 元素

---

### Requirement: HotPostsSlot 摄影感增强
HotPostsSlot 大卡片图片区容器 SHALL 为 `relative` 定位，内部 SHALL 有一个 `absolute inset-0 bg-gradient-to-b from-transparent to-black/40` 的渐变 overlay 层（`aria-hidden="true"`）。小卡片图片容器 SHALL 改用 `aspect-square` 比例控制，替换原有的 `h-24 w-24` 固定尺寸，以 `w-24 flex-shrink-0` 控制宽度。

#### Scenario: 大卡片图片渐变 overlay
- **WHEN** 大卡片渲染完成
- **THEN** 图片容器内存在 `from-transparent to-black/40` 渐变 overlay 元素

#### Scenario: 小卡片 aspect-ratio 容器
- **WHEN** 小卡片渲染完成
- **THEN** 图片容器使用 `aspect-square` 类而非固定 `h-24` 高度

---

### Requirement: HotSpotsSlot 标题文案更新
HotSpotsSlot 的 section 背景 SHALL 显式声明 `bg-white`。区块标题 SHALL 显示 `"Hidden Gems"` 而非原有的 `"Off-the-Beaten-Path Spots"`。

#### Scenario: 标题文案
- **WHEN** 用户浏览景点区域
- **THEN** 区块标题文字为 "Hidden Gems"

---

### Requirement: 全局侧边距规约合规
所有 Region Slot 的内容容器（`mx-auto max-w-*` div）SHALL 使用 `px-8 sm:px-12 lg:px-16` 侧边距，不使用 `px-6`。Hero 区域内容容器 SHALL 保持与其他 Region 一致的 `max-w-6xl`（不使用 `max-w-5xl`）。

#### Scenario: 侧边距合规
- **WHEN** 各 Region Slot 渲染时
- **THEN** 内容容器 className 包含 `px-8` 而非 `px-6`
