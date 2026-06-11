## ADDED Requirements

### Requirement: 认证工具类 AuthUtil

系统 SHALL 提供 `util/AuthUtil` 静态工具类，包含 `requireUserId(HttpServletRequest, JwtService)` 和 `optionalUserId(HttpServletRequest, JwtService)` 和 `getRequestId(HttpServletRequest)` 三个方法。

#### Scenario: requireUserId 解析有效 token

- **GIVEN** 请求携带 `Authorization: Bearer <valid-jwt>`
- **WHEN** 调用 `AuthUtil.requireUserId(request, jwtService)`
- **THEN** 返回 JWT payload 中 `sub` 字段对应的 UUID

#### Scenario: requireUserId 缺少 token

- **WHEN** 请求未携带 Authorization header
- **THEN** 抛出 PostException(HttpStatus.UNAUTHORIZED, "unauthorized", ...)

#### Scenario: optionalUserId 有效 token

- **GIVEN** 请求携带有效 Bearer token
- **WHEN** 调用 `AuthUtil.optionalUserId(request, jwtService)`
- **THEN** 返回 `Optional.of(userId)`

#### Scenario: optionalUserId 无 token

- **WHEN** 请求未携带 Authorization header
- **THEN** 返回 `Optional.empty()`

---

### Requirement: 评论实体 CommentEntity

系统 SHALL 提供 `CommentEntity` 继承 `BaseEntity`，包含 postId(UUID, not null) + userId(UUID, not null) + content(TEXT, not blank, max 10000) + parentCommentId(UUID, nullable)。

#### Scenario: 创建顶层评论

- **WHEN** 创建 CommentEntity 且 parentCommentId = null
- **THEN** 持久化成功，自动填充 id / createdAt / updatedAt / deleted=false

#### Scenario: 创建回复评论

- **GIVEN** 已存在评论 A
- **WHEN** 创建 CommentEntity 且 parentCommentId = A.id
- **THEN** 持久化成功

---

### Requirement: 发布评论

系统 SHALL 提供 `POST /api/posts/{postId}/comments` 端点，需 JWT 认证。

#### Scenario: 发布顶层评论成功

- **GIVEN** 用户已登录，帖子存在且未删除
- **WHEN** POST body `{ "content": "好文章！" }`
- **THEN** 返回 201 + 评论详情（id, post_id, user_id, content, parent_comment_id=null, created_at, request_id）

#### Scenario: 发布回复评论成功

- **GIVEN** 用户已登录，帖子存在，父评论存在
- **WHEN** POST body `{ "content": "同意", "parent_comment_id": "<uuid>" }`
- **THEN** 返回 201 + 评论详情（parent_comment_id = 指定值）

#### Scenario: 帖子不存在

- **WHEN** postId 对应帖子不存在或已删除
- **THEN** 返回 404 + error_code "not_found"

#### Scenario: 父评论不存在

- **WHEN** parent_comment_id 不为 null 且对应评论不存在
- **THEN** 返回 404 + error_code "not_found"

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 401

---

### Requirement: 查询帖子顶层评论

系统 SHALL 提供 `GET /api/posts/{postId}/comments?page=1&size=20` 端点，公开访问，返回分页顶层评论。

#### Scenario: 正常分页返回

- **GIVEN** 帖子有 25 条顶层评论
- **WHEN** GET ?page=1&size=20
- **THEN** 返回 `{ items: [...20条], total: 25, page: 1, size: 20, request_id }` 按 created_at ASC 排序

#### Scenario: 软删除评论显示 [已删除]

- **GIVEN** 帖子有一条已软删除的顶层评论
- **WHEN** GET 评论列表
- **THEN** 该评论 content 显示为 "[已删除]"，其他字段正常返回

#### Scenario: 帖子不存在

- **WHEN** postId 对应帖子不存在
- **THEN** 返回 404

---

### Requirement: 查询评论的回复

系统 SHALL 提供 `GET /api/comments/{commentId}/replies?page=1&size=20` 端点，公开访问，返回该评论的子回复（分页）。

#### Scenario: 正常返回回复列表

- **GIVEN** 评论 A 有 5 条回复
- **WHEN** GET /api/comments/A/replies?page=1&size=20
- **THEN** 返回 `{ items: [...5条], total: 5, page: 1, size: 20 }` 按 created_at ASC

#### Scenario: 包含软删除的回复

- **GIVEN** 评论 A 有一条已软删除的回复
- **WHEN** GET 回复列表
- **THEN** 该回复 content 为 "[已删除]"

---

### Requirement: 删除评论

系统 SHALL 提供 `DELETE /api/posts/{postId}/comments/{commentId}` 端点，需 JWT 认证，执行软删除。

#### Scenario: 作者删除自己的评论

- **GIVEN** 用户是评论作者
- **WHEN** DELETE 该评论
- **THEN** 返回 204，评论 deleted=true

#### Scenario: 非作者尝试删除

