## Context

WanderChina 后端当前有以下性能问题模式：

1. **N+1 查询**：通知列表（80 SQL/页）、会话列表（60 SQL/页）、未读计数（全量加载）
2. **聚合子查询风暴**：帖子排序查询每行执行 COUNT 子查询，cursor 模式同一个子查询重复 3~4 次
3. **高频只读接口无缓存**：帖子/景点列表、城市列表、详情接口每次冷查 DB

现有基础设施：Redis 已配置（`RedisConfig` + `StringRedisTemplate`），`RankingCacheService` 提供了成熟的缓存读写模式。`open-in-view: false` 已关闭，无 JPA 关联映射（全部 UUID 外键），无 LazyInitializationException 风险。

## Goals / Non-Goals

**Goals:**
- 通知列表从 ~80 SQL/页 降至 ≤5 SQL
- 会话列表从 ~60 SQL/页 降至 ≤5 SQL
- 未读计数从 O(N) 查询降至 1 条聚合 SQL
- 帖子排序查询消除所有 COUNT 子查询
- 5 个高频只读接口具备 Redis 缓存 + 降级兜底

**Non-Goals:**
- 不做读写分离或 CQRS
- 不做异步消息队列维护计数
- 不引入全文搜索引擎（Elasticsearch）替代 LIKE 查询
- 不优化 AI Chat / RAG / 语义搜索相关接口
- 不做数据库索引优化（后续 change）
- 不修改任何 API 响应契约

## Decisions

### D1: 通知 N+1 修复——Service 层批量预取 vs EntityGraph

**选择**：Service 层批量预取（收集 ID → `findAllById` → Map 查找）

**理由**：
- 当前架构没有 JPA 关联映射（全部 UUID 外键），`@EntityGraph` 无法使用
- `PostService.buildItemsWithStats()` 已有成熟的批量预取模式可复用
- 改动集中在 Controller/Service 层，不涉及 Repository 接口变更

**替代方案**：引入 JPA `@ManyToOne` 关联 + `JOIN FETCH`——改动太大，需要重构实体模型。

### D2: 会话 N+1 修复——批量预取模式

**选择**：同 D1，Service 层收集所有 otherUserId → `findAllById` 批量查 User；新增 Repository 方法批量查最新消息和未读数。

**最新消息批量查询**：在 `MessageRepository` 新增 `@Query` 方法，通过 `IN` 子句 + 子查询取每个会话的最新一条消息：

```sql
SELECT m FROM MessageEntity m WHERE m.id IN
  (SELECT MAX(m2.id) FROM MessageEntity m2 WHERE m2.conversationId IN :convIds AND m2.deleted = false GROUP BY m2.conversationId)
```

**未读数批量查询**：新增 `@Query` 方法：

```sql
SELECT m.conversationId, COUNT(m) FROM MessageEntity m
WHERE m.conversationId IN :convIds AND m.senderId IN :otherUserIds AND m.read = false AND m.deleted = false
GROUP BY m.conversationId
```

**未读总数**：改为单条聚合 SQL，不再加载全部会话。

### D3: 帖子排序优化——冗余计数 vs 物化视图 vs 定时聚合

**选择**：PostEntity 冗余字段 `cachedUpVoteCount` / `cachedCommentCount`，投票/评论时同步 +1/-1

**理由**：
- 实现简单，改动集中在 VoteService 和 CommentService
- `ddl-auto: update` 自动加列，无需手动 migration
- 排序查询直接 `ORDER BY cachedUpVoteCount DESC`，可利用数据库索引
- 与现有 `SpotEntity.viewCount` / `bookmarkCount` 冗余字段模式一致

**替代方案**：
- 物化视图——H2/MySQL 不支持，过重
- 定时聚合任务——存在数据延迟窗口，对排序准确性有要求时不适用
- 保持现状 + 加索引——子查询数量随数据线性增长，治标不治本

**计数维护时机**：
- VoteService 创建/删除 UP vote 时 → `postRepository.incrementUpVoteCount(postId, +1/-1)`
- CommentService 创建/软删除评论时 → `postRepository.incrementCommentCount(postId, +1/-1)`
- 使用 `@Modifying @Query` 做原子更新，避免并发竞争

