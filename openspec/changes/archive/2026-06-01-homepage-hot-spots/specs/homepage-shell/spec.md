## MODIFIED Requirements

### Requirement: 所有 Slot 必须为完全空容器

`AiLauncherSlot` SHALL render a single empty container element with attributes `data-region="ai-launcher"` and `aria-label="ai-launcher placeholder"`. The container MUST have zero child nodes and MUST NOT carry any inline style or className. **HeroSlot, FeatureNavSlot, CityGridSlot, HotPostsSlot and HotSpotsSlot are excluded from this constraint**: their content contracts are governed by their respective capability specs.

#### Scenario: AiLauncherSlot 独立渲染产物为空

- **GIVEN** AiLauncherSlot
- **WHEN** RTL 独立 `render(<AiLauncherSlot />)`
- **THEN** 渲染出唯一一个带 `data-region="ai-launcher"` + `aria-label="ai-launcher placeholder"` 的容器元素
- **AND** 容器 `childNodes.length === 0`
- **AND** 容器无 `style` 属性、无 `class` / `className` 属性

#### Scenario: AiLauncherSlot 容器为 div

- **GIVEN** AiLauncherSlot 已渲染
- **THEN** 根容器 tagName 为 `DIV`

#### Scenario: HotSpotsSlot 不再受空容器约束

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** 根 section 仍带 `data-region="hot-spots"`，但 `childNodes.length` 可以 `> 0`
- **AND** 具体内容契约见 `openspec/specs/homepage-hot-spots/spec.md`
