## MODIFIED Requirements

### Requirement: Feature-nav 容器必须渲染 4 个带图标的 chip

`FeatureNavSlot` SHALL render exactly 4 feature chips (Cities / Stories / Hidden Spots / Plan with AI), each containing a lucide-react icon and English label. The chips MUST be arranged in a responsive grid (2 cols mobile, 4 cols desktop) with hover effect.

#### Scenario: Feature-nav 渲染 4 个 chip

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `container.querySelectorAll('[data-region="feature-nav"] a')` 长度恰好为 `4`
- **AND** 各 `<a>` 的 textContent 依次为 `['Cities', 'Stories', 'Hidden Spots', 'Plan with AI']`

#### Scenario: 每个 chip 含 lucide-react 图标

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** 每个 `<a>` 内含一个 `<svg>`（lucide-react 图标渲染为 SVG）
- **AND** 4 个图标依次为 MapPin / BookOpen / Compass / Sparkles

#### Scenario: chip 有 hover 效果

- **WHEN** 检视 `FeatureNavSlot.tsx`
- **THEN** 每个 `<a>` 的 className 含 `hover:` 前缀的 Tailwind 类（如 `hover:shadow-md`）

#### Scenario: 响应式布局

- **WHEN** 检视 `FeatureNavSlot.tsx`
- **THEN** 外层容器 className 含 `grid-cols-2` 和 `md:grid-cols-4`

---

### Requirement: Feature-nav 数据来源必须为 4 个含图标的入口

The feature-nav content SHALL be sourced from `frontend/app/regions/featureNav.data.ts` with 4 items, each containing `label` (English), `href`, and `icon` (lucide-react icon name).

#### Scenario: data 文件包含 4 个入口

- **WHEN** 静态 import `featureNav.data.ts` 的 default export
- **THEN** 数组长度恰好为 `4`

#### Scenario: 每个入口含图标字段

- **WHEN** 遍历 data 数组
- **THEN** 每项含 `icon` 字段，值为 `'MapPin'` / `'BookOpen'` / `'Compass'` / `'Sparkles'` 之一
