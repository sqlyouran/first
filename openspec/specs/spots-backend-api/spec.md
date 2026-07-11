## ADDED Requirements

### Requirement: SpotEntity data model
The system SHALL define a `SpotEntity` extending `BaseEntity` with fields: name (VARCHAR 200, NOT NULL), nameZh (VARCHAR 200), slug (VARCHAR 220, NOT NULL, UNIQUE), description (TEXT), descriptionZh (TEXT), coverImage (VARCHAR 2048), gallery (JSON List\<String\>), tags (JSON List\<String\>), cityId (UUID, NOT NULL), cityName (VARCHAR 100), status (ENUM DRAFT/PUBLISHED via SpotStatus), rating (DECIMAL 2,1, default 0.0), viewCount (INT, default 0), bookmarkCount (INT, default 0), **ticketPrice (VARCHAR 200, nullable), openingHours (VARCHAR 500, nullable), address (VARCHAR 500, nullable)**.

#### Scenario: SpotEntity creation with required fields
- **WHEN** a SpotEntity is persisted with name="Forbidden City", slug="forbidden-city", cityId=<valid-uuid>, status=PUBLISHED
- **THEN** the entity SHALL be saved with auto-generated id, createdAt, updatedAt, deleted=false

#### Scenario: SpotEntity name validation
- **WHEN** a SpotEntity is persisted with a blank name
- **THEN** a constraint violation SHALL be thrown

#### Scenario: SpotEntity slug uniqueness
- **WHEN** two SpotEntity instances are persisted with the same slug
- **THEN** a unique constraint violation SHALL be thrown on the second insert

#### Scenario: SpotEntity 实用字段可为 NULL
- **WHEN** a SpotEntity is persisted with ticketPrice=null, openingHours=null, address=null
- **THEN** the entity SHALL be saved successfully with all three practical info fields as null

#### Scenario: SpotEntity 实用字段填充
- **WHEN** a SpotEntity is persisted with ticketPrice="旺季60元/淡季40元", openingHours="08:30-17:00（4月-10月）", address="北京市东城区景山前街4号"
- **THEN** the entity SHALL be saved with these values correctly stored and retrievable

### Requirement: List spots with pagination and filtering
The system SHALL provide `GET /api/spots` with query parameters: page (int, default 1), size (int, default 20, max 100), city_id (UUID, optional), sort (string, default "latest", options: latest|rating|viewCount|bookmarkCount). The response SHALL include items[], total, page, size in snake_case JSON.

#### Scenario: List spots with default parameters
- **WHEN** GET /api/spots is called with no parameters
- **THEN** the system SHALL return page=1, size=20, sorted by created_at DESC, only PUBLISHED spots

#### Scenario: List spots filtered by city
- **WHEN** GET /api/spots?city_id=<uuid> is called with a valid city UUID
- **THEN** the system SHALL return only PUBLISHED spots where city_id matches

#### Scenario: List spots sorted by rating
- **WHEN** GET /api/spots?sort=rating is called
- **THEN** the system SHALL return PUBLISHED spots sorted by rating DESC

#### Scenario: List spots with page size exceeding maximum
- **WHEN** GET /api/spots?size=200 is called
- **THEN** the system SHALL return HTTP 400 with error_code "validation_error"

### Requirement: Get spot by ID
The system SHALL provide `GET /api/spots/{id}` that returns the full spot details including all fields (name, nameZh, slug, description, descriptionZh, coverImage, gallery, tags, cityId, cityName, status, rating, viewCount, bookmarkCount, **ticketPrice, openingHours, address**, createdAt, updatedAt).

#### Scenario: Get existing spot
- **WHEN** GET /api/spots/{id} is called with a valid published spot UUID
- **THEN** the system SHALL return HTTP 200 with the complete spot details in snake_case JSON, including `ticket_price`, `opening_hours`, `address` fields

