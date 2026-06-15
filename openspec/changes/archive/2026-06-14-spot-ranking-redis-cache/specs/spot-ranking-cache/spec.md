## ADDED Requirements

### Requirement: Redis configuration with JSON serialization
The system SHALL provide a `RedisConfig` Spring configuration class that creates a `RedisTemplate<String, Object>` bean with `StringRedisSerializer` for keys and `GenericJackson2JsonRedisSerializer` for values.

#### Scenario: RedisTemplate bean created with correct serializers
- **WHEN** the Spring context loads
- **THEN** a `RedisTemplate<String, Object>` bean SHALL exist with key serializer `StringRedisSerializer` and value serializer `GenericJackson2JsonRedisSerializer`

### Requirement: RankingCacheService getRanking with cache hit
The system SHALL provide `RankingCacheService.getRanking(type, top, requestId)` that first checks Redis for key `spot:ranking:{type}`. If cached `List<SpotResponse>` exists, the system SHALL return a `SpotRankingResponse` wrapping the first `top` items (or all items if `top` exceeds list size) with the current request's `requestId`, without querying the database.

#### Scenario: Cache hit returns cached data with current requestId
- **WHEN** `getRanking("heat", 10, "req-123")` is called and Redis key `spot:ranking:heat` contains 50 cached items
- **THEN** the system SHALL return `SpotRankingResponse` with `requestId="req-123"`, `type="heat"`, `items` = first 10 cached items, and SHALL NOT call `SpotService.getRanking()`

#### Scenario: Cache hit with top exceeding cached list size
- **WHEN** `getRanking("rating", 100, "req-456")` is called and Redis key `spot:ranking:rating` contains 20 cached items
- **THEN** the system SHALL return all 20 cached items (not throw IndexOutOfBoundsException)

### Requirement: RankingCacheService getRanking with cache miss
When Redis key `spot:ranking:{type}` does not exist, the system SHALL call `SpotService.getRanking(type, 50, requestId)` to fetch the top-50 ranking from the database, store the resulting `List<SpotResponse>` in Redis with key `spot:ranking:{type}` and TTL of 5 minutes, then return a `SpotRankingResponse` with the first `top` items and the current request's `requestId`.

#### Scenario: Cache miss triggers database query and populates cache
- **WHEN** `getRanking("bookmark", 10, "req-789")` is called and Redis key `spot:ranking:bookmark` does not exist
- **THEN** the system SHALL call `SpotService.getRanking("bookmark", 50, "req-789")`, store the 50-item result list in Redis with key `spot:ranking:bookmark` and TTL 5 minutes, and return `SpotRankingResponse` with first 10 items

#### Scenario: Cache miss with top equal to 50
- **WHEN** `getRanking("heat", 50, "req-001")` is called and cache is empty
- **THEN** the system SHALL return all 50 items from the database query without truncation

### Requirement: RankingCacheService evictRanking
The system SHALL provide `RankingCacheService.evictRanking(type)` that deletes the Redis key `spot:ranking:{type}`.

#### Scenario: Evict existing cache key
- **WHEN** `evictRanking("heat")` is called and Redis key `spot:ranking:heat` exists
- **THEN** the key SHALL be deleted from Redis

#### Scenario: Evict non-existing cache key
- **WHEN** `evictRanking("invalid")` is called and Redis key `spot:ranking:invalid` does not exist
- **THEN** the operation SHALL complete without error (no-op)

### Requirement: Ranking cache key format
The cache key SHALL follow the format `spot:ranking:{type}` where `{type}` is one of `rating`, `heat`, `bookmark`. The value stored SHALL be `List<SpotResponse>` serialized as JSON.

#### Scenario: Cache key for heat ranking
- **WHEN** caching heat ranking data
- **THEN** the Redis key SHALL be `spot:ranking:heat`

#### Scenario: Cache key for rating ranking
- **WHEN** caching rating ranking data
- **THEN** the Redis key SHALL be `spot:ranking:rating`

#### Scenario: Cache key for bookmark ranking
- **WHEN** caching bookmark ranking data
- **THEN** the Redis key SHALL be `spot:ranking:bookmark`

### Requirement: Redis connection configuration
The system SHALL configure Redis connection in `application.yml` with host `localhost` and port `6379` under `spring.data.redis`.

#### Scenario: Redis connection to local instance
- **WHEN** the application starts
- **THEN** Spring Data Redis SHALL connect to `localhost:6379`
