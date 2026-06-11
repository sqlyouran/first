## 1. 认证工具提炼

- [x] 1.1 新增 `util/AuthUtil.java`：静态方法 `requireUserId(HttpServletRequest, JwtService)` — 提取 Bearer token → parseToken → UUID，失败抛 PostException(UNAUTHORIZED)
- [x] 1.2 新增 `AuthUtil.optionalUserId(HttpServletRequest, JwtService)` → Optional<UUID>，token 无效/缺失返回 empty
- [x] 1.3 新增 `AuthUtil.getRequestId(HttpServletRequest)` → String，从 request attribute 取 RequestIdFilter.REQUEST_ID_ATTR
- [x] 1.4 重构 `PostController`：删除私有 `requireUserId` / `getRequestId`，改调 `AuthUtil` 静态方法
- [x] 1.5 验证：现有 PostControllerTest 全部绿灯

## 2. 评论模块 — Entity + Repository

- [x] 2.1 新增 `entity/CommentEntity.java`：继承 BaseEntity，字段 postId(UUID @Column(name="post_id") not null) + userId(UUID @Column(name="user_id") not null) + content(@Column(columnDefinition="TEXT") @NotBlank @Size(max=10000)) + parentCommentId(UUID @Column(name="parent_comment_id") nullable)
- [x] 2.2 新增 `repository/CommentRepository.java`：`findByPostIdAndParentCommentIdIsNullAndDeletedFalseOrPostIdAndParentCommentIdIsNullAndDeletedTrue(UUID postId, Pageable)` — 实际用 @Query 简化：按 postId 查顶层评论（含已删除）；`findByParentCommentId(UUID parentId, Pageable)` — 查回复（含已删除）；`findByIdAndDeletedFalse(UUID id)` — 查单条未删除评论
- [x] 2.3 验证：@DataJpaTest 测试 CommentEntity 持久化 + 查询方法

## 3. 评论模块 — Service + DTO

- [x] 3.1 新增 `dto/CreateCommentRequest.java`（record）：content(@NotBlank @Size(max=10000)) + parentCommentId(UUID 可选)
- [x] 3.2 新增 `dto/response/CommentResponse.java`（extends BaseResponse）：id, post_id, user_id, content, parent_comment_id, created_at, deleted
- [x] 3.3 新增 `dto/response/CommentListResponse.java`（extends BaseResponse）：items, total, page, size
- [x] 3.4 新增 `service/CommentService.java`：createComment(postId, userId, request, requestId) — 校验帖子存在 + 父评论存在（如有），保存返回 CommentResponse
- [x] 3.5 实现 `CommentService.listTopLevelComments(postId, page, size, requestId)` — 查顶层评论(含已删除)，已删除的 content 替换为 "[已删除]"
- [x] 3.6 实现 `CommentService.listReplies(commentId, page, size, requestId)` — 按 parentCommentId 查回复，已删除的 content 替换
- [x] 3.7 实现 `CommentService.deleteComment(commentId, userId)` — 校验作者，markDeleted()

## 4. 评论模块 — Controller + 测试

- [x] 4.1 新增 `controller/CommentController.java`：注入 CommentService + JwtService
- [x] 4.2 实现 `POST /api/posts/{postId}/comments`：AuthUtil.requireUserId → createComment → 201
- [x] 4.3 实现 `GET /api/posts/{postId}/comments?page&size`：公开访问 → listTopLevelComments → 200
- [x] 4.4 实现 `GET /api/comments/{commentId}/replies?page&size`：公开访问 → listReplies → 200
- [x] 4.5 实现 `DELETE /api/posts/{postId}/comments/{commentId}`：AuthUtil.requireUserId → deleteComment → 204
- [x] 4.6 新增 `CommentControllerTest.java`（@WebMvcTest）：覆盖 spec 中所有评论场景

## 5. 投票模块 — Entity + Repository

