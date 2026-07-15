## MODIFIED Requirements

### Requirement: Query stale spots for data refresh

The system SHALL provide `GET /api/spots/stale` that returns spots whose `dataRefreshedAt` is older than the configured stale threshold (default 7 days), sorted by priority: **critical** (>30 days since refresh) first, then **normal** (7-30 days). Spots with `dataRefreshedAt = null` are treated as infinitely stale (highest priority).

该接口 SHALL 需要有效 JWT Bearer Token 认证。

#### Scenario: List stale spots with default threshold

- **GIVEN** the stale threshold is 7 days, critical threshold is 30 days
- **GIVEN** 3 spots: A (refreshed 35 days ago), B (refreshed 10 days ago), C (refreshed 2 days ago)
- **GIVEN** 客户端持有有效 JWT Token
- **WHEN** GET /api/spots/stale is called
- **THEN** the system SHALL return spots A and B (not C), sorted: A first (critical), B second (normal)

#### Scenario: Unauthenticated access rejected

- **WHEN** 客户端不带 Authorization header 请求 `GET /api/spots/stale`
- **THEN** HTTP 401

---

### Requirement: Manual trigger enrichment collection

The system SHALL provide `POST /api/spots/enrichment/trigger` that manually triggers the spot data collection pipeline (same logic as the `@Scheduled` task). The collection SHALL run asynchronously in the background.

该接口 SHALL 需要有效 JWT Bearer Token 认证。

#### Scenario: Unauthenticated trigger rejected

- **WHEN** 客户端不带 Authorization header 请求 `POST /api/spots/enrichment/trigger`
- **THEN** HTTP 401

---

### Requirement: Get latest enrichment report

The system SHALL provide `GET /api/spots/enrichment/report/latest` that returns the most recent enrichment report.

该接口 SHALL 需要有效 JWT Bearer Token 认证。

#### Scenario: Unauthenticated report access rejected

- **WHEN** 客户端不带 Authorization header 请求 `GET /api/spots/enrichment/report/latest`
- **THEN** HTTP 401
