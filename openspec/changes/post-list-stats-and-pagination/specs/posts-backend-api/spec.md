## MODIFIED Requirements

### Requirement: 帖子列表（分页）

任何人 SHALL 可通过 `GET /api/posts` 获取已发布帖子列表，无需认证。支持三种排序方式和两种分页模式。

#### Scenario: 获取默认第一页

- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`
- **AND** 响应体包含 `items`（帖子摘要数组，每项含 id / title / cover_image / tags / status / created_at / updated_at / comment_count / up_vote_count / bookmark_count，不含 content 全文）
- **AND** `items` 按 `created_at` 降序排列（默认排序）
- **AND** 响应体包含 `total`（总记录数）
- **AND** 响应体包含 `page: 1`
- **AND** 响应体包含 `size: 20`
- **AND** 响应体包含 `has_more`（boolean）
- **AND** 响应体包含 `next_cursor`（nullable，ISO 8601 时间戳或 null）

#### Scenario: 指定分页参数

- **WHEN** 客户端提交 `GET /api/posts?page=2&size=10`
- **THEN** 返回 HTTP `200`
- **AND** 响应体 `page: 2`，`size: 10`
- **AND** `items` 数量 ≤ 10

#### Scenario: 列表仅包含已发布帖子

- **GIVEN** 数据库中存在 status=published / draft / archived 的帖子
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 响应 `items` 中所有帖子的 `status` 均为 `"published"`

#### Scenario: 列表不包含已删除帖子

- **GIVEN** 数据库中存在已逻辑删除的帖子
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 响应 `items` 中不包含已删除的帖子

#### Scenario: size 超过上限被截断

- **WHEN** 客户端提交 `GET /api/posts?size=200`
- **THEN** 返回 HTTP `200`
- **AND** 实际 `size` 不超过 100

#### Scenario: 按最多点赞排序

- **GIVEN** 数据库中存在多个帖子，各有不同的点赞数
- **WHEN** 客户端提交 `GET /api/posts?sort=most_upvoted`
- **THEN** 返回 HTTP `200`
- **AND** `items` 按 `up_vote_count` 降序排列
- **AND** `up_vote_count` 相同时按 `created_at` 降序排列
- **AND** 使用 offset 分页模式（cursor 参数被忽略）

#### Scenario: 按最多评论排序

- **GIVEN** 数据库中存在多个帖子，各有不同的评论数
- **WHEN** 客户端提交 `GET /api/posts?sort=most_commented`
- **THEN** 返回 HTTP `200`
- **AND** `items` 按 `comment_count` 降序排列（仅统计 deleted=false 的评论）
- **AND** `comment_count` 相同时按 `created_at` 降序排列
- **AND** 使用 offset 分页模式（cursor 参数被忽略）

#### Scenario: cursor 分页模式

- **GIVEN** 数据库中存在多个帖子
- **WHEN** 客户端提交 `GET /api/posts?cursor=2026-06-10T12:00:00Z&size=20`
- **THEN** 返回 `created_at` 早于 cursor 的帖子
- **AND** `next_cursor` 为返回结果中最后一条帖子的 `created_at`
- **AND** `has_more` 为 true（当还有更多数据）或 false（当无更多数据）
- **AND** `page` 字段为 null
- **AND** 返回的 `items` 数量 ≤ size

#### Scenario: cursor 与 sort 冲突时降级为 offset

- **WHEN** 客户端提交 `GET /api/posts?cursor=...&sort=most_upvoted`
- **THEN** cursor 参数被忽略
- **AND** 使用 offset 分页模式（page=1）

#### Scenario: 互动统计字段正确性

- **GIVEN** 帖子 A 有 3 条评论（1 条已软删除）、5 个点赞、2 个收藏
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 帖子 A 的 `comment_count` 为 2（不含软删除）
- **AND** 帖子 A 的 `up_vote_count` 为 5
- **AND** 帖子 A 的 `bookmark_count` 为 2

#### Scenario: 无效排序参数

- **WHEN** 客户端提交 `GET /api/posts?sort=invalid_sort`
- **THEN** 返回 HTTP `400` 或降级为默认排序（`latest`）

---

### Requirement: 用户帖子列表

任何人 SHALL 可通过 `GET /api/users/{user_id}/posts` 获取指定用户的已发布帖子列表，无需认证。支持排序和分页，行为与全局帖子列表一致。

#### Scenario: 获取某用户的帖子列表

- **GIVEN** 用户存在且有已发布帖子
- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts`
- **THEN** 返回 HTTP `200`
- **AND** 响应体格式与 `GET /api/posts` 一致（含互动统计、分页、排序）
- **AND** `items` 仅包含该用户 status=published 且 deleted=false 的帖子
- **AND** 默认按 `created_at` 降序排列