- [x] 5.1 新增 `entity/VoteType.java` 枚举：UP / DOWN
- [x] 5.2 新增 `entity/VoteEntity.java`：继承 BaseEntity，字段 postId(UUID @Column(name="post_id") not null) + userId(UUID @Column(name="user_id") not null) + voteType(@Enumerated(STRING) @Column(name="vote_type") not null)。@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"post_id", "user_id"}))
- [x] 5.3 新增 `repository/VoteRepository.java`：`findByPostIdAndUserId(UUID, UUID)` → Optional；`countByPostIdAndVoteType(UUID, VoteType)` → long
- [x] 5.4 验证：@DataJpaTest 测试 unique constraint + 查询

## 6. 投票模块 — Service + DTO

- [x] 6.1 新增 `dto/VoteRequest.java`（record）：voteType(@NotNull String，值为 "up"/"down")
- [x] 6.2 新增 `dto/response/VoteResponse.java`（extends BaseResponse）：vote_type(String nullable)
- [x] 6.3 新增 `dto/response/VoteStatsResponse.java`（extends BaseResponse）：up_count, down_count, user_vote(String nullable)
- [x] 6.4 新增 `service/VoteService.java`：vote(postId, userId, voteType, requestId) — 三态逻辑（创建/取消/切换）
- [x] 6.5 实现 `VoteService.removeVote(postId, userId)` — 删除投票记录（幂等）
- [x] 6.6 实现 `VoteService.getVoteStats(postId, optionalUserId, requestId)` — 统计 + 当前用户投票状态

## 7. 投票模块 — Controller + 测试

- [x] 7.1 新增 `controller/VoteController.java`：注入 VoteService + JwtService
- [x] 7.2 实现 `POST /api/posts/{postId}/vote`：AuthUtil.requireUserId → vote → 200
- [x] 7.3 实现 `DELETE /api/posts/{postId}/vote`：AuthUtil.requireUserId → removeVote → 204
- [x] 7.4 实现 `GET /api/posts/{postId}/vote-stats`：AuthUtil.optionalUserId → getVoteStats → 200
- [x] 7.5 新增 `VoteControllerTest.java`（@WebMvcTest）：覆盖 spec 中所有投票场景（含可选认证）

## 8. 收藏模块 — Entity + Repository

- [x] 8.1 新增 `entity/BookmarkEntity.java`：继承 BaseEntity，字段 postId(UUID @Column(name="post_id") not null) + userId(UUID @Column(name="user_id") not null)。@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"post_id", "user_id"}))
- [x] 8.2 新增 `repository/BookmarkRepository.java`：`findByPostIdAndUserId(UUID, UUID)` → Optional；`findByUserIdOrderByCreatedAtDesc(UUID, Pageable)` → Page；`countByUserId(UUID)` → long
- [x] 8.3 验证：@DataJpaTest 测试 unique constraint + 分页查询

## 9. 收藏模块 — Service + DTO

- [x] 9.1 新增 `dto/response/BookmarkResponse.java`（extends BaseResponse）：bookmarked(boolean)
- [x] 9.2 新增 `dto/response/BookmarkListResponse.java`（extends BaseResponse）：items(List<BookmarkItemResponse>), total, page, size。BookmarkItemResponse 包含 bookmark_id, post_id, post_title, created_at
- [x] 9.3 新增 `service/BookmarkService.java`：toggleBookmark(postId, userId, requestId) — 存在则删除返回 false，不存在则创建返回 true
- [x] 9.4 实现 `BookmarkService.listBookmarks(userId, page, size, requestId)` — 分页查询 + 关联帖子标题

## 10. 收藏模块 — Controller + 测试

- [x] 10.1 新增 `controller/BookmarkController.java`：注入 BookmarkService + JwtService
- [x] 10.2 实现 `POST /api/posts/{postId}/bookmark`：AuthUtil.requireUserId → toggleBookmark → 200
- [x] 10.3 实现 `GET /api/bookmarks?page&size`：AuthUtil.requireUserId → listBookmarks → 200
- [x] 10.4 新增 `BookmarkControllerTest.java`（@WebMvcTest）：覆盖 spec 中所有收藏场景

## 11. 集成验证

- [x] 11.1 全量运行 `./mvnw test`，确保新旧测试全部绿灯
- [x] 11.2 启动应用验证三张表自动创建（ddl-auto: update）
