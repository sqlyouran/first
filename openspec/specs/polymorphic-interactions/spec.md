## ADDED Requirements

### Requirement: EntityType 枚举

系统 SHALL 提供 `entity/EntityType` 枚举，包含 `POST` 和 `SPOT` 两个值，供评论和收藏模块共享引用。

#### Scenario: 枚举值完整性

- **WHEN** 引用 `EntityType.values()`
- **THEN** 返回 `[POST, SPOT]`

---

### Requirement: CommentEntity 多态关联字段

系统 SHALL 提供 `CommentEntity` 包含 `entityId`(UUID, NOT NULL) + `entityType`(EntityType, NOT NULL) 替代原 `postId` 字段。`userId` + `content` + `parentCommentId` 保持不变。

#### Scenario: 创建帖子评论

- **GIVEN** `entityType = POST`, `entityId = <post-uuid>`
- **WHEN** 持久化 CommentEntity
- **THEN** 成功保存，`entity_id` 和 `entity_type` 列正确写入

#### Scenario: 创建景点评论

- **GIVEN** `entityType = SPOT`, `entityId = <spot-uuid>`
- **WHEN** 持久化 CommentEntity
- **THEN** 成功保存，`entity_id` 和 `entity_type` 列正确写入

---

### Requirement: BookmarkEntity 多态关联字段

系统 SHALL 提供 `BookmarkEntity` 包含 `entityId`(UUID, NOT NULL) + `entityType`(EntityType, NOT NULL) 替代原 `postId` 字段。表级唯一约束 SHALL 为 `(entity_id, entity_type, user_id)`。

#### Scenario: 收藏帖子

- **GIVEN** `entityType = POST`, `entityId = <post-uuid>`, `userId = <user-uuid>`
- **WHEN** 持久化 BookmarkEntity
- **THEN** 成功保存

#### Scenario: 收藏景点

- **GIVEN** `entityType = SPOT`, `entityId = <spot-uuid>`, `userId = <user-uuid>`
- **WHEN** 持久化 BookmarkEntity
- **THEN** 成功保存

#### Scenario: 唯一约束 — 同类型防重复

- **GIVEN** 用户 A 已收藏帖子 X（entity_type=POST）
- **WHEN** 尝试再次插入相同 `(entity_id, entity_type, user_id)` 组合
- **THEN** 数据库抛出 unique constraint violation

#### Scenario: 唯一约束 — 不同类型互不干扰

- **GIVEN** 用户 A 已收藏帖子 X（entity_type=POST, entity_id=X）
- **WHEN** 用户 A 收藏景点 X（entity_type=SPOT, entity_id=X，假设 UUID 相同）
- **THEN** 成功保存（不同 entity_type 不冲突）

---

### Requirement: 景点收藏状态查询

系统 SHALL 提供 `GET /api/spots/{spotId}/bookmark-status` 端点，支持可选认证。

#### Scenario: 已登录用户已收藏景点

- **GIVEN** 用户已登录且已收藏该景点
- **WHEN** GET 该端点
- **THEN** 返回 200 + `{ bookmarked: true, request_id }`

#### Scenario: 已登录用户未收藏景点

- **GIVEN** 用户已登录但未收藏该景点
- **WHEN** GET 该端点
- **THEN** 返回 200 + `{ bookmarked: false, request_id }`

#### Scenario: 未登录用户

- **WHEN** 未携带 Authorization header
- **THEN** 返回 200 + `{ bookmarked: false, request_id }`

#### Scenario: 景点不存在

- **WHEN** spotId 对应景点不存在或已删除
- **THEN** 返回 404 + error_code "not_found"

---

### Requirement: 景点收藏 Toggle

系统 SHALL 提供 `POST /api/spots/{spotId}/bookmark` 端点，需 JWT 认证，toggle 语义。

#### Scenario: 首次收藏景点

- **GIVEN** 用户未收藏该景点
- **WHEN** POST
- **THEN** 返回 200 + `{ bookmarked: true, request_id }`

#### Scenario: 取消收藏景点

- **GIVEN** 用户已收藏该景点
- **WHEN** POST
- **THEN** 返回 200 + `{ bookmarked: false, request_id }`

#### Scenario: 景点不存在

- **WHEN** spotId 对应景点不存在或已删除
- **THEN** 返回 404

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 401

---

### Requirement: 景点评论发布

系统 SHALL 提供 `POST /api/spots/{spotId}/comments` 端点，需 JWT 认证。

#### Scenario: 发布顶层评论成功

- **GIVEN** 用户已登录，景点存在且未删除
- **WHEN** POST body `{ "content": "值得一去！" }`
- **THEN** 返回 201 + 评论详情（id, entity_id, entity_type="spot", user_id, content, parent_comment_id=null, created_at, request_id）

#### Scenario: 景点不存在

- **WHEN** spotId 对应景点不存在或已删除
- **THEN** 返回 404 + error_code "not_found"

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 401

---

### Requirement: 景点评论查询

系统 SHALL 提供 `GET /api/spots/{spotId}/comments?page=1&size=20` 端点，公开访问，返回分页顶层评论。

#### Scenario: 正常分页返回

- **GIVEN** 景点有 25 条顶层评论
- **WHEN** GET ?page=1&size=20
- **THEN** 返回 `{ items: [...20条], total: 25, page: 1, size: 20, request_id }` 按 created_at ASC 排序

#### Scenario: 景点不存在

- **WHEN** spotId 对应景点不存在
- **THEN** 返回 404

---

### Requirement: 收藏列表 entity_type 筛选

系统 SHALL 在 `GET /api/bookmarks` 端点支持可选 `entity_type` 查询参数（POST/SPOT）。

#### Scenario: 按 POST 筛选

- **GIVEN** 用户收藏了 5 篇帖子 + 3 个景点
- **WHEN** GET /api/bookmarks?entity_type=POST
- **THEN** 返回 `{ items: [...5条帖子收藏], total: 5 }`

#### Scenario: 按 SPOT 筛选

- **GIVEN** 用户收藏了 5 篇帖子 + 3 个景点
- **WHEN** GET /api/bookmarks?entity_type=SPOT
- **THEN** 返回 `{ items: [...3条景点收藏], total: 3 }`

#### Scenario: 不传 entity_type

- **GIVEN** 用户收藏了 5 篇帖子 + 3 个景点
- **WHEN** GET /api/bookmarks（不传 entity_type）
- **THEN** 返回全部 8 条收藏，按 created_at DESC 分页

#### Scenario: 无效 entity_type

- **WHEN** GET /api/bookmarks?entity_type=INVALID
- **THEN** 返回 400 + error_code "validation_error"
