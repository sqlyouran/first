---
trigger: always_on
---
# 后端编码规约

后端采用 Spring Boot 3.3.x + Java 17，标准分层架构。以下为 SHOULD 级约定（允许特例但需注释说明理由）。

## 分层架构

```
controller/   ← HTTP 层：参数校验、调用 service、构造 response
service/      ← 业务逻辑：不感知 HTTP，抛自定义 RuntimeException
repository/   ← 数据访问：Spring Data JPA interface
entity/       ← JPA 实体：继承 BaseEntity
dto/          ← Request DTO（record）+ Response DTO（class extends BaseResponse）
exception/    ← 自定义异常 + GlobalExceptionHandler
filter/       ← Servlet Filter（横切关注点）
config/       ← Spring 配置类
```

依赖方向：controller → service → repository，不可反向。

## Controller

- 只做：参数校验（`@Valid`）+ 委托 service + 从 request 取 requestId + 构造 Response
- 不写业务逻辑、不直接操作 repository
- 返回 `ResponseEntity<XxxResponse>`，XxxResponse 继承 `BaseResponse`

## Service

- 构造器注入（不用 `@Autowired` 字段注入）
- 日志用 SLF4J：`private static final Logger log = LoggerFactory.getLogger(Xxx.class)`
- 业务异常抛自定义 `XxxException(HttpStatus, errorCode, message)`
- 不返回 Entity 给 Controller，转换为 DTO 或内部 record

## Request DTO

- 用 Java record
- 字段上加 Jakarta Validation 注解（`@NotBlank` / `@Email` / `@Size` / `@Pattern`）
- message 用英文，面向开发者

## Response DTO

- 继承 `dto/response/BaseResponse`（自带 `request_id`）
- 字段用 `@JsonProperty("snake_case")` 显式声明序列化名
- 不依赖全局 naming strategy
- immutable：所有字段 `private final` + 构造器赋值

## 异常处理

- 自定义异常继承 `RuntimeException`，持有 `HttpStatus` + `errorCode`（snake_case）
- `GlobalExceptionHandler`（`@RestControllerAdvice`）统一路由异常到 `ErrorResponse`
- 不在 controller/service 中 catch 后手动构造 error response

## 横切关注点

- `RequestIdFilter`：每请求生成 UUID → request attribute + MDC
- `SensitiveFieldFilter`：响应中移除 password_hash / salt 等敏感字段
- 新增 Filter 时用 `@Order` 显式声明优先级
