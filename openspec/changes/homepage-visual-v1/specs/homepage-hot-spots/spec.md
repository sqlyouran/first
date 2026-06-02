## MODIFIED Requirements

### Requirement: Hot-spots 容器必须渲染横向 carousel + 标签

`HotSpotsSlot` SHALL render 8 spot cards in a horizontal carousel (overflow-x-auto on mobile, 4-col grid on desktop). Each card MUST contain a background image (picsum.photos), English name, Chinese name subtitle, and tag Badges.

#### Scenario: Hot-spots 渲染 8 张卡片

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** `container.querySelectorAll('[data-region="hot-spots"] a')` 长度恰好为 `8`

#### Scenario: 每张卡片含图片、标题、标签

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** 每张卡片内含图片容器（`aspect-[4/3]` + `bg-cover` class）
- **AND** 每张卡片含 `<h3>` 标签（景点名）
- **AND** 每张卡片含至少 1 个 Badge 组件（标签）

#### Scenario: carousel 横向滚动（mobile）

- **WHEN** 检视 `HotSpotsSlot.tsx`
- **THEN** 外层容器 className 含 `overflow-x-auto` 和 `snap-x`
- **AND** 在 desktop（≥ 768px）使用 `md:grid md:grid-cols-4` 替代滚动

---

### Requirement: Hot-spots 数据来源必须为 8 个含标签的景点

The hot-spots content SHALL be sourced from `frontend/app/regions/hotSpots.data.ts` with 8 items, each containing `name` (English), `nameZh` (Chinese), `href`, `image` (picsum.photos URL), and `tags` (string array).

#### Scenario: data 文件包含 8 个景点

- **WHEN** 静态 import `hotSpots.data.ts` 的 default export
- **THEN** 数组长度恰好为 `8`

#### Scenario: 每个景点含标签数组

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `tags` 字段，为非空字符串数组（如 `["Nature", "Thrill"]`）

#### Scenario: 每个景点含图片 URL

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `image` 字段，以 `https://picsum.photos/` 开头
