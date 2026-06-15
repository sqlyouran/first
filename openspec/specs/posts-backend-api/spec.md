## ADDED Requirements

### Requirement: PostException 统一异常

posts 模块 SHALL 使用 `PostException`（继承 RuntimeException），持有 HttpStatus + errorCode(snake_case) + message，由 GlobalExceptionHandler 统一映射到 ErrorResponse。

#### Scenario: PostException 映射到 ErrorResponse

- **WHEN** PostService 抛出 `PostException(HttpStatus.NOT_FOUND, "not_found", "Post not found")`
- **THEN** GlobalExceptionHandler 返回 HTTP 404
- **AND** 响应体包含 `request_id`（UUID v4）
- **AND** 响应体 `error_code: "not_found"`
- **AND** 响应体 `message: "Post not found"`
- **AND** 响应体 `details` 为 `{}`

---

### Requirement: StringListConverter JSON 序列化

`StringListConverter`（`AttributeConverter<List<String>, String>`）SHALL 使用 Jackson ObjectMapper 实现 `List<String>` ↔ JSON 字符串双向转换。

#### Scenario: 序列化 List 到 JSON 字符串

- **WHEN** Entity 字段值为 `["travel", "food"]`
- **THEN** 数据库列存储 `["travel","food"]`

#### Scenario: 反序列化 JSON 字符串到 List

- **WHEN** 数据库列值为 `["travel","food"]`
- **THEN** Entity 字段还原为 `List.of("travel", "food")`

#### Scenario: null 值处理

- **WHEN** Entity 字段值为 null
- **THEN** 数据库列存储 null
- **AND** 反向转换 null 列时返回空 List

---

### Requirement: JWT 认证 helper

PostController SHALL 提供 `requireUserId(HttpServletRequest)` helper 方法，从 Authorization header 提取 Bearer token 并通过 JwtService 解析用户 ID。

#### Scenario: 有效 Bearer token

- **GIVEN** 请求携带 `Authorization: Bearer <valid-jwt>`
- **WHEN** 调用 `requireUserId(request)`
- **THEN** 返回 JWT payload 中 `sub` 字段对应的 UUID

#### Scenario: 缺少 Authorization header

- **WHEN** 请求未携带 Authorization header
- **THEN** 抛出 PostException(HttpStatus.UNAUTHORIZED, "unauthorized", ...)

#### Scenario: 无效或过期 token

- **GIVEN** 请求携带 `Authorization: Bearer <invalid-or-expired-jwt>`
- **WHEN** 调用 `requireUserId(request)`
- **THEN** 抛出 PostException(HttpStatus.UNAUTHORIZED, "unauthorized", ...)

---

### Requirement: 行为合约对齐

posts-backend-api 的所有端点行为 SHALL 与 `openspec/specs/posts/spec.md` 中定义的 11 个 Requirement 完全一致。实现时以该 spec 为验收标准。

#### Scenario: spec 覆盖

- **WHEN** 运行 @WebMvcTest 切片测试
- **THEN** 测试用例覆盖 `specs/posts/spec.md` 中所有 Scenario

---

### Requirement: GET /api/posts/{id}/spots 帖子关联景点列表

`PostController` SHALL 提供 `GET /api/posts/{id}/spots`，委托 `SpotPostService` 返回关联景点列表 `PostSpotsResponse`（无分页）。

仅返回 `status=PUBLISHED` 且 `deleted=false` 的景点。

#### Scenario: 查询存在帖子的关联景点

- **GIVEN** `posts` 表存在 id=X 的未删除帖子，关联了 2 个 PUBLISHED 景点
- **WHEN** 请求 `GET /api/posts/X/spots`
- **THEN** HTTP 200，响应包含 `request_id`、`items`（2 条 SpotResponse）

#### Scenario: 帖子无关联景点

- **GIVEN** `posts` 表存在 id=X 的未删除帖子，无关联景点
- **WHEN** 请求 `GET /api/posts/X/spots`
- **THEN** HTTP 200，响应 `items=[]`

#### Scenario: 帖子不存在

