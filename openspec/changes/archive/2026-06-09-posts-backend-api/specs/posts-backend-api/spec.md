## ADDED Requirements

### Requirement: PostException 统一异常

posts 模块 SHALL 使用 `PostException`（继承 RuntimeException），持有 HttpStatus + errorCode(snake_case) + message，由 GlobalExceptionHandler 统一映射到 ErrorResponse。

#### Scenario: PostException 映射到 ErrorResponse

- **WHEN** PostService 抛出 `PostException(HttpStatus.NOT_FOUND, "not_found", "Post not found")`
- **THEN** GlobalExceptionHandler 返回 HTTP 404
- **AND** 响应体包含 `request_id`（UUID v4）
- **AND** 响应体 `error_code: "not_found"`
- **AND** 响应体 `message: "Post not found"`
- **AND** 响应体 `details` 为 `{}`

---

### Requirement: StringListConverter JSON 序列化

`StringListConverter`（`AttributeConverter<List<String>, String>`）SHALL 使用 Jackson ObjectMapper 实现 `List<String>` ↔ JSON 字符串双向转换。

#### Scenario: 序列化 List 到 JSON 字符串

- **WHEN** Entity 字段值为 `["travel", "food"]`
- **THEN** 数据库列存储 `["travel","food"]`

#### Scenario: 反序列化 JSON 字符串到 List

- **WHEN** 数据库列值为 `["travel","food"]`
- **THEN** Entity 字段还原为 `List.of("travel", "food")`

#### Scenario: null 值处理

- **WHEN** Entity 字段值为 null
- **THEN** 数据库列存储 null
- **AND** 反向转换 null 列时返回空 List

---

### Requirement: JWT 认证 helper

PostController SHALL 提供 `requireUserId(HttpServletRequest)` helper 方法，从 Authorization header 提取 Bearer token 并通过 JwtService 解析用户 ID。

#### Scenario: 有效 Bearer token

- **GIVEN** 请求携带 `Authorization: Bearer <valid-jwt>`
- **WHEN** 调用 `requireUserId(request)`
- **THEN** 返回 JWT payload 中 `sub` 字段对应的 UUID

#### Scenario: 缺少 Authorization header

- **WHEN** 请求未携带 Authorization header
- **THEN** 抛出 PostException(HttpStatus.UNAUTHORIZED, "unauthorized", ...)

#### Scenario: 无效或过期 token

- **GIVEN** 请求携带 `Authorization: Bearer <invalid-or-expired-jwt>`
- **WHEN** 调用 `requireUserId(request)`
- **THEN** 抛出 PostException(HttpStatus.UNAUTHORIZED, "unauthorized", ...)

---

### Requirement: 行为合约对齐

posts-backend-api 的所有端点行为 SHALL 与 `openspec/specs/posts/spec.md` 中定义的 11 个 Requirement 完全一致。实现时以该 spec 为验收标准。

#### Scenario: spec 覆盖

- **WHEN** 运行 @WebMvcTest 切片测试
- **THEN** 测试用例覆盖 `specs/posts/spec.md` 中所有 Scenario
