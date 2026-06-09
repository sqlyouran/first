## Context

后端已有完整 auth 分层（AuthController / AuthService / JwtService / UserEntity / GlobalExceptionHandler）。SecurityConfig 配置 `anyRequest().permitAll()`，JWT 校验在 Controller 层通过 `extractBearerToken` + `JwtService.parseToken()` 手动完成。

`openspec/specs/posts/spec.md` 已定义 11 个 Requirement + 30+ 验收场景。本次需实现后端 HTTP API 使其完全满足 spec 行为。

约束：
- Spring Boot 3.3.5 + JDK 17 + Maven 单模块
- 复用 BaseEntity / JwtService / GlobalExceptionHandler / ErrorResponse
- SecurityConfig 保持 permitAll，写操作 Controller 层手动校验

## Goals / Non-Goals

**Goals:**

- 实现帖子 CRUD：POST / PUT / DELETE（逻辑删除）/ GET 列表（分页）/ GET 详情 / GET 用户帖子列表
- 写操作 JWT 认证（复用 AuthController 的 Bearer token 提取模式）
- PostEntity 继承 BaseEntity，tags 用 JSON 列 + AttributeConverter
- PostStatus: DRAFT / PUBLISHED（默认）/ ARCHIVED
- 列表 `created_at DESC`，仅返回 published + deleted=false
- 分页响应遵循 api-conventions：`{ items, total, page, size }`
- 字段校验：title / content / tags / cover_image
- @WebMvcTest 切片测试覆盖所有 spec 场景

**Non-Goals:**

- 前端集成（后续 change）
- 图片上传（coverImage 仅存 URL）
- 按 tag 搜索/聚合（后续 change）
- Markdown 渲染（前端负责）
- RBAC（作者即所有者）

## Decisions

### D1: 认证策略 — Controller 层手动校验

复用 AuthController 的 `extractBearerToken` 模式：

```java
private UUID requireUserId(HttpServletRequest request) {
    String authHeader = request.getHeader("Authorization");
    if (authHeader == null || !authHeader.startsWith("Bearer ")) {
        throw new PostException(HttpStatus.UNAUTHORIZED, "unauthorized", "...");
    }
    return jwtService.parseToken(authHeader.substring(7))
        .map(c -> UUID.fromString(c.getSubject()))
        .orElseThrow(() -> new PostException(HttpStatus.UNAUTHORIZED, ...));
}
```

**理由**：与 auth 模块风格一致；GET 端点无需认证，permitAll 最自然。

### D2: tags 存储 — JSON 列 + AttributeConverter

```java
@Convert(converter = StringListConverter.class)
@Column(columnDefinition = "TEXT")
private List<String> tags = new ArrayList<>();
```

`StringListConverter` 实现 `AttributeConverter<List<String>, String>`，使用 Jackson ObjectMapper 序列化/反序列化。

**理由**：单表无 JOIN，查询简单；标签 ≤10 条，无需 SQL 层按 tag 过滤。

### D3: PostException — 复用 AuthException 结构

```java
public class PostException extends RuntimeException {
    private final HttpStatus status;
    private final String errorCode;
}
```

GlobalExceptionHandler 新增 `@ExceptionHandler(PostException.class)`，映射到 ErrorResponse。

**理由**：与 AuthException 结构一致，GlobalExceptionHandler 已有处理模板。

### D4: 分页 — Spring Data Pageable

```java
Pageable pageable = PageRequest.of(
    Math.max(page - 1, 0),
    Math.min(size, 100),
    Sort.by(Sort.Direction.DESC, "createdAt")
);
```

page 从 1 开始（api-conventions），内部转 0-based。size 上限 100。

### D5: DTO 结构

```
CreatePostRequest (record): title / content / coverImage / tags / status
UpdatePostRequest (record): 同字段，均可 null（partial update）
PostResponse (extends BaseResponse): id / title / content / cover_image / tags / status / author_id / created_at / updated_at
PostListResponse (extends BaseResponse): items(List<PostResponse>) / total / page / size
```

列表返回的 PostResponse 中 content 可为 null（列表不含正文）。

### D6: 详情接口对非 PUBLISHED 的处理

GET /api/posts/{id} 公开访问：
- published + deleted=false → 200
- draft / archived / deleted=true / 不存在 → 404（不暴露存在性）

### D7: 删除为逻辑删除

DELETE /api/posts/{id}：
- 校验 JWT → 查帖子(id, deleted=false) → 校验 authorId 一致 → markDeleted() → save → 204

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| JSON 列无法 SQL 层按 tag 查询 | 当前无此需求；后续可加 PostgreSQL JSON 函数或改用关联表 |
| Controller 手动认证代码重复 | 仅 auth + posts 两模块；3+ 模块时升级为 HandlerMethodArgumentResolver |
| H2 与 PG 的 JSON TEXT 存储差异 | 仅用 JPA 标准 API + AttributeConverter，不写原生 SQL |
