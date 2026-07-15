## ADDED Requirements

### Requirement: JWT 密钥环境变量化

`application.yml` 中 `app.jwt.secret` SHALL 使用环境变量占位 `${JWT_SECRET:dev-secret-key-change-in-production-min-32-chars!!}`，不再硬编码生产密钥。

#### Scenario: 开发环境使用 fallback 密钥

- **GIVEN** 未设置 `JWT_SECRET` 环境变量
- **WHEN** 应用启动
- **THEN** 使用 fallback 值 `dev-secret-key-change-in-production-min-32-chars!!`，应用正常启动

#### Scenario: 生产环境使用环境变量密钥

- **GIVEN** 设置 `JWT_SECRET=<64字符随机字符串>`
- **WHEN** 应用启动
- **THEN** 使用环境变量中的密钥签发和校验 JWT

---

### Requirement: Springdoc 可配置开关

Springdoc/OpenAPI 文档 SHALL 通过 `springdoc.api-docs.enabled` 配置项控制，生产 profile 默认为 `false`。

#### Scenario: 生产环境 Swagger 关闭

- **GIVEN** 激活 `prod` profile（`springdoc.api-docs.enabled=false`）
- **WHEN** 请求 `GET /v3/api-docs`
- **THEN** HTTP 404 或 403，文档不可访问

#### Scenario: 开发环境 Swagger 可用

- **GIVEN** 未激活 `prod` profile
- **WHEN** 请求 `GET /v3/api-docs`
- **THEN** HTTP 200，返回 OpenAPI schema

---

### Requirement: 生产 profile 分离

系统 SHALL 提供 `application-prod.yml`，包含生产环境覆盖配置：`ddl-auto: validate`、`sql.init.mode: never`、`springdoc.api-docs.enabled: false`。

#### Scenario: 激活 prod profile 使用安全 DDL 策略

- **GIVEN** `SPRING_PROFILES_ACTIVE=prod`
- **WHEN** 应用启动
- **THEN** `hibernate.ddl-auto` 为 `validate`
- **AND** `sql.init.mode` 为 `never`

#### Scenario: 开发环境不受影响

- **GIVEN** 未设置 `SPRING_PROFILES_ACTIVE`
- **WHEN** 应用启动
- **THEN** 使用默认 `ddl-auto: update` 和 `sql.init.mode: always`

---

### Requirement: .env.example 完整声明

`.env.example` SHALL 列出所有安全相关环境变量及说明：`JWT_SECRET`、`CORS_ALLOWED_ORIGINS`、`MYSQL_PASSWORD`、`DASHSCOPE_API_KEY`、`EXCHANGE_RATE_API_KEY`。

#### Scenario: .env.example 包含所有安全变量

- **WHEN** 查看 `.env.example` 文件
- **THEN** 文件包含 `JWT_SECRET`、`CORS_ALLOWED_ORIGINS` 字段及注释说明
