## MODIFIED Requirements

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
