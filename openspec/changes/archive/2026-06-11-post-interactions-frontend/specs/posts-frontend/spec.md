## MODIFIED Requirements

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
