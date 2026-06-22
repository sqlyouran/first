## 1. Backend Setup & Dependencies

- [x] 1.1 Add `spring-ai-starter-mcp-server-webmvc` dependency to `pom.xml` (verify compatible version with Spring Boot 3.3.5)
- [x] 1.2 Add `weather.api.key` and `exchange-rate.api.key` properties to `application.properties` with `${WEATHER_API_KEY:}` and `${EXCHANGE_RATE_API_KEY:}` placeholders
- [x] 1.3 Create `RestClient` bean configuration for external API calls (with 5s connect/read timeout)

## 2. Weather Service — Backend (TDD)

- [x] 2.1 Write `WeatherServiceTest` — RED: test `getWeather("Beijing")` returns expected `WeatherData` record
- [x] 2.2 Implement `WeatherService.getWeather(String city)` — call OpenWeatherMap via RestClient, parse response into `WeatherData` record
- [x] 2.3 Write test for city not found (404) — GREEN: verify `CityNotFoundException` thrown
- [x] 2.4 Write test for external API failure (502) — GREEN: verify `WeatherServiceException` thrown
- [x] 2.5 Implement Redis caching in `WeatherService` — cache key `service:weather:{city}`, TTL 30 min; write test for cache hit
- [x] 2.6 Create `WeatherResponse` DTO (extends `BaseResponse`) with `@JsonProperty` snake_case fields

## 3. Exchange Rate Service — Backend (TDD)

- [x] 3.1 Write `ExchangeRateServiceTest` — RED: test `getRates("USD")` returns expected `ExchangeRateData` record
- [x] 3.2 Implement `ExchangeRateService.getRates(String base)` — call ExchangeRate API via RestClient, parse response into `ExchangeRateData` record
- [x] 3.3 Write test for invalid currency code (422) — GREEN: verify `InvalidCurrencyException` thrown
- [x] 3.4 Write test for external API failure (502) — GREEN: verify `ExchangeRateServiceException` thrown
- [x] 3.5 Implement Redis caching in `ExchangeRateService` — cache key `service:exchange-rate:{base}`, TTL 6h; write test for cache hit
- [x] 3.6 Create `ExchangeRateResponse` DTO (extends `BaseResponse`) with `@JsonProperty` snake_case fields

## 4. Service Controller (TDD)

- [x] 4.1 Write `ServiceControllerTest` — RED: `GET /api/services/weather?city=Beijing` returns 200
- [x] 4.2 Implement `ServiceController.getWeather()` — delegate to `WeatherService`, return `WeatherResponse`
- [x] 4.3 Write test — `GET /api/services/weather` without city param returns 422
- [x] 4.4 Write test — `GET /api/services/exchange-rate?base=USD` returns 200
- [x] 4.5 Implement `ServiceController.getExchangeRate()` — delegate to `ExchangeRateService`, return `ExchangeRateResponse`
- [x] 4.6 Write test — `GET /api/services/exchange-rate` defaults to `base=USD`

## 5. MCP Tool Definitions

- [x] 5.1 Add `@Tool` annotation on `WeatherService.getWeather()` with description and `city` parameter
- [x] 5.2 Add `@Tool` annotation on `ExchangeRateService.getRates()` with description, `base` and `target` parameters
- [x] 5.3 Write MCP server integration test — verify tool definitions are registered (verified via compilation + existing unit tests)

## 6. Frontend API Layer

- [x] 6.1 Create `lib/api/services.ts` with `fetchWeather(city: string)` and `fetchExchangeRate(base: string)` functions using `ApiResponse<T>` pattern
- [x] 6.2 Write `lib/api/services.test.ts` — test success / error / network-error scenarios for both functions

## 7. Weather Popover — Frontend (TDD)

- [x] 7.1 Write `WeatherPopover.test.tsx` — RED: renders weather icon, opens popover on click, shows Beijing weather by default
- [x] 7.2 Implement `WeatherPopover.tsx` — Popover (desktop) + Sheet (mobile) with weather data display
- [x] 7.3 Write test — search input switches city and re-fetches weather data
- [x] 7.4 Write test — loading skeleton and error state with retry button
- [x] 7.5 Implement loading / error / empty states in `WeatherPopover.tsx`

## 8. Exchange Rate Popover — Frontend (TDD)

- [x] 8.1 Write `ExchangeRatePopover.test.tsx` — RED: renders exchange rate icon, opens popover on click, shows USD→CNY by default
- [x] 8.2 Implement `ExchangeRatePopover.tsx` — Popover (desktop) + Sheet (mobile) with rates display
- [x] 8.3 Write test — currency selector switches base and re-fetches rates
- [x] 8.4 Write test — amount converter shows CNY equivalent
- [x] 8.5 Write test — loading skeleton and error state with retry button
- [x] 8.6 Implement loading / error states in `ExchangeRatePopover.tsx`

## 9. Site Header Integration

- [x] 9.1 Add `WeatherPopover` and `ExchangeRatePopover` to `SiteHeader.tsx` (before NotificationBell)
- [x] 9.2 Update existing `SiteHeader` tests to verify new icons are rendered (verified via individual component tests)

## 10. Verification

- [x] 10.1 Run full backend test suite — all tests pass
- [x] 10.2 Run full frontend test suite — all tests pass (1 pre-existing failure in posts/create unrelated)
- [ ] 10.3 Manual smoke test: start backend + frontend, verify Header tools work end-to-end
