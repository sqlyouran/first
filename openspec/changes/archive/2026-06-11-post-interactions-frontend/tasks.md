## 1. 基础设施 — Toast + 依赖

- [x] 1.1 安装 sonner 依赖：`cd frontend && npm install sonner`
- [x] 1.2 `app/layout.tsx` 添加 `<Toaster />` 组件（从 sonner 导入）
- [x] 1.3 验证：任意页面调用 `toast.error("test")` 确认 toast 弹出

## 2. 后端 — bookmark-status 端点

- [x] 2.1 `BookmarkService` 新增 `getBookmarkStatus(postId, optionalUserId, requestId)` 方法：可选认证，未登录返回 false
- [x] 2.2 `BookmarkController` 新增 `GET /api/posts/{postId}/bookmark-status` 端点
- [x] 2.3 `BookmarkControllerTest` 新增测试：已登录已收藏 / 已登录未收藏 / 未登录 / 帖子不存在
- [x] 2.4 验证：`./mvnw test` 全部绿灯

## 3. API 客户端层 — interactions.ts

- [x] 3.1 新增 `lib/api/interactions.ts`：定义 `VoteStatsData`、`VoteData`、`BookmarkStatusData`、`BookmarkData`、`CommentData`、`CommentListData` 类型
- [x] 3.2 实现投票 API：`fetchVoteStats(postId)`（普通 fetch）、`vote(postId, voteType)`（authFetch）、`removeVote(postId)`（authFetch）
- [x] 3.3 实现收藏 API：`fetchBookmarkStatus(postId)`（authFetch）、`toggleBookmark(postId)`（authFetch）
- [x] 3.4 实现评论 API：`fetchComments(postId, page, size)`（普通 fetch）、`fetchReplies(commentId, page, size)`（普通 fetch）、`createComment(postId, content, parentId?)`（authFetch）、`deleteComment(postId, commentId)`（authFetch）
- [x] 3.5 新增 `interactions.test.ts`：验证各函数 URL 拼接 + error handling

## 4. VoteButtons 投票按钮组

- [x] 4.1 新增 `app/posts/_components/VoteButtons.tsx`（"use client"）：接收 `postId`、`initialVoteStats`（`{ up_count, down_count, user_vote }`）
- [x] 4.2 实现乐观更新逻辑：点击时立即更新 UI state，调用 API，失败回滚 + `toast.error`
- [x] 4.3 实现未登录跳转：`useAuthStore` 检查 `isAuthenticated`，未登录 `router.push("/login")`
- [x] 4.4 样式：ThumbsUp / ThumbsDown 图标（lucide-react）+ 计数 + 高亮态（`text-blue-700`）
- [x] 4.5 新增 `VoteButtons.test.tsx`：初始渲染 / 乐观更新成功 / 乐观更新回滚 / 未登录跳转

## 5. BookmarkButton 收藏按钮

- [x] 5.1 新增 `app/posts/_components/BookmarkButton.tsx`（"use client"）：接收 `postId`、`initialBookmarked`
- [x] 5.2 实现乐观更新：点击切换图标（Bookmark ↔ BookmarkCheck），失败回滚 + `toast.error`
- [x] 5.3 实现未登录跳转：同 VoteButtons
- [x] 5.4 样式：填充态 `text-blue-700`，空心态 `text-slate-500`
- [x] 5.5 新增 `BookmarkButton.test.tsx`：初始已收藏 / 初始未收藏 / 乐观更新回滚 / 未登录跳转

## 6. CommentInput 评论输入

- [x] 6.1 新增 `app/posts/_components/CommentInput.tsx`（"use client"）：接收 `postId`、`parentCommentId?`、`onSuccess` callback
- [x] 6.2 已登录：textarea + "发布"按钮，按钮在内容为空时 disabled
- [x] 6.3 未登录：显示"登录后即可评论"+ Link 跳转 `/login`
- [x] 6.4 提交成功：清空输入 + `toast.success("评论已发布")` + 调用 `onSuccess`
- [x] 6.5 新增 `CommentInput.test.tsx`：已登录渲染 / 未登录渲染 / 空内容禁用 / 提交成功

## 7. CommentItem 评论项

- [x] 7.1 新增 `app/posts/_components/CommentItem.tsx`（"use client"）：接收 `comment`、`depth`、`onReply?` callback
- [x] 7.2 渲染头像占位（`div.bg-slate-200.rounded-full`）+ `user_id.slice(0,8)` + 内容 + 相对时间
- [x] 7.3 已删除评论：显示 `[已删除]`（`text-slate-400 italic`）+ "已删除用户"，无回复按钮
- [x] 7.4 嵌套回复：`depth < 2` 时渲染子回复列表，`depth >= 2` 时显示"查看更多 N 条回复"按钮
- [x] 7.5 "查看更多"按钮：点击调用 `fetchReplies(commentId)`，加载后渲染子回复
- [x] 7.6 回复按钮：点击展开 CommentInput（`parentCommentId` = 当前评论 id）
- [x] 7.7 新增 `CommentItem.test.tsx`：普通评论 / 已删除评论 / 嵌套2层 / 查看更多加载

## 8. CommentSection 评论区

- [x] 8.1 新增 `app/posts/_components/CommentSection.tsx`（"use client"）：接收 `postId`
- [x] 8.2 挂载时 `fetchComments(postId, 1, 20)`，渲染 CommentList
- [x] 8.3 空状态：显示"暂无评论，发表第一条评论吧"
- [x] 8.4 加载更多：列表有下一页时底部显示"加载更多评论"按钮
- [x] 8.5 顶部 CommentInput：新评论成功后插入列表顶部（prepend）
- [x] 8.6 新增 `CommentSection.test.tsx`：加载评论 / 空状态 / 发布新评论 / 加载更多

## 9. 详情页集成

- [x] 9.1 修改 `app/posts/[id]/page.tsx`：SSR 并行 fetch `vote-stats` + `bookmark-status`
- [x] 9.2 内容卡片下方添加互动栏：`flex items-center justify-between border-y border-slate-200 py-4`
- [x] 9.3 互动栏左侧渲染 `<VoteButtons />`，右侧渲染 `<BookmarkButton />`
- [x] 9.4 互动栏下方渲染 `<CommentSection postId={id} />`
- [x] 9.5 更新 `page.test.tsx`：验证互动组件渲染

## 10. 集成验证

- [x] 10.1 `cd frontend && npm test`：所有测试绿灯
- [ ] 10.2 启动 dev server，手动验证投票/收藏/评论交互流程
- [ ] 10.3 检查未登录用户点击各互动按钮跳转登录页
