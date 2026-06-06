## ADDED Requirements

### Requirement: OpenAPI Schema 自动生成

后端 SHALL 在应用启动后自动暴露符合 OpenAPI 3.1 规范的 JSON schema，路径为 `/v3/api-docs`。schema SHALL 包含 AuthController 所有端点的完整定义（路径、方法、请求体、响应体、状态码）。

#### Scenario: 访问 OpenAPI JSON endpoint

- **WHEN** 客户端发送 `GET /v3/api-docs`
- **THEN** 返回 HTTP 200
- **AND** Content-Type 为 `application/json`
- **AND** 响应体包含 `openapi` 字段（值为 "3.1.x"）
- **AND** 响应体 `paths` 对象包含 `/api/auth/login`、`/api/auth/register`、`/api/auth/send-code`、`/api/auth/refresh`、`/api/auth/logout`、`/api/auth/me` 路径

#### Scenario: Schema 包含精确的响应类型

- **WHEN** 客户端发送 `GET /v3/api-docs`
- **THEN** `/api/auth/login` POST 的 200 响应 schema 包含 `request_id`（type: string）、`access_token`（type: string）、`expires_in`（type: integer）字段
- **AND** 所有字段标记为 required

---

### Requirement: Swagger UI 可视化文档

后端 SHALL 提供 Swagger UI 界面，路径为 `/swagger-ui.html`，用于人工浏览和测试 API。

#### Scenario: 访问 Swagger UI

- **WHEN** 用户在浏览器访问 `http://localhost:8080/swagger-ui.html`
- **THEN** 页面加载成功（HTTP 200 或 302 重定向后 200）
- **AND** 页面展示 AuthController 的所有端点

---

### Requirement: Response DTO 强类型化

AuthController 的所有成功响应 SHALL 使用强类型 DTO（继承 `BaseResponse` 抽象基类）。`BaseResponse` 提供 `request_id` 字段。ErrorResponse 同样 SHALL 继承 `BaseResponse`。

#### Scenario: 成功响应包含精确字段

- **WHEN** 客户端提交 `POST /api/auth/login` with 有效凭据
- **THEN** 返回 HTTP 200
- **AND** 响应体 JSON 包含且仅包含 `request_id`（string）、`access_token`（string）、`expires_in`（integer）

#### Scenario: 错误响应保持一致格式

- **WHEN** 客户端提交 `POST /api/auth/login` with 无效凭据
- **THEN** 返回 HTTP 401
- **AND** 响应体 JSON 包含 `request_id`（string）、`error_code`（string）、`message`（string）、`details`（object）

---

### Requirement: OpenAPI Security Scheme 声明

OpenAPI schema SHALL 声明 HTTP Bearer (JWT) 认证方式。需要认证的端点（`GET /api/auth/me`、`DELETE /api/auth/me`）SHALL 在 schema 中标注 `securityRequirement`。

#### Scenario: Schema 包含 security scheme 定义

- **WHEN** 客户端发送 `GET /v3/api-docs`
- **THEN** 响应体 `components.securitySchemes` 包含 `bearerAuth` 定义
- **AND** 其 `type` 为 `http`，`scheme` 为 `bearer`，`bearerFormat` 为 `JWT`

#### Scenario: 受保护端点标注 security requirement

- **WHEN** 客户端发送 `GET /v3/api-docs`
- **THEN** `/api/auth/me` GET 操作的 `security` 数组包含 `bearerAuth`
- **AND** `/api/auth/me` DELETE 操作的 `security` 数组包含 `bearerAuth`

---

### Requirement: 前端 TypeScript 类型生成

前端 SHALL 提供 npm script `generate:api`，从后端 OpenAPI schema 生成 TypeScript 类型定义文件 `lib/api/schema.d.ts`。生成的类型文件 SHALL 提交到 git。

#### Scenario: 执行类型生成命令

- **WHEN** 后端运行中（`http://localhost:8080/v3/api-docs` 可达）
- **AND** 开发者在 `frontend/` 目录执行 `npm run generate:api`
- **THEN** 生成文件 `lib/api/schema.d.ts`
- **AND** 文件包含 `paths` 类型（描述所有 API 路径）
- **AND** 文件包含 `components` 类型（描述所有 schema）
