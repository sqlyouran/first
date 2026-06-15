## 1. 依赖与配置

- [x] 1.1 pom.xml 添加 `spring-boot-starter-data-redis` 依赖
- [x] 1.2 application.yml 添加 `spring.data.redis.host: localhost` + `spring.data.redis.port: 6379`
- [x] 1.3 新建 `config/RedisConfig.java`：`RedisTemplate<String, Object>` bean，key 用 `StringRedisSerializer`，value 用 `GenericJackson2JsonRedisSerializer`
- [x] 1.4 验证应用启动（Redis 连接正常，bean 注入成功）

## 2. RankingCacheService（TDD）

- [x] 2.1 新建 `service/RankingCacheService.java` 骨架（构造器注入 `RedisTemplate` + `SpotService`）
- [x] 2.2 写失败测试：`getRanking` cache hit 时返回缓存数据、不调 SpotService、使用当前 requestId
- [x] 2.3 实现 `getRanking` cache hit 逻辑，测试通过
- [x] 2.4 写失败测试：`getRanking` cache miss 时调 `SpotService.getRanking(type, 50, requestId)`、写入 Redis（TTL 5min）、截取 top 条返回
- [x] 2.5 实现 cache miss 逻辑，测试通过
- [x] 2.6 写失败测试：`getRanking` top 超过缓存列表大小时返回全部（不抛 IndexOutOfBoundsException）
- [x] 2.7 修复边界条件，测试通过
- [x] 2.8 写失败测试：`evictRanking` 删除 Redis key
- [x] 2.9 实现 `evictRanking`，测试通过
- [x] 2.10 写失败测试：`evictRanking` key 不存在时不抛异常
- [x] 2.11 验证 no-op 行为，测试通过

## 3. Controller 改造（TDD）

- [x] 3.1 修改 `SpotController` 构造器，注入 `RankingCacheService`
- [x] 3.2 修改 `getRanking()` 方法，委托给 `RankingCacheService`
- [x] 3.3 更新 `SpotControllerTest`：mock `RankingCacheService` 替代原来的 `SpotService`，验证排行榜请求走缓存层

## 4. 验证

- [x] 4.1 全部后端测试通过（`mvn test`）
- [x] 4.2 手动验证：启动应用 + Redis，连续两次调用 `GET /api/spots/ranking?type=heat`，第二次 response_time 明显下降
