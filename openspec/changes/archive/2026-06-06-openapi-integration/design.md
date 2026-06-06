## Context

当前后端 AuthController 的 7 个端点全部返回 `Map<String, Object>`，springdoc 无法推断精确 OpenAPI schema。前端 `fetchFromBackend()` 使用裸 fetch，无编译时类型保障。项目技术选型已锁定 springdoc-openapi + openapi-typescript 作为契约层，本次是首次落地。

现有代码结构：
- Request DTO：已是 Java record（`SendCodeRequest` / `RegisterRequest` / `LoginRequest`）
- Response：Controller 内手动拼 `Map.of(...)`，每个响应都包含 `request_id`
- `ErrorResponse`：record，包含 `request_id` / `error_code` / `message` / `details`
- `AuthService` 内部 record：`LoginResult` / `RefreshResult` / `UserInfo`（service 层）
- SecurityConfig：`permitAll()`，认证在 Controller 手动解析 Bearer token

## Goals / Non-Goals

**Goals:**
- 后端启动后自动暴露精确的 OpenAPI 3.1 JSON schema（`/v3/api-docs`）
- AuthController 所有成功响应有强类型 DTO，schema 中字段名/类型/必填性完整
- Swagger UI 可用于人工测试认证接口（含 Bearer token 输入）
- 前端可通过一条命令生成与后端 schema 对齐的 TypeScript 类型定义

**Non-Goals:**
- 不生成前端请求函数（L3 typed client）——只生成类型定义（L2）
- 不覆盖 HelloController
- 不做全局 JSON snake_case 命名策略
- 不在本次关闭生产环境 Swagger UI
- 不修改 API 对外行为（输入输出格式保持不变）

## Decisions

### Decision 1: Response DTO 采用 abstract class 继承体系

**选择**：`BaseResponse` 抽象基类持有 `request_id`，所有 Response DTO（含 ErrorResponse）继承该基类。

**替代方案**：
- Java record + interface：record 不可继承，每个 record 都需重复声明 `requestId` 字段，丧失"一处修改"的好处
- Lombok @Value：引入新依赖，违反 YAGNI

**理由**：继承使 `request_id` 在 schema 中表达为 `allOf` 引用基类，语义清晰；子类只声明业务字段。

### Decision 2: JSON 命名使用字段级 @JsonProperty

**选择**：每个字段显式标注 `@JsonProperty("snake_case_name")`。

**替代方案**：全局 `ObjectMapper` 配置 `SNAKE_CASE` 命名策略。

**理由**：全局配置影响所有 JSON 序列化（包括未来的非 Auth 端点），显式标注更可控、可读。

### Decision 3: OpenAPI Security 声明为 HTTP Bearer

**选择**：在 OpenAPI 配置类上添加 `@SecurityScheme(name = "bearerAuth", type = HTTP, scheme = "bearer", bearerFormat = "JWT")`，在需要认证的端点（`GET /me`、`DELETE /me`）上添加 `@SecurityRequirement(name = "bearerAuth")`。

**理由**：与现有实现一致（Controller 手动解析 `Authorization: Bearer <token>`），springdoc 不需要 Spring Security filter 实际执行 JWT 验证——只是文档声明。

### Decision 4: 前端 Spec 流转采用"本地生成 + Git 提交"方式

**选择**：开发者本地启动后端后执行 `npm run generate:api`，生成的 `lib/api/schema.d.ts` 提交进 git。

**替代方案**：
- 运行时拉取（需后端先启动，CI 复杂）
- CI artifact（当前无 CI 管线，overkill）

**理由**：submodule 结构下最简可行方案。前端 CI 不依赖后端运行。后续可升级为 CI 自动化。

### Decision 5: springdoc 版本选择 2.6.0

**选择**：`springdoc-openapi-starter-webmvc-ui:2.6.0`（Spring Boot 3.x 专用 starter）。

**理由**：v1.x 仅支持 Spring Boot 2；v2.6.0 是当前稳定版，兼容 Spring Boot 3.3.5。

## Risks / Trade-offs

- **[Risk] ErrorResponse 从 record 改为 class** → 已有测试中使用 record 的构造方式需同步修改。Mitigation：改造时同步修复 `GlobalExceptionHandler` 和相关测试。
- **[Risk] schema.d.ts 可能与后端漂移** → 开发者忘记重新生成。Mitigation：短期靠 PR review 检查；中期可加 CI lint step 比对 spec 时间戳。
- **[Trade-off] 每个字段都要写 @JsonProperty** → 代码略冗余，但换来明确性和可控性。
- **[Trade-off] BaseResponse 是 abstract class 而非 record** → 丧失 record 的简洁性，但 Response DTO 只有 5 个，可接受。
