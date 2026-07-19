## ADDED Requirements

### Requirement: SiteHeader 必须提供桌面端主导航

`SiteHeader` SHALL render a primary navigation region, placed between the logo and the tool-icon cluster, that links to the main content pages: Cities → `/spots`, Stories → `/posts`, Spots → `/spots/ranking`. This navigation MUST be visible only on desktop widths (hidden below `md`, shown at `md` and above) so the existing mobile top bar layout (logo + tool icons) is not disrupted. Mobile navigation is explicitly out of scope for this change.

#### Scenario: 桌面主导航链接存在且指向正确

- **WHEN** RTL 渲染 `<SiteHeader />`
- **THEN** 存在指向 `/spots`、`/posts`、`/spots/ranking` 的导航链接
- **AND** 每个链接 `textContent.trim().length > 0`

#### Scenario: 主导航仅桌面可见

- **WHEN** 检视 `SiteHeader.tsx` 的主导航容器 className
- **THEN** 含 `hidden` 且含 `md:flex`（或等效的 `md:` 显隐类）
- **AND** 移动端（< md）不显示这些主导航链接

#### Scenario: 现有工具图标与 Logo 布局保持不变

- **WHEN** RTL 渲染 `<SiteHeader />`
- **THEN** Logo（指向 `/` 的 Wanderchina 链接）仍存在
- **AND** 工具图标簇（Weather / ExchangeRate / Notification / Message / User）仍全部存在
- **AND** header 根容器仍为 `sticky top-0`
