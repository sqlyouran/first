---
trigger: always_on
---
# API 规约

定义前后端接口契约格式。以下为 SHOULD 级约定。

## URL 结构

- 格式：`/api/<module>/<action>`
- 示例：`/api/auth/login`、`/api/auth/send-code`
- action 用 kebab-case
- 资源型 URL（后续）：`/api/<module>/<resource>` + HTTP 动词语义

## 成功响应格式

所有成功响应包含 `request_id` + 业务字段：

```json
{
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "access_token": "eyJhbG...",
  "expires_in": 1800
}
```

- `request_id`：由 `RequestIdFilter` 生成，用于日志追踪
- 业务字段用 **snake_case**
- HTTP 状态码：200（查询/操作成功）/ 201（创建成功）/ 204（无内容）

## 错误响应格式

```json
{
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "error_code": "invalid_credentials",
  "message": "Email or password is incorrect",
  "details": {
    "password": "Password must be between 8 and 72 characters"
  }
}
```

- `error_code`：语义化 snake_case 标识符，前端用于条件判断
- `message`：人类可读英文描述
- `details`：可选，字段级错误（校验失败时）

## 错误码规范

| HTTP Status | 场景 | error_code 示例 |
|---|---|---|
| 401 | 认证失败 | `invalid_credentials` / `token_expired` |
| 403 | 无权限 | `access_denied` |
| 404 | 资源不存在 | `not_found` |
| 409 | 业务冲突 | `email_already_registered` |
| 422 | 校验失败 | `validation_error` |
| 429 | 限流 | `rate_limited` |
| 500 | 未知错误 | `internal_error` |

## 分页响应格式

列表接口 SHOULD 返回以下结构：

```json
{
  "request_id": "...",
  "items": [...],
  "total": 100,
  "page": 1,
  "size": 20
}
```

- `items`：当前页数据数组
- `total`：总记录数
- `page`：当前页码（从 1 开始）
- `size`：每页条数

请求参数：`?page=1&size=20`（默认 page=1, size=20, 最大 size=100）

## 前端 API 客户端约定

- 统一用 `ApiResponse<T>` 泛型：`{ status, data?, error? }`
- 每个函数处理三类异常：正常解析 / 5xx server error / network error
- error 结构对齐后端 `ErrorResponse`：`ApiError { request_id, error_code, message, details? }`
- 类型定义由 `openapi-typescript` 从后端 schema 生成（`lib/api/schema.d.ts`）

## 序列化约定

- 后端 JSON 字段名：**snake_case**（通过 `@JsonProperty` 显式声明）
- 前端 TypeScript 接口字段名：与 JSON 一致使用 **snake_case**（保持契约一致性）
- 不做 camelCase 转换层（减少一层映射复杂度）
