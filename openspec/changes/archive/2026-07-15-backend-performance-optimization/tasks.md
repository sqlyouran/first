## 1. Phase 1: 通知列表 N+1 修复

- [x] 1.1 重构 `NotificationService`：新增 `batchResolveActors(List<NotificationEntity>)` 方法，收集所有 actorId → `userRepository.findAllById()` → 返回 `Map<UUID, UserEntity>`
- [x] 1.2 重构 `NotificationService`：新增 `batchResolveTargetTitles(List<NotificationEntity>)` 方法，收集非 null 的 entityId → `postRepository.findAllById()` → 返回 `Map<UUID, String>`
- [x] 1.3 重构 `NotificationController.listNotifications()`：调用批量预取方法，将 `toItemResponse()` 改为从 Map 中查找，不再逐条查询
- [x] 1.4 删除 `resolveActorNickname()`、`resolveActorAvatarUrl()`、`resolveActorUsername()`、`resolveTargetTitle()` 四个逐条查询方法
- [x] 1.5 编写单元测试验证批量预取逻辑（actor Map 正确映射、entityId 为 null 不触发查询）
- [x] 1.6 编写集成测试验证 `GET /api/notifications` 响应格式不变

## 2. Phase 2: 会话列表 N+1 修复

- [x] 2.1 重构 `ConversationService.listConversations()`：收集所有 otherUserId → `userRepository.findAllById()` → 构建 `Map<UUID, UserEntity>`
- [x] 2.2 在 `MessageRepository` 新增 `findLatestMessagesByConversationIds(List<UUID> convIds)` 方法，使用 `IN` + `GROUP BY` 子查询批量获取最新消息
- [x] 2.3 在 `MessageRepository` 新增 `batchCountUnread(List<UUID> convIds, List<UUID> otherUserIds)` 方法，使用 `GROUP BY` 批量聚合未读数
- [x] 2.4 重构 `ConversationService.listConversations()` 调用新的批量方法替换循环内逐条查询
- [x] 2.5 在 `MessageRepository` 新增 `countTotalUnread(UUID userId)` 聚合方法：`SELECT COUNT(m) FROM MessageEntity m JOIN ConversationEntity c ON ... WHERE m.read = false AND m.deleted = false`
- [x] 2.6 重构 `ConversationService.getUnreadCount()`：调用单条聚合 SQL，不再使用 `Integer.MAX_VALUE` 加载全部会话
- [x] 2.7 编写单元测试验证批量查询逻辑
- [x] 2.8 编写集成测试验证会话列表和未读计数响应格式不变

## 3. Phase 3: 帖子排序优化（冗余计数）

- [x] 3.1 `PostEntity` 新增 `cachedUpVoteCount`（int，默认 0）和 `cachedCommentCount`（int，默认 0）字段，`@Column(name = "cached_up_vote_count")` / `@Column(name = "cached_comment_count")`
- [x] 3.2 `PostRepository` 新增 `@Modifying @Query` 原子更新方法：`incrementUpVoteCount(UUID postId, int delta)` 和 `incrementCommentCount(UUID postId, int delta)`
- [x] 3.3 修改 `VoteService`：创建 UP vote 后调用 `incrementUpVoteCount(postId, 1)`；删除 UP vote 后调用 `incrementUpVoteCount(postId, -1)`
- [x] 3.4 修改 `CommentService`：创建评论后调用 `incrementCommentCount(entityId, 1)`（仅当 entityType == POST）；软删除评论后调用 `incrementCommentCount(entityId, -1)`
- [x] 3.5 新增 `DataMigrationRunner`（`ApplicationRunner`）：一次性修复已有数据的冗余计数值，执行后自标记完成避免重复运行
- [x] 3.6 重写 `PostRepository` 排序查询：`findByUpVoteCount` → `ORDER BY p.cachedUpVoteCount DESC`；`findByCommentCount` → `ORDER BY p.cachedCommentCount DESC`（含 cursor 变体）
- [x] 3.7 简化 `PostService.batchFetchStats()`：优先读取冗余字段而非实时聚合查询（`voteRepository.batchCountUpVotes` 等调用可保留作为 fallback 或删除）
- [x] 3.8 编写单元测试验证 VoteService/CommentService 的计数维护逻辑
- [x] 3.9 编写单元测试验证排序查询不再包含 COUNT 子查询
- [x] 3.10 编写集成测试验证 `GET /api/posts?sort=most_upvoted` 和 `most_commented` 排序正确

## 4. Phase 4: 高频只读接口缓存

- [x] 4.1 新建 `GenericCacheService`：封装 `get(key, TypeReference) → T | null`、`put(key, value, Duration)`、`evict(pattern)` 方法，内含 try-catch + warn 日志 + 降级逻辑
- [x] 4.2 为 `PostService.listPosts()` 添加缓存：key = `cache:posts:list:{sort}:{page}:{size}`，TTL = 2 min
- [x] 4.3 为 `PostService.getPost()` 添加缓存：key = `cache:posts:detail:{slug}`，TTL = 10 min
- [x] 4.4 在 `PostService` 的 create/update/delete 方法中调用 `genericCacheService.evict("cache:posts:*")` 清除帖子相关缓存
- [x] 4.5 为 `SpotService.listSpots()` 添加缓存：key = `cache:spots:list:{cityId|all}:{sort}:{page}:{size}`，TTL = 5 min
- [x] 4.6 为 `SpotService.getSpot()` 添加缓存：key = `cache:spots:detail:{slug}`，TTL = 10 min
- [x] 4.7 为 `CityService.listCities()` 添加缓存：key = `cache:cities:list`，TTL = 30 min
- [x] 4.8 编写 `GenericCacheService` 单元测试：验证缓存命中、未命中写入、降级逻辑
- [x] 4.9 编写集成测试验证缓存生效和清除行为

## 5. 验证与收尾

- [x] 5.1 全量运行后端测试 `mvn -f backend/pom.xml test`，确保全绿
- [x] 5.2 检查所有新代码符合项目编码规约（构造器注入、SLF4J 日志、BaseEntity 继承等）
- [x] 5.3 请求 Code Review