- **WHEN** 请求 `GET /api/posts/<不存在的UUID>/spots`
- **THEN** HTTP 404，响应 `error_code="not_found"`

---

### Requirement: 帖子列表（分页）

任何人 SHALL 可通过 `GET /api/posts` 获取已发布帖子列表，无需认证。支持三种排序方式和两种分页模式。

#### Scenario: 获取默认第一页

- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`、`items`（帖子摘要数组，含互动统计字段）、`total`、`page: 1`、`size: 20`、`has_more`、`next_cursor`

#### Scenario: 指定分页参数

- **WHEN** 客户端提交 `GET /api/posts?page=2&size=10`
- **THEN** 返回 `page: 2`，`size: 10`，`items` 数量 ≤ 10

#### Scenario: 按最多点赞排序

- **WHEN** 客户端提交 `GET /api/posts?sort=most_upvoted`
- **THEN** `items` 按 `up_vote_count` 降序排列，使用 offset 分页

#### Scenario: 按最多评论排序

- **WHEN** 客户端提交 `GET /api/posts?sort=most_commented`
- **THEN** `items` 按 `comment_count` 降序排列，使用 offset 分页

#### Scenario: cursor 分页模式

- **WHEN** 客户端提交 `GET /api/posts?cursor={ISO8601}&size=20`
- **THEN** 返回 `created_at < cursor` 的帖子，`next_cursor` 为最后一条的 `created_at`，`page` 为 null

#### Scenario: cursor 与 sort 冲突时降级为 offset

- **WHEN** 客户端提交 `GET /api/posts?cursor=...&sort=most_upvoted`
- **THEN** cursor 参数被忽略，使用 offset 分页

#### Scenario: 互动统计字段正确性

- **GIVEN** 帖子 A 有 3 条评论（1 条已软删除）、5 个点赞、2 个收藏
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** `comment_count: 2`，`up_vote_count: 5`，`bookmark_count: 2`

---

### Requirement: 用户帖子列表

任何人 SHALL 可通过 `GET /api/users/{user_id}/posts` 获取指定用户的已发布帖子列表。支持排序和分页，行为与全局帖子列表一致。

#### Scenario: 获取某用户的帖子列表

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts`
- **THEN** 响应体格式与 `GET /api/posts` 一致，`items` 仅包含该用户 status=published 且 deleted=false 的帖子

