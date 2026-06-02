## MODIFIED Requirements

### Requirement: Hot-posts 容器必须渲染 storytelling 布局（1 大 + 2 小）

`HotPostsSlot` SHALL render 3 story cards in a storytelling layout: 1 large featured card (spanning 2 cols on desktop) + 2 small cards stacked on the right. Each card MUST contain a background image (picsum.photos), English storytelling title, Chinese location subtitle, and excerpt.

#### Scenario: Hot-posts 渲染 3 张卡片

- **WHEN** RTL 渲染 `<HotPostsSlot />`
- **THEN** `container.querySelectorAll('[data-region="hot-posts"] a')` 长度恰好为 `3`

#### Scenario: storytelling 布局（左大右小）

- **WHEN** 检视 `HotPostsSlot.tsx`
- **THEN** 外层 grid 容器 className 含 `grid-cols-1` 和 `md:grid-cols-3`
- **AND** 第 1 张卡片（featured）className 含 `md:col-span-2`

#### Scenario: 每张卡片含图片和标题

- **WHEN** RTL 渲染 `<HotPostsSlot />`
- **THEN** 每张卡片内含图片容器（`bg-cover` class 或 `<img>` 标签）
- **AND** 每张卡片含 `<h3>` 标签（攻略标题）

---

### Requirement: Hot-posts 数据来源必须为 6 篇含 storytelling 标题的攻略

The hot-posts content SHALL be sourced from `frontend/app/regions/hotPosts.data.ts` with 6 items, each containing `title` (English storytelling title), `location` (Chinese location), `href`, `image` (picsum.photos URL), and `excerpt`.

#### Scenario: data 文件包含 6 篇攻略

- **WHEN** 静态 import `hotPosts.data.ts` 的 default export
- **THEN** 数组长度恰好为 `6`

#### Scenario: 每篇攻略含 storytelling 标题

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `title` 字段，为非空英文字符串（如 "3-Day Yunnan Hidden Tea Trail"）

#### Scenario: 每篇攻略含图片 URL

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `image` 字段，以 `https://picsum.photos/` 开头
