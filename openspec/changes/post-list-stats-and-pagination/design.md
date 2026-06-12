## Context

后端帖子列表接口 `GET /api/posts` 和 `GET /api/users/{userId}/posts` 当前使用 Spring Data JPA `Page<T>` 模式，固定 `created_at DESC` 排序，返回 offset 分页结构。互动数据（投票 / 收藏 / 评论）分散在三个独立 Repository 中，仅提供单帖查询方法（`countByPostIdAndVoteType` 等），无批量聚合能力。

前端 `PostCard` 仅展示标题 / 封面 / 标签 / 日期，无互动统计。

现有约束：MySQL 8（ddl-auto: update）、BaseEntity 软删除、api-conventions 分页格式、不引入新依赖。

## Goals / Non-Goals

**Goals:**

- 列表项追加 `comment_count` / `up_vote_count` / `bookmark_count` 三个聚合字段
- 批量聚合查询避免 N+1（一次查询获取当前页所有帖子的统计）
- `created_at` 排序支持 cursor-based 分页（keyset pagination）
- 支持三种排序：`latest`（默认）/ `most_upvoted` / `most_commented`
- 聚合排序仅 offset 分页（cursor 与聚合排序不兼容时忽略 cursor）
- `listUserPosts` 同步增强，与全局列表保持一致
- 前端 PostCard 展示全部三项互动统计
- 前端帖子列表页增加排序切换

**Non-Goals:**

- 不在 PostEntity 存储冗余计数（数据一致性风险 + 当前数据量不需要）
- 不做互动统计缓存（后续按需引入）
- 不做无限滚动 UI（cursor 分页为 API 层能力预留，前端仍用传统翻页）
- 不修改帖子详情页的互动数据获取方式（已有独立接口）

## Decisions

### D1: 批量聚合查询策略

**选择**：每个 Repository 新增 `@Query` 批量方法，接收 `List<UUID> postIds`，返回 `List<Object[]>`（`[postId, count]`），Service 层转为 `Map<UUID, Long>`。

```java
// VoteRepository
@Query("SELECT v.postId, COUNT(v) FROM VoteEntity v WHERE v.postId IN :postIds AND v.voteType = 'UP' GROUP BY v.postId")
List<Object[]> batchCountUpVotes(@Param("postIds") List<UUID> postIds);

// BookmarkRepository
@Query("SELECT b.postId, COUNT(b) FROM BookmarkEntity b WHERE b.postId IN :postIds GROUP BY b.postId")
List<Object[]> batchCountBookmarks(@Param("postIds") List<UUID> postIds);

// CommentRepository
@Query("SELECT c.postId, COUNT(c) FROM CommentEntity c WHERE c.postId IN :postIds AND c.deleted = false GROUP BY c.postId")
List<Object[]> batchCountActiveComments(@Param("postIds") List<UUID> postIds);
```

**替代方案**：逐条查询（N+1）→ 20 条帖子 × 3 次查询 = 60 次 DB round-trip，不可接受。

**理由**：3 次批量查询 + 内存 join，性能可控。`postIds` 最多 100 个（size 上限），IN 子句无压力。

### D2: Cursor 分页实现（Keyset Pagination）

**选择**：仅 `sort=latest` 时支持 cursor。PostRepository 新增方法：

```java
@Query("SELECT p FROM PostEntity p WHERE p.status = :status AND p.deleted = false AND p.createdAt < :cursor ORDER BY p.createdAt DESC")
List<PostEntity> findByCreatedAtCursor(@Param("status") PostStatus status, @Param("cursor") Instant cursor, Pageable pageable);
```

查 `size + 1` 条，多出的那条 → `hasMore = true`，返回前 size 条，`nextCursor` = 最后一条的 `createdAt`。

**替代方案**：所有排序都支持 cursor → 聚合字段无法做 keyset（不存在于实体上），需要 window function，复杂度陡增。

### D3: 聚合排序实现（子查询）

**选择**：使用 JPQL 子查询（而非 GROUP BY），H2 兼容性更好：

```java
// most_upvoted
@Query("SELECT p FROM PostEntity p WHERE p.status = :status AND p.deleted = false ORDER BY (SELECT COUNT(v) FROM VoteEntity v WHERE v.postId = p.id AND v.voteType = 'UP') DESC, p.createdAt DESC")
Page<PostEntity> findByUpVoteCount(Pageable pageable, @Param("status") PostStatus status);

// most_commented
@Query("SELECT p FROM PostEntity p WHERE p.status = :status AND p.deleted = false ORDER BY (SELECT COUNT(c) FROM CommentEntity c WHERE c.postId = p.id AND c.deleted = false) DESC, p.createdAt DESC")
Page<PostEntity> findByCommentCount(Pageable pageable, @Param("status") PostStatus status);
```

**替代方案**：GROUP BY + JOIN → JPQL 中 `GROUP BY p.id` 需要所有非聚合字段都在 GROUP BY 中或使用 Hibernate 6 扩展，H2 兼容性不确定。子查询方案更稳健。

### D4: 分页参数互斥逻辑

```
if (cursor != null && sort == "latest")  → cursor 模式
else                                      → offset 模式
```

Controller 层判断，Service 层分两条路径执行。cursor 模式下 `page` 字段在响应中为 null。

### D5: commentCount 语义

`deleted = false` 的评论数。与帖子本身的软删除语义一致——用户可见的才是有效数据。

### D6: PostResponse 字段扩展

列表项和详情共用 `PostResponse`，新增三个字段均带 `@JsonProperty`：

```java
@JsonProperty("comment_count")
private final long commentCount;

@JsonProperty("up_vote_count")
private final long upVoteCount;

@JsonProperty("bookmark_count")
private final long bookmarkCount;
```

详情接口（`includeContent=true`）同样填充这三个字段，保持接口一致性。

### D7: PostListResponse 新增 cursor 字段

```java
@JsonProperty("next_cursor")
private final String nextCursor;  // nullable, ISO 8601

@JsonProperty("has_more")
private final boolean hasMore;
```

offset 模式下 `nextCursor = null`，`hasMore = page * size < total`。
cursor 模式下 `page = null`（JSON 序列化需 `@JsonInclude(NON_NULL)` 或在 `getPage()` 返回 `Integer` nullable）。

### D8: 前端 PostCard 统计行

```
👍 12   💬 5   🔖 3
```

使用 `ThumbsUp` / `MessageCircle` / `Bookmark` 图标（lucide-react），放在卡片底部日期上方，`text-sm text-slate-500`。

### D9: 前端排序切换

帖子列表页头部区域新增排序选项卡（按钮组）：`最新` / `最热` / `最多评论`，默认 `latest`。切换时重置 page=1 并重新请求。使用 `useState` 管理 sort 参数。

## Risks / Trade-offs

- **[风险] JPQL 子查询性能** → 数据量 <10 万时子查询可接受；如未来数据增长，可引入物化视图或缓存计数器
- **[风险] H2 与 MySQL 对 JPQL 子查询的行为差异** → TDD 阶段通过 `@DataJpaTest`（H2）验证 + 集成测试确认
- **[权衡] 详情接口也返回三个 count** → 详情页已有独立的 vote-stats / bookmark-status 接口获取精确数据，列表的三个 count 字段在详情页属冗余但无害，保持 API 一致性
- **[权衡] cursor 模式下不返回 total** → keyset pagination 天然不查 count(*)，前端如需显示总数需先做一次 offset 请求或单独 count 接口。当前前端翻页 UI 用 offset 模式，cursor 留给未来无限滚动
