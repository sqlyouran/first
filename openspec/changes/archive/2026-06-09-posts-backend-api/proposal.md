## Why

平台内容层目前仅有首页静态 Region-Slot 数据，后端无业务实体。`openspec/specs/posts/spec.md` 已定义完整的帖子 capability spec（发布/编辑/删除/列表/详情），本次实现其后端 HTTP API，使前端可对接真实数据源。

## What Changes

- 新增 `PostEntity`（继承 `BaseEntity`）：title / content(TEXT) / coverImage / tags(JSON 列 + AttributeConverter) / status(PostStatus enum: DRAFT/PUBLISHED/ARCHIVED) / authorId(UUID)
- 新增 `PostRepository`：Spring Data JPA，支持分页查询 + 按作者/状态/删除状态过滤
- 新增 `PostService`：createPost / updatePost / deletePost(逻辑删除) / getPost / listPosts / listUserPosts
- 新增 `PostController`：6 个端点（POST/PUT/DELETE 需 JWT，GET 公开）
- 新增 `PostException` + GlobalExceptionHandler 扩展处理
- 新增 `StringListConverter`（`List<String>` ↔ JSON 字符串）
- 新增 Request DTO（record）+ Response DTO（extends BaseResponse）

## Capabilities

### New Capabilities

- `posts-backend-api`: 帖子后端 HTTP API 实现合约——统一错误格式、字段校验、JWT 认证、分页列表

### Modified Capabilities

（无——`posts` capability spec 已完整定义，本次不修改其 requirements）

## Impact

- **后端代码**：`backend/src/main/java/com/mooc/app/` 新增 entity / repository / service / controller / dto / exception / converter 各类
- **数据库**：新建 `posts` 表（H2 开发库，create-drop 模式），无独立关联表
- **安全**：复用 `JwtService` 做 token 解析，SecurityConfig 保持 permitAll，写操作在 Controller 层手动校验
- **依赖**：无新增 Maven 依赖（validation / data-jpa / security / jackson 均已存在）
- **前端**：本次不动，前端集成留给后续 change
