## Context

WanderChina 当前 Site Header 包含 Logo + 通知铃铛 + 消息图标 + 用户下拉菜单。本次新增两个旅行工具（天气 / 汇率），需要在不破坏现有 Header 布局的前提下集成。

后端已有完整的 Redis 基础设施（`spring-boot-starter-data-redis` + `RedisConfig` + `StringRedisTemplate`），`RankingCacheService` 提供了成熟的缓存模式可参考。Security 配置已 `permitAll`，公开接口无需额外配置。

前端 shadcn/ui 提供 `Popover` 和 `Sheet` 组件，AI Launcher 已有 Desktop Dialog / Mobile Sheet 的响应式模式可参考。

## Goals / Non-Goals

**Goals:**
- 在 Site Header 工具栏新增天气和汇率快速查询入口
- 后端提供 REST API 代理外部 API，通过 Redis 缓存降低调用频率
- 定义 MCP tool，为后续 AI Trip Planner 集成预留接口
- 前端 Popover / Sheet 面板展示实时数据，支持用户交互（搜索城市 / 切换币种）
- 公开接口，无认证门槛

**Non-Goals:**
- 不做 AI Trip Planner 的实际对话集成（后续 change）
- 不做历史汇率图表 / 多日天气预报
- 不做用户偏好持久化（记住上次查询的城市/币种）
- 不做地理定位自动获取城市
- 不做汇率提醒 / 天气预警推送

## Decisions

### D1: 后端统一 Controller vs 拆分 Controller

**选择**：统一 `ServiceController`（单 controller 两个 endpoint）

**理由**：两个 endpoint 属于同一"旅行服务"概念，逻辑简单（各委托一个 service），不值得拆成两个 controller。后续如果服务增多可再拆。

**替代方案**：`WeatherController` + `ExchangeRateController`——两个 endpoint 就拆，过早抽象。

### D2: MCP Server 实现方式

**选择**：Spring AI MCP Server（`spring-ai-starter-mcp-server-webmvc`）

**理由**：
- Spring AI 1.0+ 原生支持 Spring Boot 3.3.x
- 通过 `@Tool` 注解直接在 Service 类上定义 MCP tool，无需额外抽象层
- REST API 和 MCP tool 共享同一 Service 实现，零重复

**替代方案**：
- 自建 MCP protocol handler——复杂度高，无必要
- 仅 REST API，MCP 后续再加——会导致两次改动 service 层

### D3: 外部 API 调用方式

**选择**：Spring `RestClient`（Spring Framework 6.1+）

**理由**：
- Spring Boot 3.3.x 自带 `RestClient`，无需额外依赖
- 比 `RestTemplate` 更现代的 fluent API
- 比 `WebClient` 轻量（不需要 reactive 依赖）
- 内置超时配置

**替代方案**：
- `RestTemplate`——已标记 legacy
- `WebClient`——需要 `spring-boot-starter-webflux` 依赖，对同步场景过重

### D4: 缓存 key 命名与 TTL

**选择**：
- 天气：`service:weather:{city}` — TTL 30 min
- 汇率：`service:exchange-rate:{base}` — TTL 6h

**理由**：
- key 前缀 `service:` 与现有 `spot:ranking:` 风格一致
- 天气 30 min 平衡实时性和 API 调用量（1000 次/天免费额度）
- 汇率 6h 因为汇率每日更新一次，6h 足够（1500 次/月免费额度）

### D5: 前端 Popover vs Dropdown

**选择**：shadcn/ui `Popover`（桌面）+ `Sheet`（移动端）

**理由**：
- 和现有 AI Launcher 的响应式模式一致（Desktop Dialog / Mobile Sheet）
- Popover 有 shadcn 无障碍支持（focus trap / escape close）
- Sheet 在移动端提供更好的交互体验

**替代方案**：
- DropdownMenu——不支持自定义内容（输入框、表格）
- Dialog——太重，整个屏幕变暗

### D6: 前端组件拆分

**选择**：`WeatherPopover.tsx` + `ExchangeRatePopover.tsx`（独立 client 组件）

**理由**：
- 两个工具独立运作，状态不共享，拆分为独立组件更清晰
- Site Header 只负责挂载图标和触发 Popover，不含业务逻辑
- 各组件内部管理自己的 loading / error / content 状态

### D7: 汇率展示策略

**选择**：API 返回全量 rates，前端只显示 CNY + 用户自选 target

**理由**：
- ExchangeRate API 按 base 返回所有 target 汇率（一次调用）
- 前端重点展示 base→CNY，用户可通过下拉选择其他 target
- 转换器在前端本地计算（amount × rate），无需额外 API 调用

## Risks / Trade-offs

### R1: 外部 API 免费额度限制
**风险**：OpenWeatherMap 1000次/天、ExchangeRate API 1500次/月。高流量时可能触及上限。
**缓解**：Redis 缓存大幅降低实际调用量。天气 30min TTL 意味着一个城市每天最多 48 次调用；汇率 6h TTL 意味着一个 base 每天最多 4 次。若仍有压力可延长 TTL 或增加 fallback 静态数据。

### R2: Spring AI 版本兼容性
**风险**：Spring AI MCP Server 可能与 Spring Boot 3.3.5 存在兼容性问题。
**缓解**：在 design 阶段验证 Spring AI BOM 兼容版本。Spring AI 1.0.x 明确支持 Spring Boot 3.3.x。

### R3: API Key 泄露
**风险**：外部 API Key 被意外提交到仓库。
**缓解**：API Key 仅通过环境变量注入（`WEATHER_API_KEY` / `EXCHANGE_RATE_API_KEY`），`application.properties` 使用 `${WEATHER_API_KEY:}` 占位符，`.env` 文件已在 `.gitignore`。

### R4: Header 拥挤
**风险**：5 个图标按钮在移动端可能过于拥挤。
**缓解**：移动端可考虑将天气/汇率合并到一个"旅行工具"入口（本期先保持独立，观察实际效果）。
