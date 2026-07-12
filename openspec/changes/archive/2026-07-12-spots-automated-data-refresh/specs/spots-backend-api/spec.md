## MODIFIED Requirements

### Requirement: SpotEntity data model

The system SHALL define a `SpotEntity` extending `BaseEntity` with fields: name (VARCHAR 200, NOT NULL), nameZh (VARCHAR 200), slug (VARCHAR 220, NOT NULL, UNIQUE), description (TEXT), descriptionZh (TEXT), coverImage (VARCHAR 2048), gallery (JSON List\<String\>), tags (JSON List\<String\>), cityId (UUID, NOT NULL), cityName (VARCHAR 100), status (ENUM DRAFT/PUBLISHED via SpotStatus), rating (DECIMAL 2,1, default 0.0), viewCount (INT, default 0), bookmarkCount (INT, default 0), ticketPrice (VARCHAR 200, nullable), openingHours (VARCHAR 500, nullable), address (VARCHAR 500, nullable), **dataRefreshedAt (TIMESTAMP, nullable)** — records the last time the spot's enrichment data was refreshed via the automated collection pipeline; independent from `updatedAt` which fires on any field change.

#### Scenario: SpotEntity dataRefreshedAt 初始为 NULL

- **WHEN** a SpotEntity is persisted without setting `dataRefreshedAt`
- **THEN** the entity SHALL be saved with `dataRefreshedAt = null`

#### Scenario: SpotEntity dataRefreshedAt 可被设置

- **WHEN** a SpotEntity is persisted with `dataRefreshedAt = 2026-07-11T02:00:00Z`
- **THEN** the entity SHALL be saved with this value correctly stored and retrievable

#### Scenario: dataRefreshedAt 不随 viewCount 变化而更新

- **GIVEN** a SpotEntity with `dataRefreshedAt = 2026-07-11T02:00:00Z`
- **WHEN** `viewCount` is incremented and the entity is saved
- **THEN** `updatedAt` SHALL change but `dataRefreshedAt` SHALL remain `2026-07-11T02:00:00Z`

---

## ADDED Requirements

### Requirement: Query stale spots for data refresh

The system SHALL provide `GET /api/spots/stale` that returns spots whose `dataRefreshedAt` is older than the configured stale threshold (default 7 days), sorted by priority: **critical** (>30 days since refresh) first, then **normal** (7-30 days). Spots with `dataRefreshedAt = null` are treated as infinitely stale (highest priority).

#### Scenario: List stale spots with default threshold

- **GIVEN** the stale threshold is 7 days, critical threshold is 30 days
- **GIVEN** 3 spots: A (refreshed 35 days ago), B (refreshed 10 days ago), C (refreshed 2 days ago)
- **WHEN** GET /api/spots/stale is called
- **THEN** the system SHALL return spots A and B (not C), sorted: A first (critical), B second (normal)

#### Scenario: List stale spots with null dataRefreshedAt

- **GIVEN** a spot D has `dataRefreshedAt = null`
- **WHEN** GET /api/spots/stale is called
- **THEN** spot D SHALL be included in the result with priority "critical" and `daysSinceRefresh` reported as a very large number (e.g., 999)

#### Scenario: No stale spots

- **GIVEN** all spots were refreshed within the last 7 days
- **WHEN** GET /api/spots/stale is called
- **THEN** the system SHALL return HTTP 200 with `items = []`, `total = 0`

#### Scenario: Only PUBLISHED non-deleted spots returned

- **GIVEN** a stale spot with `status = DRAFT` or `deleted = true`
- **WHEN** GET /api/spots/stale is called
- **THEN** that spot SHALL NOT be included in the result

---

### Requirement: Manual trigger enrichment collection

The system SHALL provide `POST /api/spots/enrichment/trigger` that manually triggers the spot data collection pipeline (same logic as the `@Scheduled` task). The collection SHALL run asynchronously in the background.

#### Scenario: Trigger collection when stale spots exist

- **GIVEN** there are 5 stale spots in the database
- **WHEN** POST /api/spots/enrichment/trigger is called
- **THEN** HTTP 202 (accepted)
- **AND** the collection SHALL start asynchronously
- **AND** response SHALL contain `request_id` and `status: "collection_started"`

#### Scenario: Trigger collection when already running

- **GIVEN** a collection is already in progress
- **WHEN** POST /api/spots/enrichment/trigger is called again
- **THEN** HTTP 409 with `error_code = "collection_in_progress"`

---

### Requirement: Get latest enrichment report

The system SHALL provide `GET /api/spots/enrichment/report/latest` that returns the most recent enrichment report.

#### Scenario: Get latest report when reports exist

- **GIVEN** 3 enrichment reports exist with different startedAt timestamps
- **WHEN** GET /api/spots/enrichment/report/latest is called
- **THEN** HTTP 200
- **AND** the response SHALL contain the report with the most recent `startedAt`

#### Scenario: Get latest report when no reports exist

- **GIVEN** no enrichment reports exist
- **WHEN** GET /api/spots/enrichment/report/latest is called
- **THEN** HTTP 404 with `error_code = "not_found"`

---

### Requirement: Scheduled daily enrichment collection

The system SHALL run the spot data collection pipeline automatically every day at 02:00 (cron: `0 0 2 * * *`). The cron expression SHALL be configurable via `app.enrichment.cron`.

#### Scenario: Scheduled collection triggers at 02:00

- **GIVEN** the application is running
- **WHEN** the system clock reaches 02:00
- **THEN** the `SpotDataCollectorService.collectStaleSpots()` method SHALL be invoked
- **AND** the collection pipeline SHALL run the same logic as manual trigger

#### Scenario: Scheduled collection skipped when no stale spots

- **GIVEN** all spots were refreshed within the stale threshold
- **WHEN** the scheduled collection triggers
- **THEN** an enrichment report SHALL still be saved with `totalAttempted = 0, totalSuccess = 0, totalFailed = 0`

---

### Requirement: SpotEnrichmentReport entity

The system SHALL define a `SpotEnrichmentReport` entity extending `BaseEntity` with fields: runId (VARCHAR 36, NOT NULL, UNIQUE), startedAt (TIMESTAMP, NOT NULL), completedAt (TIMESTAMP, NOT NULL), totalAttempted (INT), totalSuccess (INT), totalFailed (INT), details (JSON TEXT — array of per-spot enrichment results).

#### Scenario: SpotEnrichmentReport persistence

- **WHEN** a SpotEnrichmentReport is persisted with valid fields
- **THEN** the entity SHALL be saved with auto-generated id, createdAt, updatedAt, deleted=false
- **AND** runId SHALL be unique

---

### Requirement: MCP Client connection to Browser MCP Server

The system SHALL configure an MCP Client via `spring-ai-starter-mcp-client` that connects to a Browser MCP Server using stdio transport. The MCP Client SHALL be able to invoke Browser MCP tools: `navigate_page`, `take_snapshot`, `evaluate_script`.

#### Scenario: MCP Client auto-starts Browser MCP Server

- **GIVEN** `spring.ai.mcp.client.stdio.connections.browser-use.command` is configured
- **WHEN** the application starts
- **THEN** the MCP Client SHALL launch the configured command as a child process
- **AND** communicate with it via stdin/stdout using the MCP protocol

#### Scenario: MCP Client tools available

- **GIVEN** Browser MCP Server is running and connected
- **WHEN** `SpotDataCollectorService` needs browser tools
- **THEN** it SHALL be able to call `navigate_page`, `take_snapshot`, `evaluate_script` through the MCP Client
