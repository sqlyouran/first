## Why

项目已锁定"OpenAPI / springdoc-openapi + openapi-typescript"作为前后端接口契约层（见 AGENTS.md 技术选型），但当前后端无 springdoc 依赖、Controller 返回裸 `Map<String, Object>`（springdoc 无法推断精确 schema），前端无自动类型生成管线。随着 Auth 模块完成，端点数量开始增长，手动维护类型对齐的成本将持续上升。现在是补齐契约基础设施的合适时机。

## What Changes

- 后端添加 `springdoc-openapi-starter-webmvc-ui 2.6.0` 依赖，自动暴露 `/v3/api-docs`（JSON schema）和 `/swagger-ui.html`（可视化文档）
- AuthController 返回值从 `Map<String, Object>` 重构为强类型 Response DTO（继承 `BaseResponse` 抽象基类，统一管理 `request_id`）
- `ErrorResponse` 从 record 改为 class，同样继承 `BaseResponse`
- 添加 `@SecurityScheme` + `@SecurityRequirement` 注解，声明 Bearer JWT 认证方式
- 前端添加 `openapi-typescript` devDependency + `generate:api` npm script，生成 `lib/api/schema.d.ts` 并提交到 git

## Capabilities

### New Capabilities
- `openapi-contract`: 后端 OpenAPI schema 自动生成 + 前端 TypeScript 类型自动派生的契约管线

### Modified Capabilities
<!-- 本次变更不改变任何已有 spec 的外部行为。DTO 重构是内部实现变更，API 输入输出格式保持不变。 -->

## Impact

- **后端代码**：`pom.xml`（新依赖）、`dto/` 包（新增 BaseResponse + 5 个 Response DTO、ErrorResponse 改造）、`AuthController`（返回值类型变更）、`GlobalExceptionHandler`（适配新 ErrorResponse 构造）、`SecurityConfig` 或新增 OpenAPI 配置类（@SecurityScheme）
- **前端代码**：`package.json`（新 devDep + script）、新增 `lib/api/schema.d.ts`（自动生成，进 git）
- **API 行为**：无 breaking change，JSON 响应格式保持不变
- **新增端点**：`/v3/api-docs`、`/swagger-ui.html`（springdoc 自动注册）
