## ADDED Requirements

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
