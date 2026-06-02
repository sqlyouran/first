## REMOVED Requirements

### Requirement: 所有 Slot 必须为完全空容器

**Reason:** 6 个 region Slot 已全部完成内容注入；该 Requirement 的所有适用对象（HeroSlot / FeatureNavSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot / AiLauncherSlot）已分别迁移至各自 capability spec 的内容契约，原"完全空容器"约束在主 spec 中已无任何适用对象，整条退役。

**Migration:** 各 Slot 的容器形态契约由对应 capability spec 接管：

- `HeroSlot` → `openspec/specs/homepage-hero/spec.md`
- `FeatureNavSlot` → `openspec/specs/homepage-feature-nav/spec.md`
- `CityGridSlot` → `openspec/specs/homepage-city-grid/spec.md`
- `HotPostsSlot` → `openspec/specs/homepage-hot-posts/spec.md`
- `HotSpotsSlot` → `openspec/specs/homepage-hot-spots/spec.md`
- `AiLauncherSlot` → `openspec/specs/homepage-ai-launcher/spec.md`

## MODIFIED Requirements

### Requirement: Layout 必须挂载 ai-launcher 常驻槽位

`app/layout.tsx` SHALL mount `<AiLauncherSlot />` after `{children}` inside `<body>`. The ai-launcher slot MUST appear in the rendered HTML on every route, after all page content. The ai-launcher container MUST contain exactly one `<button>` child element (its content contract is defined by `homepage-ai-launcher`).

#### Scenario: layout 渲染 ai-launcher 在 children 之后

- **GIVEN** layout 已按 homepage-shell apply 修改
- **WHEN** 测试以一个带 `data-testid="children-marker"` 的子节点作为 children 渲染 layout
- **THEN** `container.querySelector('[data-region="ai-launcher"]')` 非 null
- **AND** DOM 顺序上 `[data-region="ai-launcher"]` 节点出现在 `[data-testid="children-marker"]` 之后

#### Scenario: ai-launcher 容器内含 1 个 button（断言强化）

- **GIVEN** layout 已按 homepage-shell apply 修改 + AiLauncherSlot 已按 homepage-ai-launcher 改写
- **WHEN** 测试渲染 layout 后查 `container.querySelectorAll('[data-region="ai-launcher"] button')`
- **THEN** NodeList 长度恰好为 `1`
- **AND** 该 `<button>` 的 `textContent.trim().length > 0`

#### Scenario: 跨 SSR 链路 ai-launcher 槽位存在

- **GIVEN** 前端 dev server 已起
- **WHEN** `curl -s http://localhost:<port>/`
- **THEN** 响应 HTML 中存在恰好 1 个 `data-region="ai-launcher"` 元素
- **AND** 该元素位于 5 个页内 region 之后
- **AND** 该元素内含 1 个 `<button>` 节点