#### Scenario: 用户不存在或无帖子

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts` 且 user_id 不存在
- **THEN** 返回 `items` 为空数组，`total: 0`

---

### Requirement: 帖子数据模型

Post 实体 SHALL 继承 `BaseEntity`，包含 title、content、cover_image、tags、status、author_id。PostEntity 不存储互动统计字段，通过聚合查询实时计算。

#### PostStatus 枚举

| 值 | 含义 | 公开可见 |
|---|---|---|
| `DRAFT` | 草稿 | 否 |
| `PUBLISHED` | 已发布 | 是 |
| `ARCHIVED` | 已归档 | 否 |

---

### Requirement: 列表接口排序参数

`GET /api/posts` 和 `GET /api/users/{user_id}/posts` SHALL 支持 `sort` 查询参数：`latest`（默认）、`most_upvoted`、`most_commented`。

#### Scenario: 非法 sort 值

- **WHEN** 客户端提交 `sort=unknown`
- **THEN** 返回 HTTP `400`，`error_code: "validation_error"`

---

### Requirement: 复合 Cursor 编码与解码

`PostSortBy` SHALL 提供 `encodeCursor(long count, Instant createdAt)` 和 `decodeCursor(String cursor)` 静态方法，分别编码和解码复合 cursor。LATEST 仅使用 ISO-timestamp，MOST_UPVOTED / MOST_COMMENTED 使用 `"count:timestamp"` 格式。

#### Scenario: LATEST 编码

- **WHEN** `PostSortBy.LATEST.encodeCursor(0, Instant.parse("2026-06-12T08:00:00Z"))`
- **THEN** 返回 `"2026-06-12T08:00:00Z"`

#### Scenario: MOST_UPVOTED 编码

- **WHEN** `PostSortBy.MOST_UPVOTED.encodeCursor(5, Instant.parse("2026-06-12T08:00:00Z"))`
- **THEN** 返回 `"5:2026-06-12T08:00:00Z"`

#### Scenario: 解码复合 cursor

- **WHEN** `PostSortBy.MOST_UPVOTED.decodeCursor("5:2026-06-12T08:00:00Z")`
- **THEN** 返回包含 `count=5` 和 `timestamp=2026-06-12T08:00:00Z` 的解析结果

#### Scenario: 解码 LATEST cursor

- **WHEN** `PostSortBy.LATEST.decodeCursor("2026-06-12T08:00:00Z")`
- **THEN** 返回包含 `timestamp=2026-06-12T08:00:00Z` 的解析结果（count 不使用）

#### Scenario: 非法 cursor 格式

- **WHEN** cursor 格式无法解析（非 ISO-8601 / count:timestamp）
- **THEN** 抛出 `IllegalArgumentException`

---

### Requirement: 帖子列表分页与排序

`GET /api/posts` 和 `GET /api/users/{userId}/posts` SHALL 同时支持 offset 分页（page/size）和 cursor 分页（cursor/size），cursor 在所有排序模式下均有效。当 `cursor` 参数存在时优先 cursor 模式，忽略 `page` 参数。cursor 模式下响应包含 `next_cursor`（非 null，有数据时）和 `has_more`（boolean）。

#### Scenario: cursor 分页 sort=latest

- **WHEN** 请求 `GET /api/posts?sort=latest&cursor=2026-06-12T00:00:00Z&size=20`
- **THEN** 返回 `createdAt < 2026-06-12T00:00:00Z` 的前 20 条帖子
- **AND** `next_cursor` 为最后一条的 `createdAt`（ISO-8601 格式）
- **AND** `has_more` 为 `true`（若还有更多）或 `false`

#### Scenario: cursor 分页 sort=most_upvoted

- **WHEN** 请求 `GET /api/posts?sort=most_upvoted&cursor=5:2026-06-12T00:00:00Z&size=20`
- **THEN** 返回 `voteCount < 5 OR (voteCount = 5 AND createdAt < 2026-06-12T00:00:00Z)` 的前 20 条帖子
- **AND** `next_cursor` 为 `"voteCount:createdAt"` 复合编码（如 `"3:2026-06-11T12:00:00Z"`）

#### Scenario: cursor 分页 sort=most_commented

- **WHEN** 请求 `GET /api/posts?sort=most_commented&cursor=3:2026-06-12T00:00:00Z&size=20`
- **THEN** 返回 `commentCount < 3 OR (commentCount = 3 AND createdAt < 2026-06-12T00:00:00Z)` 的前 20 条帖子（`commentCount` 仅计 `deleted=false`）
- **AND** `next_cursor` 为复合编码

#### Scenario: 首次加载（无 cursor）返回 next_cursor

- **WHEN** 请求 `GET /api/posts?sort=latest&size=20`（无 cursor 参数）
- **THEN** 返回第一页 offset 分页结果
- **AND** `next_cursor` 为最后一条帖子的 `createdAt`（非 null，若有数据）
- **AND** `has_more` 为 `true`（若还有更多数据）

#### Scenario: 首次加载聚合排序返回 next_cursor

- **WHEN** 请求 `GET /api/posts?sort=most_upvoted&size=20`（无 cursor 参数）
- **THEN** 返回第一页 offset 分页结果（按 upVoteCount DESC 排序）
- **AND** `next_cursor` 为最后一条帖子的 `"voteCount:createdAt"` 复合编码（非 null）

#### Scenario: 空结果 cursor 为 null

- **WHEN** 请求返回 0 条帖子
- **THEN** `next_cursor` 为 `null`，`has_more` 为 `false`

---

### Requirement: 列表项互动统计字段

帖子列表的每个 item SHALL 包含 `comment_count`、`up_vote_count`、`bookmark_count` 三个聚合字段。

#### Scenario: comment_count 不含软删除评论

- **GIVEN** 帖子有 5 条评论，其中 2 条已软删除
- **WHEN** 列表返回该帖子
- **THEN** `comment_count: 3`
