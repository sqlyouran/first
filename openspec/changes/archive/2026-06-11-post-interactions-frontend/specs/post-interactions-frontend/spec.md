## ADDED Requirements

### Requirement: Toast 通知集成

`app/layout.tsx` SHALL 在根布局中添加 sonner `<Toaster />` 组件。所有用户操作反馈（成功/失败/提示）通过 `toast()` 函数触发。

#### Scenario: 全局 Toaster 渲染

- **WHEN** 应用启动
- **THEN** `<Toaster />` 在根布局中渲染，toast 通知出现在页面右上角

#### Scenario: toast.error 显示错误

- **WHEN** 调用 `toast.error("操作失败")`
- **THEN** 页面显示红色样式错误通知，包含文案"操作失败"

### Requirement: 投票 API 客户端

`lib/api/interactions.ts` SHALL 导出投票相关 API 函数，使用 `authFetch` + `ApiResponse<T>` 封装。

#### Scenario: fetchVoteStats 成功

- **WHEN** 调用 `fetchVoteStats(postId)`
- **THEN** 发送 `GET /api/posts/{postId}/vote-stats`，使用普通 `fetch`（可选认证）
- **AND** 返回 `ApiResponse<VoteStatsData>`，包含 `up_count`、`down_count`、`user_vote`

#### Scenario: vote 成功

- **WHEN** 调用 `vote(postId, voteType)`
- **THEN** 发送 `POST /api/posts/{postId}/vote`，使用 `authFetch`
- **AND** 返回 `ApiResponse<VoteData>`，包含 `vote_type`（可为 null 表示取消）

#### Scenario: removeVote 成功

- **WHEN** 调用 `removeVote(postId)`
- **THEN** 发送 `DELETE /api/posts/{postId}/vote`，使用 `authFetch`
- **AND** 返回 `ApiResponse<void>`（status: 204）

#### Scenario: 网络错误兜底

- **WHEN** 投票 API 调用抛出异常
- **THEN** 返回 `networkError()`（status: 0, error_code: "network_error"）

### Requirement: 收藏 API 客户端

`lib/api/interactions.ts` SHALL 导出收藏相关 API 函数。

#### Scenario: fetchBookmarkStatus 成功

- **WHEN** 调用 `fetchBookmarkStatus(postId)`
- **THEN** 发送 `GET /api/posts/{postId}/bookmark-status`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkStatusData>`，包含 `bookmarked: boolean`

#### Scenario: toggleBookmark 成功

- **WHEN** 调用 `toggleBookmark(postId)`
- **THEN** 发送 `POST /api/posts/{postId}/bookmark`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkData>`，包含 `bookmarked: boolean`

### Requirement: 评论 API 客户端

`lib/api/interactions.ts` SHALL 导出评论相关 API 函数。

#### Scenario: fetchComments 分页

- **WHEN** 调用 `fetchComments(postId, page?, size?)`
- **THEN** 发送 `GET /api/posts/{postId}/comments?page={page}&size={size}`，使用普通 `fetch`
- **AND** 返回 `ApiResponse<CommentListData>`

#### Scenario: fetchReplies 分页

- **WHEN** 调用 `fetchReplies(commentId, page?, size?)`
- **THEN** 发送 `GET /api/comments/{commentId}/replies?page={page}&size={size}`
- **AND** 返回 `ApiResponse<CommentListData>`

#### Scenario: createComment 成功

- **WHEN** 调用 `createComment(postId, content, parentCommentId?)`
- **THEN** 发送 `POST /api/posts/{postId}/comments`，使用 `authFetch`
- **AND** 返回 `ApiResponse<CommentData>`

#### Scenario: deleteComment 成功

- **WHEN** 调用 `deleteComment(postId, commentId)`
- **THEN** 发送 `DELETE /api/posts/{postId}/comments/{commentId}`，使用 `authFetch`
- **AND** 返回 `ApiResponse<void>`（status: 204）

### Requirement: VoteButtons 投票按钮组

`app/posts/_components/VoteButtons.tsx` SHALL 为 Client Component，接收 `postId`、`initialVoteStats` props，展示 👍/👎 按钮和计数。

#### Scenario: 初始渲染

- **WHEN** 组件挂载并接收 `initialVoteStats: { up_count: 5, down_count: 1, user_vote: "up" }`
- **THEN** 显示 👍 5 和 👎 1，👍 按钮高亮

#### Scenario: 已登录用户点击投票

- **GIVEN** 用户已登录
- **WHEN** 用户点击 👍 按钮
- **THEN** 乐观更新 UI（计数+1，按钮高亮）
- **AND** 发送 `POST /api/posts/{postId}/vote`
- **AND** 成功时用响应确认状态，失败时回滚 UI + `toast.error("投票失败，请重试")`

#### Scenario: 切换投票类型

- **GIVEN** 用户已投票 👍
- **WHEN** 用户点击 👎
- **THEN** 乐观更新（👍 取消高亮，👎 高亮，计数相应变化）
- **AND** 发送 API 更新投票类型

#### Scenario: 取消投票（再次点击已选项）

- **GIVEN** 用户已投票 👍
- **WHEN** 用户再次点击 👍
- **THEN** 乐观更新（👍 取消高亮，计数-1）
- **AND** 发送 API（后端三态切换返回 null）

#### Scenario: 未登录用户点击投票

