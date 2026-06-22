## Why

WanderChina 面向境外旅行者，汇率和天气是行前决策的两项刚需信息。当前平台缺少这类实用工具，用户需要跳转到第三方站点查询。在 Site Header 工具栏集成快速查询入口，可以让用户在浏览内容时随手获取关键行前信息，同时为后续 AI Trip Planner 提供可调用的 MCP tools。

## What Changes

- 新增后端 API 接口 `/api/services/weather` 和 `/api/services/exchange-rate`，代理外部 API（OpenWeatherMap / ExchangeRate API），通过 Redis 缓存降低调用频率
- 新增 MCP Server tool 定义（`get_weather` / `get_exchange_rate`），使同一服务可被 AI Agent 调用
- Site Header 右侧工具栏新增两个图标按钮（天气 🌤️ / 汇率 💱），点击弹出 Popover 面板展示实时数据
- 天气面板：默认 Beijing，支持用户手动搜索切换城市，展示当前天气 + 温度 + 天气描述
- 汇率面板：用户自选币种对，预设常见货币列表（USD / EUR / GBP / JPY / KRW 等），展示对 CNY 汇率
- 两个接口均为公开接口，无需登录
- 移动端 Popover fallback 到 Sheet 组件

## Capabilities

### New Capabilities

- `weather-service`: 天气查询服务——后端 API 代理 OpenWeatherMap、Redis 缓存（30 min TTL）、MCP tool 定义、前端 Header Popover 面板
- `exchange-rate-service`: 汇率查询服务——后端 API 代理 ExchangeRate API、Redis 缓存（6 h TTL）、MCP tool 定义、前端 Header Popover 面板

### Modified Capabilities

_无需修改现有 capability 的需求级行为。_

## Impact

- **后端新增**：`controller/ServiceController.java`、`service/WeatherService.java`、`service/ExchangeRateService.java`、对应 DTO（Request / Response）
- **后端依赖**：需新增 Spring AI MCP Server 相关依赖（`spring-ai-mcp-server-spring-boot-starter`）
- **后端配置**：`application.properties` 新增 `weather.api.key`、`exchange-rate.api.key` 环境变量引用
- **前端新增**：`app/_components/WeatherPopover.tsx`、`app/_components/ExchangeRatePopover.tsx`、`lib/api/services.ts`
- **前端修改**：`app/_components/SiteHeader.tsx` 新增两个工具按钮
- **外部依赖**：OpenWeatherMap API（免费额度 1000 次/天）、ExchangeRate API（免费额度 1500 次/月）
- **运行时**：Redis 已有配置，新增两个缓存 key 前缀
