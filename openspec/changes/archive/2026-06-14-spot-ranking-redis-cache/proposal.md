## Why

景点排行榜接口（`GET /api/spots/ranking`）每次请求都直接查询 MySQL，数据变化频率低（景点评分/热度/收藏数不会秒级变化），但首页多个区域（HotSpots、FeatureNav 等）会并发调用该接口，造成不必要的数据库压力。加一层 Redis 缓存可将 5 分钟内的重复请求直接命中内存，显著降低 DB 负载并提升响应速度。

## What Changes

- 引入 `spring-boot-starter-data-redis` 依赖
- 在 `application.yml` 添加 Redis 连接配置（`localhost:6379`）
- 新建 `RedisConfig` 配置类，设置 `GenericJackson2JsonRedisSerializer` 为默认序列化器
- 新建 `RankingCacheService`：
  - `getRanking(type, top, requestId)` — 先查 Redis，命中则直接返回；未命中则调 `SpotService.getRanking()` 查库，结果（top=50 的完整列表）写入 Redis，TTL 5 分钟
  - `evictRanking(type)` — 删除对应 key，供将来数据写入时调用
- 改造 `SpotController.getRanking()` — 调用 `RankingCacheService` 而非直接调 `SpotService`
- 缓存 key 格式：`spot:ranking:{type}`，value 为 `List<SpotResponse>` JSON
- `requestId` 不缓存，每次用当前请求的 requestId 重新包装 `SpotRankingResponse`

## Capabilities

### New Capabilities

- `spot-ranking-cache`: 景点排行榜 Redis 缓存层，包含缓存读写、TTL 过期、手动清除、JSON 序列化配置

### Modified Capabilities

- `spots-backend-api`: 排行榜接口的调用链从 `Controller → SpotService` 改为 `Controller → RankingCacheService → SpotService`，外部行为不变

## Impact

- **依赖**：pom.xml 新增 `spring-boot-starter-data-redis`（运行时需 Redis 实例）
- **配置**：`application.yml` 新增 `spring.data.redis` 节
- **代码**：`controller/SpotController.java`、新建 `config/RedisConfig.java`、新建 `service/RankingCacheService.java`
- **测试**：`SpotControllerTest` 需适配新依赖；新增 `RankingCacheServiceTest`（mock RedisTemplate + SpotService）
- **运行时**：本地开发需启动 Redis（已有），CI/测试用 mock 不依赖真实 Redis
