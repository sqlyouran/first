# exchange-rate-service Spec

> 站点头栏汇率查询服务能力契约。
> 本 spec 定义后端汇率查询 API、Redis 缓存、MCP 工具定义以及前端 Site Header 中汇率 Popover/Sheet 交互的最小能力集合。

## Requirements

### Requirement: Exchange rate query API endpoint
The system SHALL expose `GET /api/services/exchange-rate?base={base}` to return exchange rates from a base currency to CNY and other common currencies. The response SHALL include the base currency, a map of target currency rates, and the last-updated timestamp. This endpoint SHALL be public (no authentication required).

#### Scenario: Successful rate query for USD base
- **WHEN** client sends `GET /api/services/exchange-rate?base=USD`
- **THEN** system returns 200 with `{ request_id, base, rates: { CNY: 7.24, EUR: 0.92, ... }, updated_at }`

#### Scenario: Rate query with default base
- **WHEN** client sends `GET /api/services/exchange-rate` without `base` parameter
- **THEN** system defaults to `base=USD` and returns rates accordingly

#### Scenario: Invalid base currency code
- **WHEN** client sends `GET /api/services/exchange-rate?base=INVALID`
- **THEN** system returns 422 with `error_code: "invalid_currency"` and `message: "Invalid currency code"`

#### Scenario: External API is unavailable
- **WHEN** ExchangeRate API returns a 5xx error or times out (>5s)
- **THEN** system returns 502 with `error_code: "exchange_rate_service_unavailable"`

### Requirement: Exchange rate data caching
The system SHALL cache exchange rate responses in Redis with a TTL of 6 hours. Cache key format SHALL be `service:exchange-rate:{base}`. On cache hit, the system SHALL return cached data without calling the external API.

#### Scenario: Cache hit within TTL
- **WHEN** the same base currency is queried within 6 hours of a previous successful query
- **THEN** system returns cached data and does NOT call ExchangeRate API

#### Scenario: Cache miss or expired
- **WHEN** a base currency is queried and no valid cache entry exists
- **THEN** system calls ExchangeRate API, caches the result with 6h TTL, and returns the data

### Requirement: Exchange rate MCP tool definition
The system SHALL define an MCP tool named `get_exchange_rate` that accepts `base` (string, required) and `target` (string, optional, defaults to CNY) parameters. The tool SHALL invoke the same internal exchange rate service used by the REST API.

#### Scenario: MCP tool invocation with default target
- **WHEN** an AI agent calls the `get_exchange_rate` tool with `base: "EUR"`
- **THEN** system returns exchange rates for EUR against CNY

#### Scenario: MCP tool invocation with specific target
- **WHEN** an AI agent calls the `get_exchange_rate` tool with `base: "USD"` and `target: "JPY"`
- **THEN** system returns the USD to JPY exchange rate

### Requirement: Exchange rate Popover in Site Header
The Site Header SHALL include an exchange rate icon button (Banknote/ArrowLeftRight icon). Clicking it SHALL open a Popover (desktop) or Sheet (mobile) panel displaying:
- A currency selector dropdown for the base currency (presets: USD, EUR, GBP, JPY, KRW, AUD, CAD, CHF)
- Exchange rates against CNY (and optionally other major currencies)
- A simple converter input: user enters an amount in base currency, sees the CNY equivalent
- "Updated X hours ago" timestamp

#### Scenario: User opens exchange rate popover on desktop
- **WHEN** user clicks the exchange rate icon in Site Header on a desktop viewport (≥768px)
- **THEN** a Popover panel appears showing USD→CNY rates by default

#### Scenario: User switches base currency
- **WHEN** user selects "EUR" from the currency selector dropdown
- **THEN** the panel updates to show EUR-based exchange rates

#### Scenario: User converts an amount
- **WHEN** user types "100" in the amount input field
- **THEN** the panel displays the CNY equivalent using the current rate

#### Scenario: Exchange rate popover on mobile
- **WHEN** user taps the exchange rate icon on a mobile viewport (<768px)
- **THEN** a Sheet slides up from the bottom showing the same exchange rate panel

#### Scenario: Loading state
- **WHEN** exchange rate data is being fetched
- **THEN** the panel shows skeleton placeholders for all data fields

#### Scenario: Error state in popover
- **WHEN** the exchange rate API returns an error
- **THEN** the panel shows an error message with a "Retry" button
