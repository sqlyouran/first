## 1. 后端 Repository 批量聚合查询

- [x] 1.1 VoteRepository 新增 `batchCountUpVotes(List<UUID> postIds)` — `@Query` GROUP BY postId，返回 `List<Object[]>`
- [x] 1.2 BookmarkRepository 新增 `batchCountBookmarks(List<UUID> postIds)` — `@Query` GROUP BY postId，返回 `List<Object[]>`
- [x] 1.3 CommentRepository 新增 `batchCountActiveComments(List<UUID> postIds)` — `@Query` WHERE deleted=false GROUP BY postId，返回 `List<Object[]>`
- [x] 1.4 验证：@DataJpaTest 测试三个批量聚合方法（含空列表、部分有数据、全空场景）

## 2. 后端 Repository 分页查询增强

- [x] 2.1 PostRepository 新增 `findByCreatedAtCursor(PostStatus status, Instant cursor, Pageable pageable)` — keyset 查询，返回 `List<PostEntity>`
- [x] 2.2 PostRepository 新增 `findByUpVoteCount(Pageable, PostStatus)` — JPQL 子查询 ORDER BY COUNT(votes) DESC
- [x] 2.3 PostRepository 新增 `findByCommentCount(Pageable, PostStatus)` — JPQL 子查询 ORDER BY COUNT(comments WHERE deleted=false) DESC
- [x] 2.4 PostRepository 新增 `findByAuthorIdAndCreatedAtCursor` / `findByAuthorIdAndUpVoteCount` / `findByAuthorIdAndCommentCount` — 用户帖子列表对应变体
- [x] 2.5 验证：@DataJpaTest 测试 keyset 查询 + 聚合排序查询

## 3. 后端 DTO 增强

- [x] 3.1 PostResponse 新增 `comment_count` / `up_vote_count` / `bookmark_count` 三个 `@JsonProperty` 字段（long），更新构造器
- [x] 3.2 PostListResponse 新增 `next_cursor`（String, nullable, `@JsonProperty("next_cursor")`）和 `has_more`（boolean, `@JsonProperty("has_more")`），更新构造器
- [x] 3.3 PostListResponse `page` 字段类型改为 `Integer`（nullable），cursor 模式下为 null
- [x] 3.4 新增 `PostSortBy` 枚举：LATEST / MOST_UPVOTED / MOST_COMMENTED，含 fromString 工厂方法（非法值抛异常）

## 4. 后端 Service 重构

- [x] 4.1 PostService 新增 `batchFetchStats(List<UUID> postIds)` 私有方法 — 调用三个 Repository 批量方法，返回 `Map<UUID, long[]>`
- [x] 4.2 重构 `PostService.listPosts` 方法签名：`listPosts(int page, int size, String cursor, PostSortBy sort, String requestId)` — 支持 cursor + offset + 排序
- [x] 4.3 实现 cursor 分支：sort=LATEST 且 cursor!=null 时走 keyset 查询，fetch size+1 条判断 hasMore
- [x] 4.4 实现 offset 分支：根据 sort 选择对应 Repository 方法，Page<T> 模式
- [x] 4.5 所有分支最后调用 `batchFetchStats` 填充互动统计字段
- [x] 4.6 重构 `PostService.listUserPosts` 同步增强（与 listPosts 保持一致的 cursor + sort 支持）
- [x] 4.7 `PostService.toPostResponse` 更新：接收 stats 参数，填充三个 count 字段
- [x] 4.8 `PostService.getPost` 更新：也填充三个 count 字段（单帖调用现有单条查询或直接传 0）

## 5. 后端 Controller 更新

- [x] 5.1 PostController `listPosts` 新增参数：`@RequestParam(required = false) String cursor` + `@RequestParam(defaultValue = "latest") String sort`
- [x] 5.2 PostController `listPosts` 内部逻辑：sort 解析为 PostSortBy，cursor 与 page 互斥判断
- [x] 5.3 PostController `listUserPosts` 同步新增 cursor + sort 参数
- [x] 5.4 非法 sort 值返回 400 + error_code "validation_error"

## 6. 后端测试（TDD — RED → GREEN → REFACTOR）

- [x] 6.1 `PostControllerTest`：listPosts 默认分页增加断言 — `comment_count` / `up_vote_count` / `bookmark_count` 字段存在
- [x] 6.2 `PostControllerTest`：listPosts 互动统计正确性 — 创建帖子 + 评论 + 投票 + 收藏 → 验证 count 值
- [x] 6.3 `PostControllerTest`：listPosts sort=most_upvoted — 多帖子不同点赞数 → 验证排序
- [x] 6.4 `PostControllerTest`：listPosts sort=most_commented — 多帖子不同评论数 → 验证排序（含软删除评论不计入）
- [x] 6.5 `PostControllerTest`：listPosts cursor 分页 — 验证 next_cursor + has_more + items 正确
- [x] 6.6 `PostControllerTest`：listPosts sort=invalid → 400 validation_error
- [x] 6.7 `PostControllerTest`：listPosts cursor + sort=most_upvoted → cursor 被忽略，走 offset
- [x] 6.8 `PostControllerTest`：listUserPosts 同步增强测试（至少验证 sort + 互动统计字段）
- [x] 6.9 `PostServiceTest`（或集成到 Controller 测试）：cursor keyset 查询边界 — 空 cursor / 最后一条 / 无更多数据

## 7. 后端验收

- [x] 7.1 `mvn -f backend/pom.xml test` 全绿（新旧测试全部通过）

## 8. 前端类型与 API 更新

- [x] 8.1 `lib/api/posts.ts` PostListItem 类型新增 `comment_count` / `up_vote_count` / `bookmark_count`（number）
- [x] 8.2 `lib/api/posts.ts` PostListData 类型新增 `next_cursor`（string | null）/ `has_more`（boolean）
- [x] 8.3 `lib/api/posts.ts` 定义 `PostSortType = "latest" | "most_upvoted" | "most_commented"` 类型
- [x] 8.4 重构 `fetchPosts` 签名：接受 `{ page?, size?, sort?, cursor? }` 对象参数，构造对应 URL
- [x] 8.5 重构 `fetchUserPosts` 签名：同上
- [x] 8.6 更新 `posts.test.ts` 测试用例适配新签名和新字段

## 9. 前端 PostCard 互动统计

- [x] 9.1 PostCard.tsx 新增互动统计行：ThumbsUp + up_vote_count / MessageCircle + comment_count / Bookmark + bookmark_count
- [x] 9.2 统计行样式：`flex items-center gap-4 text-sm text-slate-500`，放在标签和日期之间
- [x] 9.3 更新 PostCard 测试（如有）验证互动统计渲染

## 10. 前端排序 UI

- [x] 10.1 posts/page.tsx 新增排序选项卡 UI：三个按钮（最新 / 最热 / 最多评论），默认选中「最新」
- [x] 10.2 排序按钮样式：选中态 `bg-blue-50 text-blue-700`，未选中 `text-slate-600 hover:bg-slate-100`
- [x] 10.3 排序切换时重置 page=1，更新 sort state，重新请求
- [x] 10.4 更新 `fetchPosts` 调用传入 sort 参数

## 11. 前端测试

- [x] 11.1 `cd frontend && npm test` 全绿
- [x] 11.2 手动验证：帖子列表页排序切换 + PostCard 互动统计展示
