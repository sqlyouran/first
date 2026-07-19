## ADDED Requirements

### Requirement: hot-posts 区块必须提供 "See all" 入口

`HotPostsSlot` SHALL render a "See all →" link in the section heading row, pointing to `/posts`, mirroring the existing HotSpots "See all → /spots/ranking" pattern. The link MUST be placed alongside the section heading (not inside a story card). The story-card count assertion MUST be decoupled from this link so that adding "See all" does not break the "exactly 3 cards" contract.

#### Scenario: See all 链接指向 /posts

- **WHEN** RTL 渲染 `<HotPostsSlot />` 并查 `container.querySelector('a[href="/posts"]')`
- **THEN** 返回非 null
- **AND** 其 `textContent.trim()` 为 `See all →`

#### Scenario: 卡片计数与 See all 解耦

- **WHEN** RTL 渲染 `<HotPostsSlot />` 并查故事卡（`[data-region="hot-posts"] .grid a`）
- **THEN** 故事卡数量恰好为 `3`
- **AND** 该计数 selector 不把 "See all" 链接计入（See all 位于标题行、在 `.grid` 之外）

#### Scenario: See all 位于标题行

- **WHEN** 检视 `HotPostsSlot.tsx`
- **THEN** "See all" 链接与 `<h2>` 标题同处一个标题行容器（含 `flex items-center justify-between`）
- **AND** "See all" 不在任何故事卡 `<a>` 内部