- **GIVEN** 用户不是评论作者
- **WHEN** DELETE 该评论
- **THEN** 返回 403 + error_code "access_denied"

#### Scenario: 评论不存在

- **WHEN** commentId 不存在或已删除
- **THEN** 返回 404

---

### Requirement: 投票实体 VoteEntity

系统 SHALL 提供 `VoteEntity` 继承 `BaseEntity`，包含 postId(UUID, not null) + userId(UUID, not null) + voteType(枚举 UP/DOWN)。表级 unique constraint(post_id, user_id) 保证一人一票。

#### Scenario: 唯一约束生效

- **GIVEN** 用户 A 已对帖子 X 投票
- **WHEN** 尝试插入相同 post_id + user_id 的新记录
- **THEN** 数据库抛出 unique constraint violation

---

### Requirement: 创建或切换投票

系统 SHALL 提供 `POST /api/posts/{postId}/vote` 端点，需 JWT 认证。

#### Scenario: 首次投票

- **GIVEN** 用户未对该帖子投票
- **WHEN** POST body `{ "vote_type": "up" }`
- **THEN** 返回 200 + `{ vote_type: "up", request_id }`

#### Scenario: 相同投票 → 取消

- **GIVEN** 用户已投 UP
- **WHEN** POST body `{ "vote_type": "up" }`
- **THEN** 返回 200 + `{ vote_type: null, request_id }`（投票已取消）

#### Scenario: 不同投票 → 切换

- **GIVEN** 用户已投 UP
- **WHEN** POST body `{ "vote_type": "down" }`
- **THEN** 返回 200 + `{ vote_type: "down", request_id }`（已切换）

#### Scenario: 帖子不存在

- **WHEN** postId 对应帖子不存在
- **THEN** 返回 404

---

### Requirement: 取消投票

系统 SHALL 提供 `DELETE /api/posts/{postId}/vote` 端点，需 JWT 认证。

#### Scenario: 取消已有投票

- **GIVEN** 用户已对该帖子投票
- **WHEN** DELETE
- **THEN** 返回 204，投票记录被删除

#### Scenario: 未投票时取消

- **GIVEN** 用户未对该帖子投票
- **WHEN** DELETE
- **THEN** 返回 204（幂等，不报错）

---

### Requirement: 获取投票统计

系统 SHALL 提供 `GET /api/posts/{postId}/vote-stats` 端点，支持可选认证。

#### Scenario: 未登录用户查看统计

- **GIVEN** 帖子有 10 个 UP + 3 个 DOWN
- **WHEN** GET 无 Authorization header
- **THEN** 返回 200 + `{ up_count: 10, down_count: 3, user_vote: null, request_id }`

#### Scenario: 已登录用户查看统计

- **GIVEN** 帖子有 10 UP + 3 DOWN，当前用户已投 UP
- **WHEN** GET 带有效 Bearer token
- **THEN** 返回 200 + `{ up_count: 10, down_count: 3, user_vote: "up", request_id }`

#### Scenario: 帖子不存在

- **WHEN** postId 对应帖子不存在
- **THEN** 返回 404

---

### Requirement: 收藏实体 BookmarkEntity

系统 SHALL 提供 `BookmarkEntity` 继承 `BaseEntity`，包含 postId(UUID, not null) + userId(UUID, not null)。表级 unique constraint(post_id, user_id) 防重复收藏。

#### Scenario: 唯一约束生效

- **GIVEN** 用户 A 已收藏帖子 X
- **WHEN** 尝试插入相同 post_id + user_id 的新记录
- **THEN** 数据库抛出 unique constraint violation

---

### Requirement: Toggle 收藏

系统 SHALL 提供 `POST /api/posts/{postId}/bookmark` 端点，需 JWT 认证，toggle 语义。

#### Scenario: 首次收藏

- **GIVEN** 用户未收藏该帖子
- **WHEN** POST
- **THEN** 返回 200 + `{ bookmarked: true, request_id }`

#### Scenario: 取消收藏

- **GIVEN** 用户已收藏该帖子
- **WHEN** POST
- **THEN** 返回 200 + `{ bookmarked: false, request_id }`

#### Scenario: 帖子不存在

- **WHEN** postId 对应帖子不存在
- **THEN** 返回 404

---

### Requirement: 获取当前用户收藏列表

系统 SHALL 提供 `GET /api/bookmarks?page=1&size=20` 端点，需 JWT 认证，返回当前用户的收藏帖子列表（分页）。

#### Scenario: 正常分页返回

- **GIVEN** 用户有 30 条收藏
- **WHEN** GET ?page=1&size=20
- **THEN** 返回 `{ items: [...20条], total: 30, page: 1, size: 20, request_id }` 按 created_at DESC

#### Scenario: 无收藏

- **WHEN** 用户无任何收藏
- **THEN** 返回 `{ items: [], total: 0, page: 1, size: 20 }`

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 401
