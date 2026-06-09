## 1. 基础设施

- [x] 1.1 新增 `converter/StringListConverter.java`：实现 `AttributeConverter<List<String>, String>`，使用 Jackson ObjectMapper 序列化/反序列化，处理 null → 空 List
- [x] 1.2 新增 `entity/PostStatus.java` 枚举：`DRAFT` / `PUBLISHED` / `ARCHIVED`
- [x] 1.3 新增 `entity/PostEntity.java`：继承 BaseEntity，含 title(@NotBlank @Size(max=200)) / content(@NotBlank @Size(max=50000) TEXT) / coverImage(@Size(max=2048)) / tags(@Convert JSON列) / status(@Enumerated(STRING) 默认PUBLISHED) / authorId(@NotNull UUID)
- [x] 1.4 新增 `repository/PostRepository.java`：`findByStatusAndDeletedFalse(PostStatus, Pageable)` / `findByAuthorIdAndStatusAndDeletedFalse(UUID, PostStatus, Pageable)` / `findByIdAndDeletedFalse(UUID)`

## 2. DTO

- [x] 2.1 新增 `dto/CreatePostRequest.java`（record）：title / content / coverImage / tags(List) / status(String 可选)，含 Jakarta Validation 注解
- [x] 2.2 新增 `dto/UpdatePostRequest.java`（record）：同字段，均可 null（partial update）
- [x] 2.3 新增 `dto/response/PostResponse.java`（extends BaseResponse）：id / title / content / cover_image / tags / status / author_id / created_at / updated_at，@JsonProperty snake_case
- [x] 2.4 新增 `dto/response/PostListResponse.java`（extends BaseResponse）：items(List) / total / page / size，@JsonProperty snake_case

## 3. 异常处理

- [x] 3.1 新增 `exception/PostException.java`：继承 RuntimeException，持有 HttpStatus + errorCode + message
- [x] 3.2 更新 `exception/GlobalExceptionHandler.java`：新增 `@ExceptionHandler(PostException.class)` → ErrorResponse

## 4. 业务服务

- [x] 4.1 新增 `service/PostService.java`：构造器注入 PostRepository + JwtService + UserRepository
- [x] 4.2 实现 `createPost(CreatePostRequest, UUID authorId)`：校验用户存在 → 构造 PostEntity → save → PostResponse
- [x] 4.3 实现 `updatePost(UUID postId, UpdatePostRequest, UUID authorId)`：查帖子(deleted=false) → 校验 authorId(403) → partial update → save → PostResponse
- [x] 4.4 实现 `deletePost(UUID postId, UUID authorId)`：查帖子(deleted=false) → 校验 authorId(403) → markDeleted() → save
- [x] 4.5 实现 `getPost(UUID postId)`：查帖子(id, deleted=false, status=PUBLISHED) → 无则 404 → PostResponse（含 content）
- [x] 4.6 实现 `listPosts(int page, int size)`：Pageable(page-1, min(size,100), DESC createdAt) → findByStatusAndDeletedFalse(PUBLISHED) → PostListResponse
- [x] 4.7 实现 `listUserPosts(UUID authorId, int page, int size)`：同上，用 findByAuthorIdAndStatusAndDeletedFalse

## 5. Controller

- [x] 5.1 新增 `controller/PostController.java`：注入 PostService + JwtService
- [x] 5.2 实现 `requireUserId(HttpServletRequest)` helper：提取 Bearer token → parseToken → UUID
- [x] 5.3 `POST /api/posts`：@Valid CreatePostRequest + requireUserId → createPost → 201
- [x] 5.4 `PUT /api/posts/{id}`：@PathVariable + @Valid UpdatePostRequest + requireUserId → updatePost → 200
- [x] 5.5 `DELETE /api/posts/{id}`：@PathVariable + requireUserId → deletePost → 204
- [x] 5.6 `GET /api/posts/{id}`：@PathVariable → getPost → 200
- [x] 5.7 `GET /api/posts`：@RequestParam page/size → listPosts → 200
- [x] 5.8 `GET /api/users/{userId}/posts`：@PathVariable + @RequestParam page/size → listUserPosts → 200

## 6. 测试（TDD — RED → GREEN → REFACTOR）

- [x] 6.1 `PostEntityTest`（@DataJpaTest）：BaseEntity 字段自动填充 / markDeleted / tags JSON 持久化还原
- [x] 6.2 `StringListConverterTest`：序列化 / 反序列化 / null 处理
- [x] 6.3 `PostControllerTest`（@WebMvcTest）：POST /api/posts — 成功 201 / 草稿 / 无 token 401 / 校验失败 422
- [x] 6.4 `PostControllerTest`：PUT /api/posts/{id} — 成功 200 / 非作者 403 / 不存在 404 / 无 token 401
- [x] 6.5 `PostControllerTest`：DELETE /api/posts/{id} — 成功 204 / 非作者 403 / 不存在 404 / 无 token 401
- [x] 6.6 `PostControllerTest`：GET /api/posts/{id} — 成功 200 / 不存在 404 / draft 404 / archived 404
- [x] 6.7 `PostControllerTest`：GET /api/posts — 默认分页 / 自定义分页 / 仅 published / size 截断
- [x] 6.8 `PostControllerTest`：GET /api/users/{userId}/posts — 有数据 200 / 无数据空列表 200

## 7. 验收

- [x] 7.1 `mvn -f backend/pom.xml test` 全绿
- [x] 7.2 确认所有响应包含 request_id（RequestIdFilter 全局生效）
- [x] 7.3 确认 GET 端点无需 Authorization，POST/PUT/DELETE 必须携带
