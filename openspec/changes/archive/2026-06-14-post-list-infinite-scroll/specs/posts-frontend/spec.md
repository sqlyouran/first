## MODIFIED Requirements

### Requirement: PostCard 共享组件

`app/posts/_components/PostCard.tsx` SHALL 渲染帖子摘要卡片，含条件化互动统计行。

#### Scenario: 渲染帖子卡片

- **WHEN** 传入 `PostListItem` 数据
- **THEN** 渲染标题、封面图（有则显示，无则占位）、标签（Badge）、发布时间

#### Scenario: 互动统计零值隐藏

- **WHEN** `up_vote_count`、`comment_count`、`bookmark_count` 均为 0
- **THEN** 不渲染互动统计行（无视觉噪音）

#### Scenario: 互动统计部分显示

- **WHEN** `up_vote_count=5`、`comment_count=0`、`bookmark_count=2`
- **THEN** 仅渲染 `👍 5` 和 `🔖 2`，不渲染评论图标

#### Scenario: 大数字格式化

- **WHEN** `up_vote_count=1234`
- **THEN** 显示为 `👍 1.2k`（`<10000` 时保留一位小数）

- **WHEN** `up_vote_count=12345`
- **THEN** 显示为 `👍 12k`（`>=10000` 时取整）

---

### Requirement: 帖子列表页

`app/posts/page.tsx` SHALL 展示已发布帖子列表，使用 IntersectionObserver 无限滚动加载。使用 Client Component。

#### Scenario: 首次加载

- **WHEN** 用户访问 `/posts`
- **THEN** 加载第一页帖子（无 cursor，sort=latest，size=20）
- **AND** 显示帖子卡片列表

#### Scenario: 触底自动加载

- **WHEN** 用户滚动到列表底部 sentinel 元素进入视口
- **AND** `has_more` 为 `true` 且非加载中
- **THEN** 以当前 `next_cursor` 为 cursor 参数加载下一页
- **AND** 新帖子追加到列表末尾
- **AND** 底部显示 3 张骨架卡占位（加载中状态）

#### Scenario: 已到底部

- **WHEN** `has_more` 为 `false` 且列表非空
- **THEN** 列表底部显示"已经到底啦"文案

#### Scenario: 排序切换清空重载

- **WHEN** 用户点击排序 Tab（最新 / 最热 / 最多讨论）
- **THEN** 清空当前列表（`items = []`）
- **AND** 重置 `nextCursor = null`
- **AND** 显示首屏骨架屏
- **AND** 重新加载第一页数据（无 cursor，新 sort 值）

#### Scenario: 点击帖子卡片跳转详情

- **WHEN** 用户点击帖子卡片
- **THEN** 导航到 `/posts/{id}`

#### Scenario: 空列表提示

- **WHEN** 列表返回 `items` 为空
- **THEN** 显示空状态提示文案及"发布第一篇帖子"CTA

---

## ADDED Requirements

### Requirement: formatCount 工具函数

`PostCard.tsx` SHALL 内置 `formatCount(n: number): string | null` 函数，用于互动统计数字的显示格式化。

#### Scenario: 零值返回 null

- **WHEN** `formatCount(0)`
- **THEN** 返回 `null`（调用方不渲染该项）

#### Scenario: 小于 1000 原样显示

- **WHEN** `formatCount(42)`
- **THEN** 返回 `"42"`

#### Scenario: 1000~9999 保留一位小数

- **WHEN** `formatCount(1234)`
- **THEN** 返回 `"1.2k"`

#### Scenario: 10000 及以上取整

- **WHEN** `formatCount(12345)`
- **THEN** 返回 `"12k"`
