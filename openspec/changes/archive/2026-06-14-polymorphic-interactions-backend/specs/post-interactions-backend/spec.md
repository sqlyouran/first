## MODIFIED Requirements

### Requirement: 评论实体 CommentEntity

系统 SHALL 提供 `CommentEntity` 继承 `BaseEntity`，包含 `entityId`(UUID, NOT NULL) + `entityType`(EntityType, NOT NULL) + `userId`(UUID, NOT NULL) + `content`(TEXT, NOT BLANK, max 10000) + `parentCommentId`(UUID, nullable)。原 `postId` 字段 SHALL 被 `entityId` + `entityType` 替代。帖子评论使用 `entityType = POST`。

#### Scenario: 创建顶层评论

- **GIVEN** `entityType = POST`, `entityId = <post-uuid>`
- **WHEN** 创建 CommentEntity 且 parentCommentId = null
- **THEN** 持久化成功，自动填充 id / createdAt / updatedAt / deleted=false

#### Scenario: 创建回复评论

- **GIVEN** 已存在评论 A
- **WHEN** 创建 CommentEntity 且 parentCommentId = A.id
- **THEN** 持久化成功

---

### Requirement: 发布评论

系统 SHALL 提供 `POST /api/posts/{postId}/comments` 端点，需 JWT 认证。内部 SHALL 以 `entityType = POST` 委托泛化 CommentService。

#### Scenario: 发布顶层评论成功

- **GIVEN** 用户已登录，帖子存在且未删除
- **WHEN** POST body `{ "content": "好文章！" }`
- **THEN** 返回 201 + 评论详情（id, entity_id, entity_type="post", user_id, content, parent_comment_id=null, created_at, request_id）

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

系统 SHALL 提供 `GET /api/posts/{postId}/comments?page=1&size=20` 端点，公开访问，返回分页顶层评论。内部 SHALL 以 `entityType = POST` 查询。

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

### Requirement: 收藏实体 BookmarkEntity

系统 SHALL 提供 `BookmarkEntity` 继承 `BaseEntity`，包含 `entityId`(UUID, NOT NULL) + `entityType`(EntityType, NOT NULL) + `userId`(UUID, NOT NULL)。表级唯一约束 SHALL 为 `(entity_id, entity_type, user_id)`。原 `postId` 字段 SHALL 被 `entityId` + `entityType` 替代。

#### Scenario: 唯一约束生效

- **GIVEN** 用户 A 已收藏帖子 X（entity_type=POST）
- **WHEN** 尝试插入相同 `(entity_id, entity_type, user_id)` 组合
- **THEN** 数据库抛出 unique constraint violation

---

### Requirement: Toggle 收藏

系统 SHALL 提供 `POST /api/posts/{postId}/bookmark` 端点，需 JWT 认证，toggle 语义。内部 SHALL 以 `entityType = POST` 委托泛化 BookmarkService。

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

系统 SHALL 提供 `GET /api/bookmarks?page=1&size=20&entity_type=POST|SPOT` 端点，需 JWT 认证，返回当前用户的收藏列表（分页）。`entity_type` 为可选参数。

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
