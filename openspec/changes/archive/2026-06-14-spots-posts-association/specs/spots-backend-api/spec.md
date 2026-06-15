## ADDED Requirements

### Requirement: GET /api/spots/{id}/posts 景点关联帖子列表

`SpotController` SHALL 提供 `GET /api/spots/{id}/posts`，参数：`page`（默认 1）、`size`（默认 20，最大 100），委托 `SpotPostService` 返回关联帖子列表 `SpotPostsResponse`。

仅返回 `status=PUBLISHED` 且 `deleted=false` 的帖子。

#### Scenario: 查询存在景点的关联帖子

- **GIVEN** `spots` 表存在 id=X 的未删除景点，关联了 3 个 PUBLISHED 帖子
- **WHEN** 请求 `GET /api/spots/X/posts`
- **THEN** HTTP 200，响应包含 `request_id`、`items`（3 条 PostResponse）、`total=3`、`page=1`、`size=20`

#### Scenario: 景点无关联帖子

- **GIVEN** `spots` 表存在 id=X 的未删除景点，无关联帖子
- **WHEN** 请求 `GET /api/spots/X/posts`
- **THEN** HTTP 200，响应 `items=[]`，`total=0`

#### Scenario: 景点不存在

- **WHEN** 请求 `GET /api/spots/<不存在的UUID>/posts`
- **THEN** HTTP 404，响应 `error_code="not_found"`

#### Scenario: 分页参数超出范围

- **WHEN** 请求 `GET /api/spots/{id}/posts?size=200`
- **THEN** HTTP 400，响应 `error_code="validation_error"`
