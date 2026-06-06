## 1. 后端依赖与基础配置

- [x] 1.1 在 `backend/pom.xml` 添加 `springdoc-openapi-starter-webmvc-ui:2.6.0` 依赖
- [x] 1.2 验证后端启动后 `GET /v3/api-docs` 返回 200 且包含 `openapi` 字段
- [x] 1.3 验证 `http://localhost:8080/swagger-ui.html` 可访问

## 2. BaseResponse 抽象基类

- [x] 2.1 创建 `dto/response/BaseResponse.java`：abstract class，含 `@JsonProperty("request_id") String requestId` 字段 + constructor + getter
- [x] 2.2 编写 BaseResponse 单元测试（验证 JSON 序列化输出 `request_id` 字段）

## 3. 成功响应 DTO

- [x] 3.1 创建 `dto/response/SendCodeResponse.java` extends BaseResponse（仅 requestId）
- [x] 3.2 创建 `dto/response/RegisterResponse.java` extends BaseResponse（仅 requestId）
- [x] 3.3 创建 `dto/response/LoginResponse.java` extends BaseResponse（accessToken + expiresIn）
- [x] 3.4 创建 `dto/response/RefreshResponse.java` extends BaseResponse（accessToken + expiresIn）
- [x] 3.5 创建 `dto/response/UserInfoResponse.java` extends BaseResponse（id + email + state + createdAt）

## 4. ErrorResponse 改造

- [x] 4.1 将 `dto/ErrorResponse.java` 从 record 重构为 class extends BaseResponse（保留 errorCode / message / details 字段）
- [x] 4.2 修改 `GlobalExceptionHandler.java` 适配新的 ErrorResponse 构造方式
- [x] 4.3 验证现有异常处理测试通过（修复因 ErrorResponse 构造变更导致的编译错误）

## 5. AuthController 返回值重构

- [x] 5.1 将 `POST /send-code` 返回值从 `Map` 改为 `SendCodeResponse`
- [x] 5.2 将 `POST /register` 返回值从 `Map` 改为 `RegisterResponse`
- [x] 5.3 将 `POST /login` 返回值从 `Map` 改为 `LoginResponse`
- [x] 5.4 将 `POST /refresh` 返回值从 `Map` 改为 `RefreshResponse`
- [x] 5.5 将 `GET /me` 返回值从 `Map` 改为 `UserInfoResponse`
- [x] 5.6 验证 `AuthControllerTest` 全部通过（修复因返回类型变更导致的断言）

## 6. OpenAPI Security 注解

- [x] 6.1 创建 `config/OpenApiConfig.java`，声明 `@SecurityScheme(name = "bearerAuth", type = HTTP, scheme = "bearer", bearerFormat = "JWT")`
- [x] 6.2 在 AuthController 的 `GET /me` 和 `DELETE /me` 方法上添加 `@SecurityRequirement(name = "bearerAuth")`
- [x] 6.3 验证 `/v3/api-docs` 输出包含 `components.securitySchemes.bearerAuth` 且受保护端点有 `security` 声明

## 7. 前端类型生成管线

- [x] 7.1 在 `frontend/` 安装 `openapi-typescript` 为 devDependency
- [x] 7.2 在 `package.json` 添加 `"generate:api"` script：`openapi-typescript http://localhost:8080/v3/api-docs -o lib/api/schema.d.ts`
- [x] 7.3 启动后端，执行 `npm run generate:api`，验证 `lib/api/schema.d.ts` 生成成功且包含 `paths` 和 `components` 类型
- [x] 7.4 将生成的 `schema.d.ts` 提交到 git
