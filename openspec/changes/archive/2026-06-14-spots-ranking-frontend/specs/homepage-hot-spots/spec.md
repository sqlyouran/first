## MODIFIED Requirements

### Requirement: 占位链接必须为严格 `#`

Every hot-spots card item's `href` SHALL be exactly the string `"#"`. The "See all →" navigation link in the section header SHALL use `href="/spots/ranking"` to navigate to the ranking page.

#### Scenario: 卡片链接仍为占位 `#`

- **WHEN** RTL 渲染 `<HotSpotsSlot />` 并 map 出每张卡片 `<a>` 的 `href` 属性
- **THEN** 所有卡片项 `href === "#"`

#### Scenario: "See all" 链接指向排行榜页面

- **WHEN** RTL 渲染 `<HotSpotsSlot />`
- **THEN** 包含文本 "See all →" 的 `<a>` 元素 `href === "/spots/ranking"`
