## MODIFIED Requirements

### Requirement: 收藏 API 客户端

`lib/api/interactions.ts` SHALL 导出收藏相关 API 函数，接受 `entityId` + `entityType` 参数。URL 通过 `entityPath(entityType)` 辅助函数动态拼接。

#### Scenario: fetchBookmarkStatus 帖子

- **WHEN** 调用 `fetchBookmarkStatus(entityId, "post")`
- **THEN** 发送 `GET /api/posts/{entityId}/bookmark-status`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkStatusData>`，包含 `bookmarked: boolean`

#### Scenario: fetchBookmarkStatus 景点

- **WHEN** 调用 `fetchBookmarkStatus(entityId, "spot")`
- **THEN** 发送 `GET /api/spots/{entityId}/bookmark-status`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkStatusData>`

#### Scenario: toggleBookmark 帖子

- **WHEN** 调用 `toggleBookmark(entityId, "post")`
- **THEN** 发送 `POST /api/posts/{entityId}/bookmark`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkData>`

#### Scenario: toggleBookmark 景点

- **WHEN** 调用 `toggleBookmark(entityId, "spot")`
- **THEN** 发送 `POST /api/spots/{entityId}/bookmark`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkData>`

---

### Requirement: 评论 API 客户端

`lib/api/interactions.ts` SHALL 导出评论相关 API 函数，接受 `entityId` + `entityType` 参数（fetchReplies 除外，仍用 commentId）。

#### Scenario: fetchComments 帖子

- **WHEN** 调用 `fetchComments(entityId, "post", page?, size?)`
- **THEN** 发送 `GET /api/posts/{entityId}/comments?page={page}&size={size}`，使用普通 `fetch`
- **AND** 返回 `ApiResponse<CommentListData>`

#### Scenario: fetchComments 景点

- **WHEN** 调用 `fetchComments(entityId, "spot", page?, size?)`
- **THEN** 发送 `GET /api/spots/{entityId}/comments?page={page}&size={size}`
- **AND** 返回 `ApiResponse<CommentListData>`

#### Scenario: createComment 帖子

- **WHEN** 调用 `createComment(entityId, "post", content, parentCommentId?)`
- **THEN** 发送 `POST /api/posts/{entityId}/comments`，使用 `authFetch`
- **AND** 返回 `ApiResponse<CommentData>`

#### Scenario: createComment 景点

- **WHEN** 调用 `createComment(entityId, "spot", content, parentCommentId?)`
- **THEN** 发送 `POST /api/spots/{entityId}/comments`，使用 `authFetch`
- **AND** 返回 `ApiResponse<CommentData>`

---

### Requirement: BookmarkButton 收藏按钮

`app/posts/_components/BookmarkButton.tsx` SHALL 为 Client Component，接收 `entityId` + `entityType` + `initialBookmarked` props。

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
- **AND** 发送 `POST /api/{entityPath(entityType)}/{entityId}/bookmark`
- **AND** 成功时确认状态，失败时回滚 + `toast.error("收藏失败，请重试")`

#### Scenario: 未登录用户点击收藏

- **GIVEN** 用户未登录
- **WHEN** 用户点击收藏按钮
- **THEN** 跳转 `/login`，不发送 API

---

### Requirement: CommentSection 评论区

`app/posts/_components/CommentSection.tsx` SHALL 为 Client Component，接收 `entityId` + `entityType` props，管理评论输入 + 列表渲染。

#### Scenario: 初始加载评论列表

- **WHEN** 组件挂载
- **THEN** 调用 `fetchComments(entityId, entityType, 1, 20)`
- **AND** 渲染评论列表（每条含头像占位、用户ID截断、内容、时间、回复按钮）

#### Scenario: 空评论状态

- **WHEN** 评论列表为空
- **THEN** 显示空状态文案"暂无评论，发表第一条评论吧"

#### Scenario: 加载更多评论

- **WHEN** 评论列表有下一页
- **THEN** 底部显示"加载更多评论"按钮
- **AND** 点击后追加下一页数据

---

### Requirement: CommentInput 评论输入

`app/posts/_components/CommentInput.tsx` SHALL 接收 `entityId` + `entityType` + `parentCommentId?` + `onSuccess` props。

#### Scenario: 提交评论

- **WHEN** 用户输入内容后点击"发布"
- **THEN** 调用 `createComment(entityId, entityType, content, parentCommentId?)`
- **AND** 成功后清空输入框 + `toast.success("评论已发布")`
- **AND** 将新评论插入列表顶部
