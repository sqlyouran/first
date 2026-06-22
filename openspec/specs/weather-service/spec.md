# weather-service Spec

> 站点头栏天气查询服务能力契约。
> 本 spec 定义后端天气查询 API、Redis 缓存、MCP 工具定义以及前端 Site Header 中天气 Popover/Sheet 交互的最小能力集合。

## Requirements

### Requirement: Weather query API endpoint
The system SHALL expose `GET /api/services/weather?city={city}` to return current weather data for a given city. The response SHALL include temperature (Celsius), weather description, weather icon code, humidity, and wind speed. This endpoint SHALL be public (no authentication required).

#### Scenario: Successful weather query for a known city
- **WHEN** client sends `GET /api/services/weather?city=Beijing`
- **THEN** system returns 200 with `{ request_id, city, temperature, description, icon, humidity, wind_speed, updated_at }`

#### Scenario: Weather query for an unknown city
- **WHEN** client sends `GET /api/services/weather?city=NonExistentCity123`
- **THEN** system returns 404 with `error_code: "city_not_found"` and `message: "City not found"`

#### Scenario: External API is unavailable
- **WHEN** OpenWeatherMap API returns a 5xx error or times out (>5s)
- **THEN** system returns 502 with `error_code: "weather_service_unavailable"`

#### Scenario: Missing city parameter
- **WHEN** client sends `GET /api/services/weather` without `city` parameter
- **THEN** system returns 422 with `error_code: "validation_error"`

### Requirement: Weather data caching
The system SHALL cache weather responses in Redis with a TTL of 30 minutes. Cache key format SHALL be `service:weather:{city}`. On cache hit, the system SHALL return cached data without calling the external API.

#### Scenario: Cache hit within TTL
- **WHEN** the same city is queried within 30 minutes of a previous successful query
- **THEN** system returns cached data and does NOT call OpenWeatherMap API

#### Scenario: Cache miss or expired
- **WHEN** a city is queried and no valid cache entry exists
- **THEN** system calls OpenWeatherMap API, caches the result with 30 min TTL, and returns the data

### Requirement: Weather MCP tool definition
The system SHALL define an MCP tool named `get_weather` that accepts a `city` parameter (string, required). The tool SHALL invoke the same internal weather service used by the REST API.

#### Scenario: MCP tool invocation
- **WHEN** an AI agent calls the `get_weather` tool with `city: "Shanghai"`
- **THEN** system returns the same weather data structure as the REST API

### Requirement: Weather Popover in Site Header
The Site Header SHALL include a weather icon button (Cloud/Sun icon). Clicking it SHALL open a Popover (desktop) or Sheet (mobile) panel displaying:
- Current city name with a search input to switch cities
- Current temperature in Celsius
- Weather description text
- Humidity and wind speed
- "Updated X minutes ago" timestamp

#### Scenario: User opens weather popover on desktop
- **WHEN** user clicks the weather icon in Site Header on a desktop viewport (≥768px)
- **THEN** a Popover panel appears showing Beijing weather by default

#### Scenario: User searches for a different city
- **WHEN** user types a city name in the search input and submits
- **THEN** the panel updates to show weather data for the searched city

#### Scenario: Weather popover on mobile
- **WHEN** user taps the weather icon on a mobile viewport (<768px)
- **THEN** a Sheet slides up from the bottom showing the same weather panel

#### Scenario: Loading state
- **WHEN** weather data is being fetched
- **THEN** the panel shows skeleton placeholders for all data fields

#### Scenario: Error state in popover
- **WHEN** the weather API returns an error
- **THEN** the panel shows an error message with a "Retry" button