- **GIVEN** 用户未登录
- **WHEN** 用户点击投票按钮
- **THEN** 跳转 `/login`（`router.push("/login")`），不发送 API

### Requirement: BookmarkButton 收藏按钮

`app/posts/_components/BookmarkButton.tsx` SHALL 为 Client Component，接收 `postId`、`initialBookmarked` props。

#### Scenario: 初始渲染已收藏

- **WHEN** 组件挂载且 `initialBookmarked: true`
- **THEN** 显示填充状态的 BookmarkCheck 图标

#### Scenario: 初始渲染未收藏

- **WHEN** 组件挂载且 `initialBookmarked: false`
- **THEN** 显示空心状态的 Bookmark 图标

#### Scenario: 已登录用户点击切换收藏

- **GIVEN** 用户已登录
- **WHEN** 用户点击收藏按钮
- **THEN** 乐观切换图标状态（空心 ↔ 填充）
- **AND** 发送 `POST /api/posts/{postId}/bookmark`
- **AND** 成功时确认状态，失败时回滚 + `toast.error("收藏失败，请重试")`

#### Scenario: 未登录用户点击收藏

- **GIVEN** 用户未登录
- **WHEN** 用户点击收藏按钮
- **THEN** 跳转 `/login`，不发送 API

### Requirement: CommentSection 评论区

`app/posts/_components/CommentSection.tsx` SHALL 为 Client Component，接收 `postId` props，管理评论输入 + 列表渲染。

#### Scenario: 初始加载评论列表

- **WHEN** 组件挂载
- **THEN** 调用 `fetchComments(postId, 1, 20)`
- **AND** 渲染评论列表（每条含头像占位、用户ID截断、内容、时间、回复按钮）

#### Scenario: 空评论状态

- **WHEN** 评论列表为空
- **THEN** 显示空状态文案"暂无评论，发表第一条评论吧"

#### Scenario: 加载更多评论

- **WHEN** 评论列表有下一页
- **THEN** 底部显示"加载更多评论"按钮
- **AND** 点击后追加下一页数据

### Requirement: CommentItem 评论项

`app/posts/_components/CommentItem.tsx` SHALL 渲染单条评论，支持嵌套回复展示。

#### Scenario: 渲染普通评论

- **WHEN** 评论 `deleted: false`
- **THEN** 显示用户头像占位（灰色圆形）、`user_id` 前8位、内容、相对时间、回复按钮

#### Scenario: 渲染已删除评论

- **WHEN** 评论 `deleted: true`
- **THEN** 显示用户头像占位、"已删除用户"、内容显示 `[已删除]`（灰色斜体）、无回复按钮

#### Scenario: 展示嵌套回复（最多2层）

- **WHEN** 评论有回复
- **THEN** 展示最多2层嵌套回复（视觉缩进）
- **AND** 若第2层回复有更深回复，显示"查看更多 N 条回复"按钮
- **AND** 点击按钮调用 `fetchReplies(commentId)` 加载下一层

#### Scenario: 点击回复按钮

- **WHEN** 用户点击某条评论的"回复"按钮
- **THEN** 在该评论下方展开 CommentInput，placeholder 显示"回复 @user_id..."

### Requirement: CommentInput 评论输入

`app/posts/_components/CommentInput.tsx` SHALL 提供评论输入框和发布按钮。

#### Scenario: 已登录用户显示输入框

- **GIVEN** 用户已登录
- **WHEN** 渲染 CommentInput
- **THEN** 显示 textarea + "发布"按钮，按钮默认禁用

#### Scenario: 未登录用户隐藏输入框

- **GIVEN** 用户未登录
- **WHEN** 渲染 CommentInput
- **THEN** 不显示输入框，显示"登录后即可评论"+ 跳转链接

#### Scenario: 提交评论

- **WHEN** 用户输入内容后点击"发布"
- **THEN** 调用 `createComment(postId, content, parentCommentId?)`
- **AND** 成功后清空输入框 + `toast.success("评论已发布")`
- **AND** 将新评论插入列表顶部（无需刷新）

#### Scenario: 提交空内容

- **WHEN** 用户未输入内容就点击"发布"
- **THEN** 按钮保持禁用，不发送请求

#### Scenario: API 失败

- **WHEN** `createComment` 返回错误
- **THEN** `toast.error("评论失败，请重试")`，输入内容保留

### Requirement: 后端 bookmark-status 端点

BookmarkController SHALL 实现 `GET /api/posts/{postId}/bookmark-status`，返回当前用户对该帖子的收藏状态。

#### Scenario: 已登录用户查询收藏状态（已收藏）

- **GIVEN** 用户已收藏 postId=X
- **WHEN** 发送 `GET /api/posts/X/bookmark-status`（携带 Bearer token）
- **THEN** 返回 200，`{ bookmarked: true, request_id: "..." }`

#### Scenario: 已登录用户查询收藏状态（未收藏）

- **GIVEN** 用户未收藏 postId=X
- **WHEN** 发送 `GET /api/posts/X/bookmark-status`
- **THEN** 返回 200，`{ bookmarked: false, request_id: "..." }`

#### Scenario: 未登录用户查询

- **WHEN** 发送 `GET /api/posts/X/bookmark-status`（无 Bearer token）
- **THEN** 返回 200，`{ bookmarked: false, request_id: "..." }`（可选认证，未登录默认 false）

#### Scenario: 帖子不存在

- **WHEN** postId 不存在
- **THEN** 返回 404，`error_code: "not_found"`
