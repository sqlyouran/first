## MODIFIED Requirements

### Requirement: feature-nav region 必须渲染至少 1 个 `<a>` 子节点

`FeatureNavSlot` SHALL render a single root `<section data-region="feature-nav">` containing exactly 4 feature items. The first 3 items (Cities / Stories / Hidden Spots) MUST each be an `<a>` element carrying a non-empty `textContent` (the item label) and a real business-route `href`. The 4th item ("Plan with AI") MUST be a `<button>` element (not an `<a>`) that triggers the global AI panel. Every item MUST carry a non-empty label.

#### Scenario: feature-nav region 容器仍存在

- **GIVEN** `FeatureNavSlot` 已按本变更改写
- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `container.querySelector('[data-region="feature-nav"]')` 非 null
- **AND** 该节点 tagName 为 `SECTION`

#### Scenario: 前 3 项为链接、第 4 项为按钮

- **WHEN** RTL 渲染 `<FeatureNavSlot />`
- **THEN** `section[data-region="feature-nav"] a` NodeList 长度为 `3`
- **AND** `section[data-region="feature-nav"] button` NodeList 长度为 `1`
- **AND** 4 个 item 的 label 依次为 `["Cities", "Stories", "Hidden Spots", "Plan with AI"]`
- **AND** 每个 item 的 `textContent.trim().length > 0`

---

### Requirement: 占位链接必须为严格 `#`

The first 3 feature-nav links SHALL point to real, existing business routes: Cities → `/spots`, Stories → `/posts`, Hidden Spots → `/spots/ranking`. No feature-nav item's `href` may be `"#"`. This change MUST NOT introduce a link to a non-existent route.

> **homepage-nav-wiring MODIFIED**：占位阶段结束，`href === "#"` 契约作废。前 3 张功能卡改为指向已存在的真实业务列表页；第 4 张 "Plan with AI" 不再是链接。

#### Scenario: 前 3 张卡指向真实路由

- **WHEN** RTL 渲染 `<FeatureNavSlot />` 并 map 出每个 `<a>` 的 `href` 属性
- **THEN** href 集合为 `["/spots", "/posts", "/spots/ranking"]`
- **AND** 没有任何 `<a>` 的 `href` 等于 `"#"`

#### Scenario: data 文件不再包含占位 `#`

- **WHEN** 静态 import `frontend/app/regions/featureNav.data.ts` 的 default export
- **THEN** 前 3 项的 `href` 字段分别为 `/spots`、`/posts`、`/spots/ranking`
- **AND** 无任何项的 `href` 字段等于 `"#"`

## ADDED Requirements

### Requirement: "Plan with AI" 卡片必须触发全局 AI 面板

The 4th feature-nav item ("Plan with AI") SHALL be a `<button>` that, when clicked, opens the same global AI chat panel used by `AiLauncherSlot`. The trigger MUST call the shared AI-panel UI store's open action. It MUST NOT navigate to any route and MUST NOT mount a duplicate `<AiChatPanel />` instance inside `FeatureNavSlot`.

#### Scenario: 点击 "Plan with AI" 打开 AI 面板

- **GIVEN** 全局 AI 面板 store 初始为关闭
- **WHEN** 点击 feature-nav 中 label 为 "Plan with AI" 的 `<button>`
- **THEN** 全局 AI 面板 store 的 open 状态变为 `true`

#### Scenario: 触发逻辑不引入路由或重复面板

- **WHEN** 检视 `FeatureNavSlot.tsx` 及其 "Plan with AI" 子组件
- **THEN** 该按钮无 `href`、不调用 `router.push`
- **AND** `FeatureNavSlot` 内不 import `AiChatPanel`

#### Scenario: no-fetch 守护保持

- **WHEN** `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/FeatureNavSlot.tsx`
- **THEN** 输出为空（无任何匹配行）
