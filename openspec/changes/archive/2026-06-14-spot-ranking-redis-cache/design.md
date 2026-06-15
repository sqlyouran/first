## Context

当前 `SpotController.getRanking()` → `SpotService.getRanking()` 直查 MySQL。排行榜数据（rating / heat / bookmark）变化频率低，首页多个区域（HotSpots、FeatureNav）并发调用该接口，每次全量查库浪费资源。

已有约束：
- 后端 Spring Boot 3.3.5 + Java 17
- 开发环境 MySQL，本地已有 Redis 实例
- 测试用 Mockito，不依赖真实 Redis

## Goals / Non-Goals

**Goals:**
- 排行榜接口在 5 分钟内相同 type 的请求直接走 Redis，不查 MySQL
- 缓存自动过期（TTL 5min），保证数据不会永久陈旧
- `requestId` 每次请求独立，不从缓存中读取
- 提供 `evictRanking()` 方法供未来写入接口调用

**Non-Goals:**
- 不为 `listSpots` / `getSpot` 等其他接口加缓存（YAGNI）
- 不接入缓存清除的实际触发点（当前无写入接口，等后续 change 接入）
- 不做分布式锁 / 缓存击穿防护（当前流量不需要）
- 不做 Redis 集群 / 哨兵配置（单机开发环境）

## Decisions

### D1: 缓存粒度 — 固定缓存 top=50，小 top 从结果截取

**选择**：缓存 key 为 `spot:ranking:{type}`，value 固定存 top=50 的完整列表，请求 top < 50 时 `subList(0, top)` 截取。

**备选**：
- A) key 包含 top（`spot:ranking:{type}:{top}`）→ 缓存粒度细，但前端 top=10 和 top=20 分别缓存，命中率低
- B) **选中**：固定 50 条 → 命中率高，数据量小（50 条 SpotResponse 约几 KB），可忽略浪费

**理由**：排行榜接口 top 最大 50，前端大概率用默认 10，固定缓存 50 条一次写入多次命中，性价比最高。

### D2: 缓存层位置 — 新建 RankingCacheService，Controller 调用它

**选择**：新建 `RankingCacheService`，`SpotController` 调它，它再调 `SpotService`。

**备选**：
- A) 直接在 `SpotService.getRanking()` 内部加缓存 → 破坏单一职责，SpotService 变难测
- B) **选中**：独立 CacheService → 职责清晰，SpotService 保持不变，测试隔离
- C) 用 Spring Cache 注解（`@Cacheable`）→ 抽象层太厚，不方便控制 requestId 分离

**理由**：独立 Service 保持 SpotService 纯净，测试时可以 mock RedisTemplate + SpotService 独立验证缓存逻辑。

### D3: 序列化 — GenericJackson2JsonRedisSerializer

**选择**：Redis value 用 JSON 序列化（`GenericJackson2JsonRedisSerializer`）。

**备选**：
- A) JDK 序列化 → 不可读，类变更时反序列化可能报错
- B) **选中**：JSON → 可读、调试友好、SpotResponse 字段都是基础类型无兼容风险

**理由**：SpotResponse 是 immutable class，字段全是 String / int / 基础类型，JSON 序列化无兼容问题。

### D4: requestId 不缓存

**选择**：Redis 只存 `List<SpotResponse>`，返回时用当前请求的 requestId 重新包装 `SpotRankingResponse`。

**理由**：requestId 是请求级追踪标识，缓存后所有请求拿到同一个 id，破坏日志追踪能力。

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| Redis 宕机时排行榜接口不可用 | 后续可加 fallback 降级直查 DB（本次不做，YAGNI） |
| 缓存数据与 DB 不一致（最多 5 分钟） | 排行榜本身容忍延迟，5 分钟 TTL 可接受 |
| 引入 Redis 依赖增加运维复杂度 | 本地已有 Redis，生产 Docker Compose 统一编排 |
| 测试 mock RedisTemplate 覆盖不全 | RankingCacheService 逻辑简单（get/set/delete），mock 可覆盖 |
