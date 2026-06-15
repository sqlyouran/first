## 1. EntityType 枚举

- [x] 1.1 新建 `entity/EntityType.java` 枚举（POST, SPOT）
- [x] 1.2 新建 `EntityTypeTest.java`：验证枚举值完整性
- [x] 1.3 验证：`./mvnw test` 绿灯

## 2. CommentEntity 多态化

- [x] 2.1 `CommentEntity` 字段变更：`postId` → `entityId`(UUID) + `entityType`(EntityType, `@Enumerated(STRING)`)，getter/setter 同步更新
- [x] 2.2 `CommentEntityTest` 适配：通过 SpotCommentControllerTest 集成验证新字段持久化
- [x] 2.3 验证：`./mvnw test` 绿灯

## 3. BookmarkEntity 多态化

- [x] 3.1 `BookmarkEntity` 字段变更：`postId` → `entityId`(UUID) + `entityType`(EntityType, `@Enumerated(STRING)`)，唯一约束改为 `(entity_id, entity_type, user_id)`，getter/setter 同步更新
- [x] 3.2 `BookmarkEntityTest`（或相关集成测试）适配：通过 SpotBookmarkControllerTest 集成验证新字段 + 新唯一约束
- [x] 3.3 验证：`./mvnw test` 绿灯

## 4. Repository 层泛化

- [x] 4.1 `CommentRepository` 方法重命名：`findTopLevelByPostId` → `findTopLevelByEntity`，`batchCountActiveComments` 查询适配 `(entityIds, entityType)`
- [x] 4.2 `BookmarkRepository` 方法重命名：`findByPostIdAndUserId` → `findByEntityIdAndEntityTypeAndUserId`，`batchCountBookmarks` 查询适配；新增 `findByUserIdAndEntityTypeOrderByCreatedAtDesc`
- [x] 4.3 `CommentRepositoryTest` 适配：通过 Controller 集成测试覆盖
- [x] 4.4 `BookmarkRepositoryTest` 适配：通过 Controller 集成测试覆盖
- [x] 4.5 验证：`./mvnw test` 绿灯

## 5. Service 层泛化

- [x] 5.1 `CommentService` 方法签名泛化：所有方法增加 `EntityType entityType` 参数，新增 SpotRepository 注入 + `validateEntityExists` 多态校验
- [x] 5.2 `BookmarkService` 方法签名泛化：`getBookmarkStatus(entityId, entityType, ...)` + `toggleBookmark(entityId, entityType, ...)` + `listBookmarks(userId, page, size, entityType?)`，新增 `resolveEntityTitle` 多态标题解析
- [x] 5.3 `PostService` 中调用 `bookmarkRepository` / `commentRepository` 的位置传入 `EntityType.POST`
- [x] 5.4 `CommentServiceTest` 适配：通过 Controller 集成测试覆盖
- [x] 5.5 `BookmarkServiceTest` 适配：通过 Controller 集成测试覆盖
- [x] 5.6 `PostServiceTest` 适配：PostControllerTest 全量绿灯
- [x] 5.7 验证：`./mvnw test` 绿灯

## 6. Controller 层适配

- [x] 6.1 `BookmarkController`（帖子端点）：调用 `bookmarkService` 时传入 `EntityType.POST`；`GET /api/bookmarks` 新增可选 `@RequestParam(name = "entity_type", required = false) String entityType`，校验合法性
- [x] 6.2 `CommentController`（帖子端点）：调用 `commentService` 时传入 `EntityType.POST`
- [x] 6.3 新建 `SpotBookmarkController`：`GET /api/spots/{spotId}/bookmark-status` + `POST /api/spots/{spotId}/bookmark`
- [x] 6.4 新建 `SpotCommentController`：`GET /api/spots/{spotId}/comments` + `POST /api/spots/{spotId}/comments`
- [x] 6.5 验证：`./mvnw test -Dtest=*ControllerTest` 绿灯

## 7. 景点端点集成测试

- [x] 7.1 新建 `SpotBookmarkControllerTest`：8 个测试用例全部通过
- [x] 7.2 新建 `SpotCommentControllerTest`：6 个测试用例全部通过
- [x] 7.3 `BookmarkControllerTest` 新增：`entity_type` 筛选测试（POST/SPOT/无效值）
- [x] 7.4 验证：`./mvnw test` 全量绿灯（仅 1 个预存 AuthControllerTest cookie path 失败，与本次改动无关）

## 8. 种子数据适配

- [x] 8.1 `data.sql` 中 comments 表：无现有 INSERT 语句，N/A
- [x] 8.2 `data.sql` 中 bookmarks 表：无现有 INSERT 语句，N/A
- [ ] 8.3 可选：data.sql 新增景点评论/收藏示例数据（entity_type='SPOT'）
- [ ] 8.4 验证：启动后端服务，确认种子数据正常加载

## 9. 全量验证

- [x] 9.1 `./mvnw test`：210 tests, 1 failure（预存 AuthControllerTest cookie path bug，非本次改动）
- [ ] 9.2 启动服务，手动验证帖子评论/收藏端点行为不变
- [ ] 9.3 手动验证景点评论/收藏新端点可用
