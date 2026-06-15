# spots-posts-association Spec

> 景点与帖子关联关系。
> 定义 `SpotPostEntity` 关联实体、`SpotPostService` 查询服务、关联 API 端点和种子数据。

## Requirements

### Requirement: SpotPostEntity 关联实体定义

`SpotPostEntity` SHALL 继承 `BaseEntity`（id / createdAt / updatedAt / deleted），映射到 `spots_posts` 表，字段如下：

| 字段 | 类型 | 约束 | DB 列名 |
|------|------|------|---------|
| `spotId` | `UUID` | NOT NULL | `spot_id` |
| `postId` | `UUID` | NOT NULL | `post_id` |

表级约束：`(spot_id, post_id)` 联合唯一（`UNIQUE`）。

#### Scenario: 创建合法 SpotPostEntity 后持久化

- **GIVEN** `SpotPostEntity` 实例 `spotId=<valid-spot-uuid>`, `postId=<valid-post-uuid>`
- **WHEN** 通过 Repository 持久化
- **THEN** `id` 为 UUID，`createdAt` 和 `updatedAt` 不为 null，`deleted` 为 false
- **AND** 数据库 `spots_posts` 表存在对应行

#### Scenario: 重复关联触发联合唯一约束

- **GIVEN** `spots_posts` 表已存在 `(spotId=A, postId=B)` 的记录
- **WHEN** 持久化另一条 `(spotId=A, postId=B)` 的 `SpotPostEntity`
- **THEN** 抛出 `DataIntegrityViolationException`

#### Scenario: spotId 不可为空

- **WHEN** 持久化 `spotId=null` 的 `SpotPostEntity`
- **THEN** 抛出 `ConstraintViolationException`

#### Scenario: postId 不可为空

- **WHEN** 持久化 `postId=null` 的 `SpotPostEntity`
- **THEN** 抛出 `ConstraintViolationException`

---

### Requirement: SpotPostRepository 查询方法

`SpotPostRepository` SHALL 继承 `JpaRepository<SpotPostEntity, UUID>`，提供：

- `findBySpotIdAndDeletedFalse(UUID spotId, Pageable pageable)` — 分页查询某景点的所有有效关联记录
- `findByPostIdAndDeletedFalse(UUID postId)` — 查询某帖子的所有有效关联记录
- `existsBySpotIdAndPostIdAndDeletedFalse(UUID spotId, UUID postId)` — 检查关联是否存在

#### Scenario: 按景点 ID 查询关联记录

- **GIVEN** `spots_posts` 表有 5 条 `spotId=A` 且 `deleted=false` 的记录
- **WHEN** 调用 `findBySpotIdAndDeletedFalse(A, PageRequest.of(0, 20))`
- **THEN** 返回 5 条 `SpotPostEntity`

#### Scenario: 逻辑删除的关联不出现在查询结果中

- **GIVEN** `spots_posts` 表有 3 条 `spotId=A` 且 `deleted=false`，2 条 `deleted=true`
- **WHEN** 调用 `findBySpotIdAndDeletedFalse(A, PageRequest.of(0, 20))`
- **THEN** 返回 3 条 `SpotPostEntity`

#### Scenario: 按帖子 ID 查询关联记录

- **GIVEN** `spots_posts` 表有 2 条 `postId=X` 且 `deleted=false` 的记录
- **WHEN** 调用 `findByPostIdAndDeletedFalse(X)`
- **THEN** 返回 2 条 `SpotPostEntity`

---

### Requirement: SpotPostService 关联查询服务

`SpotPostService` SHALL 提供以下方法：

- `getPostsBySpotId(UUID spotId, int page, int size, String requestId)` — 返回景点关联的帖子列表（分页）
- `getSpotsByPostId(UUID postId, String requestId)` — 返回帖子关联的景点列表

**getPostsBySpotId 逻辑**：
1. 通过 `SpotPostRepository` 获取关联的 postId 列表（分页）
2. 通过 `PostRepository` 批量查询这些 postId 对应的 PUBLISHED 且未删除的 PostEntity
3. 组装为 `SpotPostsResponse`（分页）

**getSpotsByPostId 逻辑**：
1. 通过 `SpotPostRepository` 获取关联的 spotId 列表
2. 通过 `SpotRepository` 批量查询这些 spotId 对应的 PUBLISHED 且未删除的 SpotEntity
3. 组装为 `PostSpotsResponse`（列表，无分页）

#### Scenario: 获取景点关联的帖子列表

- **GIVEN** spot A 关联了 3 个 PUBLISHED 帖子
- **WHEN** 调用 `getPostsBySpotId(A, 1, 20, requestId)`
- **THEN** 返回 `SpotPostsResponse`，`total=3`，`items` 包含 3 条 PostResponse

#### Scenario: 关联的帖子为 DRAFT 时不返回

- **GIVEN** spot A 关联了 2 个 PUBLISHED 帖子 + 1 个 DRAFT 帖子
- **WHEN** 调用 `getPostsBySpotId(A, 1, 20, requestId)`
- **THEN** 返回 `total=2`，`items` 仅包含 PUBLISHED 帖子

#### Scenario: 景点不存在时抛出异常

- **GIVEN** 不存在 id=X 的景点
- **WHEN** 调用 `getPostsBySpotId(X, 1, 20, requestId)`
- **THEN** 抛出 `SpotException(HttpStatus.NOT_FOUND, "not_found", "Spot not found")`

#### Scenario: 获取帖子关联的景点列表

- **GIVEN** post X 关联了 2 个 PUBLISHED 景点
- **WHEN** 调用 `getSpotsByPostId(X, requestId)`
- **THEN** 返回 `PostSpotsResponse`，`items` 包含 2 条 SpotResponse

#### Scenario: 帖子不存在时抛出异常

- **GIVEN** 不存在 id=Y 的帖子
- **WHEN** 调用 `getSpotsByPostId(Y, requestId)`
- **THEN** 抛出 `PostException(HttpStatus.NOT_FOUND, "not_found", "Post not found")`

---

### Requirement: SpotPostsResponse 与 PostSpotsResponse DTO

`SpotPostsResponse` SHALL 继承 `BaseResponse`（自带 `request_id`），字段：`items`（`List<PostResponse>`）、`total`（`long`）、`page`（`int`）、`size`（`int`）。

`PostSpotsResponse` SHALL 继承 `BaseResponse`（自带 `request_id`），字段：`items`（`List<SpotResponse>`）。

所有字段 `private final`，使用 `@JsonProperty` 显式声明 snake_case 序列化。

#### Scenario: SpotPostsResponse 包含分页元数据

- **WHEN** `SpotPostsResponse` 序列化为 JSON
- **THEN** 响应体包含 `request_id`、`items`、`total`、`page`、`size` 字段

#### Scenario: PostSpotsResponse 包含景点列表

- **WHEN** `PostSpotsResponse` 序列化为 JSON
- **THEN** 响应体包含 `request_id`、`items` 字段

---

### Requirement: 关联种子数据

`data.sql` SHALL 追加 `INSERT IGNORE INTO spots_posts` 种子数据，建立景点与帖子之间的关联关系。同时确保 `data.sql` 中有帖子种子数据可供关联。

#### Scenario: 种子数据包含有效的关联记录

- **WHEN** 应用启动
- **THEN** `spots_posts` 表包含至少 5 条关联记录，覆盖多个景点与帖子

#### Scenario: 种子数据幂等

- **WHEN** 应用重启
- **THEN** INSERT IGNORE 防止重复插入