#### Scenario: 用户不存在或无帖子

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts` 且 user_id 不存在或该用户无已发布帖子
- **THEN** 返回 HTTP `200`
- **AND** `items` 为空数组，`total: 0`

#### Scenario: 支持分页和排序参数

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts?page=1&size=10&sort=most_upvoted`
- **THEN** 返回分页结果，格式与全局帖子列表一致
- **AND** 支持 cursor 分页和排序参数，行为与全局列表一致

---

### Requirement: 帖子数据模型

Post 实体 SHALL 继承 `BaseEntity`，包含以下业务字段：

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| title | String | `@NotBlank`, `@Size(max = 200)` | 帖子标题 |
| content | String | `@NotBlank`, `@Size(max = 50000)`, `@Column(columnDefinition = "TEXT")` | Markdown 正文 |
| cover_image | String | `@Size(max = 2048)` | 封面图 URL，可为 null |
| tags | `List<String>` | JSON 列，`@Size(max = 10)`，each `@Size(max = 30)` | 标签列表，以 JSON 字符串存储 |
| status | PostStatus (enum) | `@Enumerated(STRING)`, 默认 `PUBLISHED` | 帖子状态 |
| author_id | UUID | `@NotNull`, `@Column(name = "author_id")` | 作者用户 ID |

PostEntity 不存储互动统计字段（comment_count / up_vote_count / bookmark_count），这些字段通过聚合查询实时计算。

#### PostStatus 枚举

| 值 | 含义 | 公开列表/详情可见 |
|---|---|---|
| `DRAFT` | 草稿，仅作者可见 | 否 |
| `PUBLISHED` | 已发布，公开可见 | 是 |
| `ARCHIVED` | 已归档，不参与列表 | 否 |

#### Scenario: Post 继承 BaseEntity 公共字段

- **WHEN** 创建 Post 实体并持久化
- **THEN** 自动填充 id（UUID）、created_at、updated_at
- **AND** deleted 默认为 false

#### Scenario: 逻辑删除

- **WHEN** 调用 `markDeleted()` 后持久化
- **THEN** deleted 字段为 true
- **AND** 常规查询（过滤 deleted=false）不再返回该记录

#### Scenario: tags 以 JSON 格式存储

- **WHEN** Post 实体包含 tags `["travel", "food", "culture"]` 并持久化
- **THEN** 数据库中 `tags` 列存储 JSON 字符串 `["travel","food","culture"]`
- **AND** 读取时还原为 `List<String>`

---

## ADDED Requirements

### Requirement: 列表接口排序参数

`GET /api/posts` 和 `GET /api/users/{user_id}/posts` SHALL 支持 `sort` 查询参数。

| sort 值 | 排序规则 | 分页模式 |
|---|---|---|
| `latest`（默认） | `created_at DESC` | offset 或 cursor |
| `most_upvoted` | `up_vote_count DESC, created_at DESC` | 仅 offset |
| `most_commented` | `comment_count DESC, created_at DESC` | 仅 offset |

#### Scenario: 默认排序

- **WHEN** 客户端未提供 `sort` 参数
- **THEN** 使用 `latest` 排序

#### Scenario: 非法 sort 值

- **WHEN** 客户端提交 `sort=unknown`
- **THEN** 返回 HTTP `400`，`error_code: "validation_error"`

### Requirement: 列表接口 cursor 分页

`GET /api/posts` 和 `GET /api/users/{user_id}/posts` SHALL 支持 cursor-based 分页（仅 `sort=latest` 时有效）。

#### Scenario: cursor 分页请求

- **WHEN** 客户端提交 `GET /api/posts?cursor={ISO8601}&size=20`
- **THEN** 返回 `created_at < cursor` 的帖子，按 `created_at DESC` 排序
- **AND** 最多返回 `size` 条记录
- **AND** 响应包含 `next_cursor`（最后一条的 `created_at`）和 `has_more`

#### Scenario: cursor 首页请求

- **WHEN** 客户端提交 `GET /api/posts?cursor=&size=20`（cursor 为空或不提供）
- **THEN** 等同于 `GET /api/posts?page=1&size=20`

#### Scenario: cursor 与聚合排序冲突

- **WHEN** 客户端同时提供 `cursor` 和 `sort=most_upvoted`（或 `most_commented`）
- **THEN** cursor 参数被忽略，使用 offset 分页

### Requirement: 列表项互动统计字段

帖子列表的每个 item SHALL 包含 `comment_count`、`up_vote_count`、`bookmark_count` 三个聚合字段。

#### Scenario: 互动统计字段存在

- **WHEN** 列表返回帖子数据
- **THEN** 每个 item 包含 `comment_count`（Long）、`up_vote_count`（Long）、`bookmark_count`（Long）

#### Scenario: 无互动数据的帖子

- **GIVEN** 帖子无任何评论、点赞、收藏
- **WHEN** 列表返回该帖子
- **AND** `comment_count: 0`，`up_vote_count: 0`，`bookmark_count: 0`

#### Scenario: comment_count 不含软删除评论

- **GIVEN** 帖子有 5 条评论，其中 2 条已软删除
- **WHEN** 列表返回该帖子
- **THEN** `comment_count: 3`
