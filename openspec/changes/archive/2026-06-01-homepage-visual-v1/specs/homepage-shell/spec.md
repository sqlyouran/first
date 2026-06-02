## MODIFIED Requirements

### Requirement: 页面级视觉契约（新增）

All region slots SHALL conform to a shared page-level visual contract defined in `app/globals.css`. This contract includes: font stack (Inter for body, Plus Jakarta Sans for display headings), primary color (indigo / blue-700), section spacing (96px desktop / 64px mobile), and responsive 3-breakpoint system (mobile < 768 / tablet 768-1023 / desktop ≥ 1024).

#### Scenario: 字体 stack 正确

- **WHEN** 检视 `app/layout.tsx` 和 `app/globals.css`
- **THEN** `next/font/google` 引入 Inter 和 Plus Jakarta Sans
- **AND** `:root` CSS 变量定义 `--font-sans` 和 `--font-display`
- **AND** `body` 使用 `--font-sans`，`h1-h3` 使用 `--font-display`

#### Scenario: 主色为靛青

- **WHEN** 检视 `app/globals.css`
- **THEN** `:root` CSS 变量定义 `--color-primary: #1d4ed8`（Tailwind blue-700）

#### Scenario: section 间距正确

- **WHEN** 检视 `app/globals.css`
- **THEN** `section[data-region]` 的 `padding-block` 在 mobile（< 1024px）为 64px，desktop（≥ 1024px）为 96px

#### Scenario: 响应式 3 断点

- **WHEN** 检视所有 Slot 组件的 Tailwind class
- **THEN** 布局使用 `grid-cols-2` / `md:grid-cols-4` 等断点类名
- **AND** 断点符合 mobile < 768 / tablet 768-1023 / desktop ≥ 1024 分段

---

### Requirement: Layout 必须挂载 ai-launcher 常驻槽位（无变化）

（此 Requirement 保持 homepage-ai-launcher archive 后的状态，无新增 Scenario）

---

### Requirement: 首页 Page 必须渲染 5 个 region Slot 按文档顺序（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）

---

### Requirement: HelloMessage 与 lib/backend 链路必须保留（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）

---

### Requirement: 首页必须不依赖后端运行（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）

---

### Requirement: BFF 边界守护必须保持（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）

---

### Requirement: regions 目录必须恰好包含 6 个 Slot 文件（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）

---

### Requirement: 治理文档必须随 archive 同步更新（无变化）

（此 Requirement 保持 homepage-shell archive 后的状态，无新增 Scenario）
