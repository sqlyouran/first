## Why

WanderChina 后端存在多处 N+1 查询、聚合排序子查询风暴、以及高频只读接口缺少缓存的问题。当前数据量尚小，但随着帖子和景点增长，这些问题会在数据量过万后导致首页、列表、通知等核心接口显著变慢。现在是数据量还小、改动成本最低的最佳修复窗口。

## What Changes

- 修复通知列表 N+1 查询：`NotificationController.toItemResponse()` 对每条通知执行 4 次独立查询（3 次查同一 User + 1 次查 Post），改为批量预取
- 修复会话列表 N+1 查询：`ConversationService.listConversations()` 对每条会话执行 3 次查询（User + 最新消息 + 未读数），改为批量查询
- 修复未读消息计数全量加载：`getUnreadCount()` 用 `Integer.MAX_VALUE` 加载全部会话再逐条计数，改为单条聚合 SQL
- 消除帖子排序 COUNT 子查询：`findByUpVoteCount` / `findByCommentCount` 每行执行子查询 COUNT，在 PostEntity 上冗余计数字段避免运行时聚合
- 为高频只读接口添加 Redis 缓存层：帖子列表、景点列表、城市列表、帖子/景点详情等接口，复用 RankingCacheService 已有的缓存模式

## Capabilities

### New Capabilities

- `notification-batch-resolve`: 通知列表 N+1 修复——批量预取 actor 用户信息和 target 帖子标题
- `conversation-batch-resolve`: 会话列表 N+1 修复——批量预取对方用户、最新消息、未读数；未读计数改为聚合 SQL
- `post-sort-denormalization`: 帖子排序优化——PostEntity 新增 `cachedUpVoteCount` / `cachedCommentCount` 冗余字段，投票/评论时维护，消除 ORDER BY 子查询
- `api-read-cache`: 高频只读接口缓存——为帖子列表、景点列表、城市列表、帖子详情、景点详情添加 Redis 缓存

### Modified Capabilities

_无需修改现有 capability 的需求级行为。本次变更仅涉及性能优化，API 契约不变。_

## Impact

- **后端修改**：`NotificationController`、`NotificationService`、`ConversationService`、`PostEntity`、`PostRepository`、`PostService`、`VoteService`、`CommentService`、`SpotService`、`CityService`
- **后端新增**：`PostCacheService`（或扩展现有缓存模式）、批量查询辅助方法
- **数据库**：`posts` 表新增 `cached_up_vote_count` 和 `cached_comment_count` 两列（通过 `ddl-auto: update` 自动建表）
- **Redis**：新增多个缓存 key 前缀（`cache:posts:*`、`cache:spots:*`、`cache:cities`）
- **API 契约**：无变化，响应格式不变
- **前端**：无变化
