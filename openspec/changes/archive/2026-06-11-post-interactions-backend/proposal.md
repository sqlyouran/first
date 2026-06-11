## Why

帖子详情页当前只有内容展示，缺乏用户互动能力。为构建社区氛围，需补充评论、投票（点赞/点踩）、收藏三项核心互动功能的后端 API。同时，认证逻辑（`requireUserId`）已在多个 Controller 中重复出现（第 3 次），触发 DRY 提炼。

## What Changes

- **提炼认证工具**：从 PostController 抽取 `requireUserId` / `getRequestId` 到公共工具类，消除 AuthController / PostController / 新 Controller 间的重复
- **新增 CommentEntity**（继承 BaseEntity）：postId + userId + content(TEXT) + parentCommentId(可 null)，支持无限嵌套回复
- **新增 CommentController**：发布评论/回复、按帖子查顶层评论(分页)、按评论查回复(分页)、软删除评论
- **新增 VoteEntity**（继承 BaseEntity）：postId + userId + voteType(UP/DOWN)，unique constraint(post_id, user_id) 保证一人一票
- **新增 VoteController**：POST 创建/切换投票、DELETE 取消投票、GET 投票统计(可选认证)
- **新增 BookmarkEntity**（继承 BaseEntity）：postId + userId，unique constraint(post_id, user_id) 防重复
- **新增 BookmarkController**：POST toggle 收藏、GET 当前用户收藏列表(分页)
- **复用 PostException**：三个模块共用已有异常类，GlobalExceptionHandler 无需修改
- **软删除评论展示**：被删评论内容置为 [已删除]，子回复仍可见（Reddit 风格）
- **投票统计可选认证**：未登录返回 `user_vote: null`，已登录返回实际投票状态

## Capabilities

### New Capabilities
- `post-interactions-backend`: 帖子互动后端 API——评论(CRUD + 嵌套回复)、投票(创建/切换/取消/统计)、收藏(toggle/列表)的完整 HTTP 端点与业务逻辑

### Modified Capabilities
（无——现有 `posts-backend-api` capability 的 requirements 不变，仅提炼其 Controller 内部的认证方法到公共工具类）

## Impact

- **后端代码**：`backend/src/main/java/com/mooc/app/` 新增 entity × 3 / repository × 3 / service × 3 / controller × 3 / dto / 公共工具类
- **数据库**：新建 `comments`、`votes`、`bookmarks` 三张表，含 unique constraint
- **API 端点**：新增 8 个端点（Comment 4 + Vote 3 + Bookmark 2），其中 GET vote-stats 支持可选认证
- **安全**：写操作需 JWT，GET vote-stats 可选认证，GET 评论列表公开
- **依赖**：无新增 Maven 依赖（JPA / validation / jackson 均已存在）
- **前端**：本次不动，前端集成留给后续 change