#### Scenario: Get non-existent spot
- **WHEN** GET /api/spots/{id} is called with a UUID that does not exist or is deleted
- **THEN** the system SHALL return HTTP 404 with error_code "not_found"

#### Scenario: Get draft spot
- **WHEN** GET /api/spots/{id} is called with a UUID of a DRAFT status spot
- **THEN** the system SHALL return HTTP 404 with error_code "not_found"

### Requirement: Spot ranking API
The system SHALL provide `GET /api/spots/ranking` with query parameters: type (required, enum: rating|heat|bookmark), top (optional, default 10, max 50). The response SHALL include type and items[] with spot summary fields. The controller SHALL delegate to `RankingCacheService` instead of calling `SpotService` directly, so that repeated requests within the TTL window are served from Redis cache.

#### Scenario: Get top rated spots
- **WHEN** GET /api/spots/ranking?type=rating&top=10 is called
- **THEN** the system SHALL return top 10 PUBLISHED spots sorted by rating DESC

#### Scenario: Get hottest spots
- **WHEN** GET /api/spots/ranking?type=heat is called
- **THEN** the system SHALL return top 10 PUBLISHED spots sorted by view_count DESC

#### Scenario: Get most bookmarked spots
- **WHEN** GET /api/spots/ranking?type=bookmark is called
- **THEN** the system SHALL return top 10 PUBLISHED spots sorted by bookmark_count DESC

#### Scenario: Get ranking with invalid type
- **WHEN** GET /api/spots/ranking?type=invalid is called
- **THEN** the system SHALL return HTTP 400 with error_code "validation_error"

#### Scenario: Get ranking with top exceeding maximum
- **WHEN** GET /api/spots/ranking?type=rating&top=100 is called
- **THEN** the system SHALL return HTTP 400 with error_code "validation_error"

#### Scenario: Consecutive ranking requests served from cache
- **WHEN** GET /api/spots/ranking?type=heat is called twice within 5 minutes
- **THEN** the second request SHALL be served from Redis cache without querying MySQL, and SHALL return a response with a different requestId from the first

### Requirement: SpotException handling
The system SHALL define `SpotException` extending RuntimeException with HttpStatus and errorCode. The `GlobalExceptionHandler` SHALL map SpotException to ErrorResponse with request_id, error_code, message.

#### Scenario: SpotException mapped to error response
- **WHEN** a SpotException with status=404, errorCode="not_found", message="Spot not found" is thrown
- **THEN** the GlobalExceptionHandler SHALL return HTTP 404 with JSON body containing request_id, error_code="not_found", message="Spot not found"

### Requirement: Spot seed data
The system SHALL include seed data in data.sql with at least 15 spots across 5+ cities, using INSERT IGNORE for idempotency. Seed data SHALL include meaningful rating/viewCount/bookmarkCount values for ranking verification. **Beijing SHALL have at least 20 spots with real-world data (name, ticketPrice, openingHours, address, description) sourced from Ctrip. The existing 3 Beijing spots (UUIDs b1111111, b2222222, b3333333) SHALL be updated in-place with enriched data.**

#### Scenario: Seed data loaded on startup
- **WHEN** the application starts
- **THEN** data.sql SHALL insert spot records with unique UUIDs, covering multiple cities with varied rating/viewCount/bookmarkCount values, and Beijing spots SHALL include ticket_price, opening_hours, and address fields

#### Scenario: Seed data idempotency
- **WHEN** the application restarts
- **THEN** INSERT IGNORE SHALL prevent duplicate records from being inserted

#### Scenario: 北京景点数据合并更新
- **GIVEN** 现有 3 个北京景点使用固定 UUID（b1111111/b2222222/b3333333）
- **WHEN** data.sql 执行
- **THEN** 这 3 个景点的 description/descriptionZh/ticketPrice/openingHours/address 等字段 SHALL 被真实采集数据覆盖，UUID 保持不变

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
