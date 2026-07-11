## MODIFIED Requirements

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
