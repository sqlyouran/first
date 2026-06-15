## MODIFIED Requirements

### Requirement: Posts API 封装

`lib/api/posts.ts` SHALL 封装所有帖子相关 API 调用，使用 `ApiResponse<T>` 泛型包装返回值。写操作使用 `authFetch`，读操作使用普通 `fetch`。

#### Scenario: createPost 成功

- **WHEN** 调用 `createPost({ title, content, coverImage, tags, status })`
- **THEN** 发送 `POST /api/posts`，使用 `authFetch`，返回 `ApiResponse<PostData>`

#### Scenario: fetchPost 成功

- **WHEN** 调用 `fetchPost(id)`
- **THEN** 发送 `GET /api/posts/{id}`，使用普通 `fetch`，返回 `ApiResponse<PostData>`

#### Scenario: fetchPosts 分页和排序

- **WHEN** 调用 `fetchPosts({ page, size, sort })` 或 `fetchPosts({ cursor, size, sort })`
- **THEN** 发送 `GET /api/posts?page={page}&size={size}&sort={sort}` 或 `GET /api/posts?cursor={cursor}&size={size}`
- **AND** 返回 `ApiResponse<PostListData>`
- **AND** `PostListData` 包含 `next_cursor`（string | null）和 `has_more`（boolean）字段

#### Scenario: fetchUserPosts 分页和排序

- **WHEN** 调用 `fetchUserPosts(userId, { page, size, sort })` 或 `fetchUserPosts(userId, { cursor, size, sort })`
- **THEN** 发送 `GET /api/users/{userId}/posts?page={page}&size={size}&sort={sort}` 或带 cursor 的 URL
- **AND** 返回 `ApiResponse<PostListData>`

#### Scenario: 网络错误兜底

- **WHEN** 任何 API 调用 `fetch` 抛出异常
- **THEN** 返回 `networkError()`（status: 0, error_code: "network_error"）

### Requirement: 帖子列表页

`app/posts/page.tsx` SHALL 展示已发布帖子列表，支持分页和排序切换。使用 Client Component。

#### Scenario: 默认加载第一页

- **WHEN** 用户访问 `/posts`
- **THEN** 页面加载第一页帖子（page=1, size=20, sort=latest）
- **AND** 显示帖子卡片列表（每项含 title / cover_image / tags / created_at / comment_count / up_vote_count / bookmark_count）
- **AND** 显示排序选项卡（最新 / 最热 / 最多评论），默认选中「最新」

#### Scenario: 点击排序切换

- **WHEN** 用户点击「最热」或「最多评论」按钮
- **THEN** 重置 page=1，重新请求数据
- **AND** URL 或组件状态更新为对应 sort 值
- **AND** 列表按新排序重新渲染

#### Scenario: 点击分页切换页码

- **WHEN** 用户点击"下一页"或页码按钮
- **THEN** 重新请求对应页码数据并更新列表

#### Scenario: 空列表提示

- **WHEN** 列表返回 `items` 为空
- **THEN** 显示空状态提示文案

#### Scenario: 点击帖子卡片跳转详情

- **WHEN** 用户点击帖子卡片
- **THEN** 导航到 `/posts/{id}`

### Requirement: PostCard 共享组件

`app/posts/_components/PostCard.tsx` SHALL 渲染帖子摘要卡片，包含互动统计展示。

#### Scenario: 渲染帖子卡片

- **WHEN** 传入 `PostListItem` 数据
- **THEN** 渲染标题、封面图（有则显示，无则占位）、标签（Badge）、互动统计行、发布时间

#### Scenario: 互动统计行展示

- **WHEN** PostCard 渲染
- **THEN** 在标签下方、发布时间上方显示互动统计行
- **AND** 统计行包含：点赞图标 + `up_vote_count`、评论图标 + `comment_count`、收藏图标 + `bookmark_count`
- **AND** 使用 lucide-react 图标（ThumbsUp / MessageCircle / Bookmark）
- **AND** 样式为 `text-sm text-slate-500`，图标与数字间有间距

#### Scenario: 互动统计为零

- **WHEN** `comment_count` / `up_vote_count` / `bookmark_count` 均为 0
- **THEN** 仍显示图标和数字 `0`（不隐藏统计行）

---

## ADDED Requirements

### Requirement: PostListItem 类型增强

`PostListItem` 类型 SHALL 包含互动统计字段。

#### Scenario: 类型定义

- **WHEN** 前端代码引用 `PostListItem` 类型
- **THEN** 类型包含 `comment_count: number`、`up_vote_count: number`、`bookmark_count: number` 字段

### Requirement: PostListData 类型增强

`PostListData` 类型 SHALL 包含 cursor 分页相关字段。

#### Scenario: 类型定义

- **WHEN** 前端代码引用 `PostListData` 类型
- **THEN** 类型包含 `next_cursor: string | null`、`has_more: boolean` 字段
