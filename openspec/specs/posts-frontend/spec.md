## ADDED Requirements

### Requirement: API 通用工具层

`lib/api/client.ts` SHALL 导出 `ApiError` / `ApiResponse<T>` 类型和 `parseResponse` / `networkError` / `serverError` 工具函数。`lib/api/auth.ts` SHALL 从 `client.ts` 导入这些类型和函数。

#### Scenario: client.ts 导出完整 API 工具

- **WHEN** 其他模块 `import { ApiResponse, parseResponse, networkError, serverError } from "@/lib/api/client"`
- **THEN** 导入成功且类型与 `auth.ts` 中原定义一致

#### Scenario: auth.ts 复用 client.ts

- **WHEN** `lib/api/auth.ts` 使用 `ApiResponse` 类型
- **THEN** 从 `client.ts` 导入，不重复定义

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

#### Scenario: 网络错误兗底

- **WHEN** 任何 API 调用 `fetch` 抛出异常
- **THEN** 返回 `networkError()`（status: 0, error_code: "network_error"）

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

### Requirement: 帖子详情页

`app/posts/[id]/page.tsx` SHALL 展示单个帖子详情，使用 Server Component（SSR）。页面底部包含投票/收藏互动栏和评论区。

#### Scenario: 获取已发布帖子详情

- **WHEN** 用户访问 `/posts/{id}`
- **THEN** 通过 `fetchFromBackend` SSR 预取帖子数据、投票统计（`/api/posts/{id}/vote-stats`）、收藏状态（`/api/posts/{id}/bookmark-status`）
- **AND** 渲染标题（h1）、封面图、Markdown 正文（`react-markdown` + `remark-gfm`）、标签、作者、发布时间
- **AND** 渲染投票按钮组（接收 initialVoteStats）、收藏按钮（接收 initialBookmarked）
- **AND** 渲染评论区 CommentSection

#### Scenario: 帖子不存在

- **WHEN** 后端返回 404
- **THEN** 使用 Next.js `notFound()` 显示 404 页面

#### Scenario: 互动组件布局

- **WHEN** 帖子内容渲染完成
- **THEN** 内容卡片下方显示互动栏：左侧投票按钮（👍/👎），右侧收藏按钮
- **AND** 互动栏使用 `border-y border-slate-200 py-4` 分隔
- **AND** 互动栏下方为评论区

### Requirement: 发帖页

`app/posts/create/page.tsx` SHALL 提供帖子创建表单，需登录后访问。使用 Client Component。

#### Scenario: 表单字段

- **WHEN** 用户访问 `/posts/create`
- **THEN** 显示表单：标题（Input）、正文（Markdown 编辑器）、封面图 URL（Input）、标签（TagInput）、状态选择（默认 published）、提交按钮

#### Scenario: 提交成功

- **WHEN** 用户填写 title + content 后点击提交
- **THEN** 调用 `createPost()` API
- **AND** 成功后导航到 `/posts/{id}`

#### Scenario: 校验失败

- **WHEN** 用户未填写 title 或 content 就提交
- **THEN** 显示对应字段错误提示，不发送请求

#### Scenario: API 错误

- **WHEN** `createPost()` 返回 error
- **THEN** 显示错误信息（来自 `ApiError.message`）

#### Scenario: 未登录被拦截

- **WHEN** 未登录用户访问 `/posts/create`
- **THEN** middleware 重定向到 `/login`

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

### Requirement: TagInput 组件

`app/posts/_components/TagInput.tsx` SHALL 提供标签输入组件，支持添加和删除标签。

#### Scenario: 添加标签

- **WHEN** 用户输入标签文本并按回车
- **THEN** 标签添加到列表中
- **AND** 最多 10 个标签，每个最多 30 字符

#### Scenario: 删除标签

- **WHEN** 用户点击标签的删除按钮（X）
- **THEN** 标签从列表移除

### Requirement: Middleware 路由守卫

`middleware.ts` SHALL 使用白名单保护策略：仅保护 `PROTECTED_PAGES` 中的路径，其余路径全部放行。

#### Scenario: 已登录用户访问受保护页面

- **WHEN** 已登录用户访问 `/posts/create`
- **THEN** 正常放行

#### Scenario: 未登录用户访问受保护页面

- **WHEN** 未登录用户访问 `/posts/create`
- **THEN** 重定向到 `/login`

#### Scenario: 任何用户访问公开页面

- **WHEN** 任何用户访问 `/posts` 或 `/posts/[id]`
- **THEN** 正常放行，不做认证检查

#### Scenario: 已登录用户访问认证页面

- **WHEN** 已登录用户访问 `/login` 或 `/register`
- **THEN** 重定向到 `/`

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
