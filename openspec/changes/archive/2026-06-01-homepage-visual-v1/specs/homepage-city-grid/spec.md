## MODIFIED Requirements

### Requirement: City-grid 容器必须渲染 8 张带季节标签的城市卡片

`CityGridSlot` SHALL render 8 city cards in a responsive grid (2 cols mobile, 4 cols desktop). Each card MUST contain a background image (picsum.photos), English city name, Chinese location subtitle, description, and a Badge showing best season.

#### Scenario: City-grid 渲染 8 张卡片

- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** `container.querySelectorAll('[data-region="city-grid"] a')` 长度恰好为 `8`

#### Scenario: 每张卡片含图片、标题、Badge

- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** 每张卡片内含一个 `aspect-[4/3]` 的图片容器（`bg-cover` class）
- **AND** 每张卡片含 `<h3>` 标签（城市名）
- **AND** 每张卡片含一个 Badge 组件（季节标签）

#### Scenario: 响应式布局

- **WHEN** 检视 `CityGridSlot.tsx`
- **THEN** grid 容器 className 含 `grid-cols-2` 和 `md:grid-cols-4`

---

### Requirement: City-grid 数据来源必须为 8 个含季节标签的城市

The city-grid content SHALL be sourced from `frontend/app/regions/cityGrid.data.ts` with 8 items, each containing `label` (English name), `labelZh` (Chinese name), `href`, `image` (picsum.photos URL), `description`, and `bestSeason`.

#### Scenario: data 文件包含 8 个城市

- **WHEN** 静态 import `cityGrid.data.ts` 的 default export
- **THEN** 数组长度恰好为 `8`

#### Scenario: 每个城市含季节字段

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `bestSeason` 字段，值为 `'Spring'` / `'Summer'` / `'Autumn'` / `'Winter'` 之一

#### Scenario: 每个城市含图片 URL

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `image` 字段，以 `https://picsum.photos/` 开头
