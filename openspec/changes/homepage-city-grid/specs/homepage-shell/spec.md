## MODIFIED Requirements

### Requirement: 所有 Slot 必须为完全空容器

Every region slot component (HotPostsSlot / HotSpotsSlot / AiLauncherSlot) SHALL render a single empty container element with attributes `data-region="<name>"` and `aria-label="<name> placeholder"`. The container MUST have zero child nodes and MUST NOT carry any inline style or className. **HeroSlot, FeatureNavSlot and CityGridSlot are excluded from this constraint**: their content contracts are governed by their respective capability specs.

#### Scenario: Slot 独立渲染产物为空（3 个仍空 Slot）

- **GIVEN** 任意非 HeroSlot / 非 FeatureNavSlot / 非 CityGridSlot 的 Slot 组件（HotPostsSlot / HotSpotsSlot / AiLauncherSlot）
- **WHEN** RTL 独立 `render(<HotPostsSlot />)`（其它 2 个仍空 Slot 同理）
- **THEN** 渲染出唯一一个带 `data-region` + `aria-label` 的容器元素
- **AND** 容器 `childNodes.length === 0`
- **AND** 容器无 `style` 属性、无 `class` / `className` 属性

#### Scenario: 2 个仍空的页内 Slot 容器为 section，ai-launcher 容器为 div

- **GIVEN** 任意非 HeroSlot / 非 FeatureNavSlot / 非 CityGridSlot 的 Slot 已渲染
- **THEN** HotPostsSlot / HotSpotsSlot 的根容器 tagName 为 `SECTION`
- **AND** AiLauncherSlot 的根容器 tagName 为 `DIV`

#### Scenario: CityGridSlot 不再受空容器约束

- **WHEN** RTL 渲染 `<CityGridSlot />`
- **THEN** 根 section 仍带 `data-region="city-grid"`，但 `childNodes.length` 可以 `> 0`
- **AND** 具体内容契约见 `openspec/specs/homepage-city-grid/spec.md`
