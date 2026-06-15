## MODIFIED Requirements

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