### D4: 缓存层架构——通用 CacheService vs 各 Service 内嵌缓存

**选择**：新建 `GenericCacheService` 工具类，封装 Redis 读写 + 降级 + TTL 逻辑，各 Service 调用

**理由**：
- `RankingCacheService` 已展示了内嵌缓存模式，但 4+ 个 Service 各自内嵌会重复大量 try-catch + 序列化代码
- 抽取通用缓存工具，符合 DRY 原则（出现第 3 次相同模式时提炼）
- 降级逻辑集中管理：Redis 异常时 catch + warn 日志 + fallback 查 DB

**key 命名规范**：
- `cache:posts:list:{sort}:{page}:{size}` — 帖子列表
- `cache:posts:detail:{slug}` — 帖子详情
- `cache:spots:list:{cityId|all}:{sort}:{page}:{size}` — 景点列表
- `cache:spots:detail:{slug}` — 景点详情
- `cache:cities:list` — 城市列表

**TTL 策略**：

| 接口 | TTL | 失效触发 |
|------|-----|----------|
| 帖子列表 | 2 min | 帖子 CRUD |
| 帖子详情 | 10 min | 帖子更新 |
| 景点列表 | 5 min | — (TTL 自然过期) |
| 景点详情 | 10 min | — (TTL 自然过期) |
| 城市列表 | 30 min | — (TTL 自然过期) |

**缓存失效**：帖子 CRUD 时使用 `redisTemplate.delete(keysMatching("cache:posts:*"))` 批量清除。景点和城市依赖 TTL 自然过期（数据变动频率低）。

### D5: 缓存序列化方式

**选择**：使用 `ObjectMapper` 序列化为 JSON 字符串存储，与 `RankingCacheService` 保持一致。

**理由**：JSON 可读性好，便于调试和排查缓存内容；`ObjectMapper` 已在项目中配置。

### D6: 实施顺序

按风险从低到高、依赖从前到后：

1. **Phase 1**: 通知 N+1 修复（纯 Service 层重构，无 schema 变更）
2. **Phase 2**: 会话 N+1 修复（同上）
3. **Phase 3**: 帖子排序优化（schema 变更 + 计数维护逻辑）
4. **Phase 4**: 缓存层（依赖 Phase 3 完成后缓存的数据是准确的）

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| 冗余计数与真实计数不一致 | 后续可加定时对账任务重新聚合修正；当前阶段投票/评论操作频率低，并发竞争概率小 |
| 缓存导致用户看到过期数据 | TTL 设置较短（2~30 min）；帖子更新时主动清缓存 |
| Redis 不可用 | 所有缓存操作 try-catch + 降级查 DB，日志 warn |
| `cache:posts:*` 批量清除性能 | 当前缓存 key 数量有限（几十种 sort/page 组合），`keys()` + `delete()` 可接受；数据量大后改 hash tag 或 SCAN |
| 冗余字段增加写入延迟 | 仅 +1 原子操作，延迟可忽略（< 1ms） |

## Migration Plan

1. Phase 1-2 无 schema 变更，可直接部署
2. Phase 3 通过 `ddl-auto: update` 自动加列（`cached_up_vote_count` / `cached_comment_count`，默认 0）
3. Phase 3 部署后需运行一次性数据修复脚本：`UPDATE posts SET cached_up_vote_count = (SELECT COUNT(*) FROM votes WHERE votes.post_id = posts.id AND votes.vote_type = 'UP')`——可在 `ApplicationRunner` 中实现
4. Phase 4 纯新增缓存层，无 schema 变更
5. 回滚策略：每个 Phase 独立，可单独回滚

## Open Questions

- 帖子列表缓存的 `cache:posts:*` 批量清除，在 key 数量增长后是否需要改为 SCAN 模式？（暂按 `keys()` 实现，后续优化）
- 是否需要在 `batchFetchStats` 中优先读冗余字段而非实时聚合？（Phase 3 完成后自然切换）
