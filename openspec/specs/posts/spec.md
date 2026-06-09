## ADDED Requirements

### Requirement: 发布帖子

已认证用户 SHALL 可通过 `POST /api/posts` 发布新帖子，帖子内容使用 Markdown 格式，默认状态为 `PUBLISHED`。

#### Scenario: 发布成功（默认 PUBLISHED）

- **GIVEN** 用户已登录且持有有效 access_token
- **WHEN** 客户端提交 `POST /api/posts` with body `{ "title": "...", "content": "<markdown>", "cover_image": "https://...", "tags": ["tag1", "tag2"] }`
- **THEN** 返回 HTTP `201 Created`
- **AND** 响应体包含 `request_id`（UUID v4）
- **AND** 响应体包含 `id`（UUID v4，帖子 ID）
- **AND** 响应体包含 `status: "published"`
- **AND** 响应体包含 `created_at`（ISO 8601 时间戳）

#### Scenario: 发布为草稿

- **GIVEN** 用户已登录且持有有效 access_token
- **WHEN** 客户端提交 `POST /api/posts` with body `{ "title": "...", "content": "...", "status": "draft" }`
- **THEN** 返回 HTTP `201 Created`
- **AND** 响应体 `status: "draft"`

#### Scenario: 发布时字段校验失败

- **WHEN** 客户端提交 `POST /api/posts` with title 为空 或 content 为空
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"`
- **AND** `details` 包含具体字段错误描述

#### Scenario: 未认证发布被拒绝

- **WHEN** 客户端提交 `POST /api/posts` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: 编辑帖子

已认证用户 SHALL 可通过 `PUT /api/posts/{id}` 编辑自己发布的帖子。

#### Scenario: 编辑成功

- **GIVEN** 帖子存在且属于当前认证用户
- **WHEN** 客户端提交 `PUT /api/posts/{id}` with body `{ "title": "...", "content": "...", "cover_image": "...", "tags": [...], "status": "..." }`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含更新后的帖子完整数据
- **AND** `updated_at` 大于或等于 `created_at`

#### Scenario: 编辑他人帖子被拒绝

- **GIVEN** 帖子存在但不属于当前认证用户
- **WHEN** 客户端提交 `PUT /api/posts/{id}`
- **THEN** 返回 HTTP `403 Forbidden`
- **AND** 响应体 `error_code: "access_denied"`

#### Scenario: 编辑不存在的帖子

- **WHEN** 客户端提交 `PUT /api/posts/{id}` 且该 id 不存在（或已逻辑删除）
- **THEN** 返回 HTTP `404 Not Found`
- **AND** 响应体 `error_code: "not_found"`

#### Scenario: 未认证编辑被拒绝

- **WHEN** 客户端提交 `PUT /api/posts/{id}` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: 删除帖子

已认证用户 SHALL 可通过 `DELETE /api/posts/{id}` 逻辑删除自己发布的帖子。删除操作仅将 `deleted` 标记为 `true`，不物理移除数据。

#### Scenario: 删除成功

- **GIVEN** 帖子存在且属于当前认证用户
- **WHEN** 客户端提交 `DELETE /api/posts/{id}`
- **THEN** 返回 HTTP `204 No Content`
- **AND** 该帖子的 `deleted` 字段变为 `true`
- **AND** 后续 `GET /api/posts` 和 `GET /api/posts/{id}` 不再返回该帖子

#### Scenario: 删除他人帖子被拒绝

- **GIVEN** 帖子存在但不属于当前认证用户
- **WHEN** 客户端提交 `DELETE /api/posts/{id}`
- **THEN** 返回 HTTP `403 Forbidden`
- **AND** 响应体 `error_code: "access_denied"`
- **AND** 该帖子 `deleted` 字段保持 `false`

#### Scenario: 删除不存在的帖子

- **WHEN** 客户端提交 `DELETE /api/posts/{id}` 且该 id 不存在（或已逻辑删除）
- **THEN** 返回 HTTP `404 Not Found`
- **AND** 响应体 `error_code: "not_found"`

#### Scenario: 未认证删除被拒绝

- **WHEN** 客户端提交 `DELETE /api/posts/{id}` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: 帖子列表（分页）

任何人 SHALL 可通过 `GET /api/posts` 获取已发布帖子列表，无需认证。默认按 `created_at DESC` 排序。

#### Scenario: 获取默认第一页

- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`
- **AND** 响应体包含 `items`（帖子摘要数组，每项含 id / title / cover_image / tags / status / created_at / updated_at，不含 content 全文）
- **AND** `items` 按 `created_at` 降序排列
- **AND** 响应体包含 `total`（总记录数）
- **AND** 响应体包含 `page: 1`
- **AND** 响应体包含 `size: 20`

#### Scenario: 指定分页参数

- **WHEN** 客户端提交 `GET /api/posts?page=2&size=10`
- **THEN** 返回 HTTP `200`
- **AND** 响应体 `page: 2`，`size: 10`
- **AND** `items` 数量 ≤ 10

#### Scenario: 列表仅包含已发布帖子

- **GIVEN** 数据库中存在 status=published / draft / archived 的帖子
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 响应 `items` 中所有帖子的 `status` 均为 `"published"`

#### Scenario: 列表不包含已删除帖子

- **GIVEN** 数据库中存在已逻辑删除的帖子
- **WHEN** 客户端提交 `GET /api/posts`
- **THEN** 响应 `items` 中不包含已删除的帖子

#### Scenario: size 超过上限被截断

- **WHEN** 客户端提交 `GET /api/posts?size=200`
- **THEN** 返回 HTTP `200`
- **AND** 实际 `size` 不超过 100

---

### Requirement: 帖子详情

任何人 SHALL 可通过 `GET /api/posts/{id}` 获取单个已发布帖子详情（含完整 Markdown content），无需认证。

#### Scenario: 获取已发布帖子详情

- **GIVEN** 帖子存在且 status=published 且 deleted=false
- **WHEN** 客户端提交 `GET /api/posts/{id}`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含完整字段：id / title / content（Markdown 全文）/ cover_image / tags / status / created_at / updated_at / author_id

#### Scenario: 获取非已发布帖子返回 404

- **GIVEN** 帖子存在但 status=draft 或 archived
- **WHEN** 客户端提交 `GET /api/posts/{id}`
- **THEN** 返回 HTTP `404 Not Found`
- **AND** 响应体 `error_code: "not_found"`（不暴露帖子存在性）

#### Scenario: 获取不存在的帖子

- **WHEN** 客户端提交 `GET /api/posts/{id}` 且该 id 不存在或已逻辑删除
- **THEN** 返回 HTTP `404 Not Found`
- **AND** 响应体 `error_code: "not_found"`

---

### Requirement: 用户帖子列表

任何人 SHALL 可通过 `GET /api/users/{user_id}/posts` 获取指定用户的已发布帖子列表，无需认证。默认按 `created_at DESC` 排序。

#### Scenario: 获取某用户的帖子列表

- **GIVEN** 用户存在且有已发布帖子
- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts`
- **THEN** 返回 HTTP `200`
- **AND** 响应体格式与 `GET /api/posts` 一致（分页结构）
- **AND** `items` 仅包含该用户 status=published 且 deleted=false 的帖子
- **AND** 按 `created_at` 降序排列

#### Scenario: 用户不存在或无帖子

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts` 且 user_id 不存在或该用户无已发布帖子
- **THEN** 返回 HTTP `200`
- **AND** `items` 为空数组，`total: 0`

#### Scenario: 支持分页参数

- **WHEN** 客户端提交 `GET /api/users/{user_id}/posts?page=1&size=10`
- **THEN** 返回分页结果，格式与全局帖子列表一致

---

### Requirement: 帖子数据模型

Post 实体 SHALL 继承 `BaseEntity`，包含以下业务字段：

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| title | String | `@NotBlank`, `@Size(max = 200)` | 帖子标题 |
| content | String | `@NotBlank`, `@Size(max = 50000)`, `@Column(columnDefinition = "TEXT")` | Markdown 正文 |
| cover_image | String | `@Size(max = 2048)` | 封面图 URL，可为 null |
| tags | `List<String>` | JSON 列，`@Size(max = 10)`，each `@Size(max = 30)` | 标签列表，以 JSON 字符串存储 |
| status | PostStatus (enum) | `@Enumerated(STRING)`, 默认 `PUBLISHED` | 帖子状态 |
| author_id | UUID | `@NotNull`, `@Column(name = "author_id")` | 作者用户 ID |

#### PostStatus 枚举

| 值 | 含义 | 公开列表/详情可见 |
|---|---|---|
| `DRAFT` | 草稿，仅作者可见 | 否 |
| `PUBLISHED` | 已发布，公开可见 | 是 |
| `ARCHIVED` | 已归档，不参与列表 | 否 |

#### Scenario: Post 继承 BaseEntity 公共字段

- **WHEN** 创建 Post 实体并持久化
- **THEN** 自动填充 id（UUID）、created_at、updated_at
- **AND** deleted 默认为 false

#### Scenario: 逻辑删除

- **WHEN** 调用 `markDeleted()` 后持久化
- **THEN** deleted 字段为 true
- **AND** 常规查询（过滤 deleted=false）不再返回该记录

#### Scenario: tags 以 JSON 格式存储

- **WHEN** Post 实体包含 tags `["travel", "food", "culture"]` 并持久化
- **THEN** 数据库中 `tags` 列存储 JSON 字符串 `["travel","food","culture"]`
- **AND** 读取时还原为 `List<String>`

---

### Requirement: error_code 枚举

posts 模块 SHALL 使用以下 `error_code` 值，不允许出现枚举外的值：

| error_code | HTTP Status | 含义 |
|---|---|---|
| validation_error | 422 | 请求体字段格式不合法 |
| not_found | 404 | 帖子不存在或已删除 |
| access_denied | 403 | 无权操作该帖子（非作者） |

#### Scenario: 未知错误不暴露内部信息

- **WHEN** posts 模块发生未预期异常
- **THEN** 返回 HTTP 500
- **AND** 响应体 `error_code` 为 `"internal_error"`
- **AND** `message` 为通用描述，不包含堆栈或内部细节

---

### Requirement: 字段约束 — title

`title` 字段 SHALL 满足：1-200 字符、不能为纯空白。

#### Scenario: title 为空被拒绝

- **WHEN** 客户端提交 title 为 `""`
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.title` 包含错误描述

#### Scenario: title 超长被拒绝

- **WHEN** 客户端提交 title 长度为 201 字符
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.title` 包含错误描述

---

### Requirement: 字段约束 — content

`content` 字段 SHALL 为 Markdown 格式文本，1-50000 字符。

#### Scenario: content 为空被拒绝

- **WHEN** 客户端提交 content 为 `""`
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.content` 包含错误描述

#### Scenario: content 超长被拒绝

- **WHEN** 客户端提交 content 长度为 50001 字符
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.content` 包含错误描述

---

### Requirement: 字段约束 — tags

`tags` 字段 SHALL 为字符串列表，最多 10 个标签，每个标签 1-30 字符。

#### Scenario: 标签数量超限

- **WHEN** 客户端提交 11 个 tags
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.tags` 包含错误描述

#### Scenario: 单个标签过长

- **WHEN** 客户端提交某个 tag 长度为 31 字符
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.tags` 包含错误描述

#### Scenario: 空标签列表允许

- **WHEN** 客户端提交 tags 为 `[]`
- **THEN** 请求正常处理（tags 为可选字段）

---

### Requirement: 字段约束 — cover_image

`cover_image` 字段 SHALL 为合法 URL 字符串，最大 2048 字符，可为空。

#### Scenario: cover_image 非 URL 格式被拒绝

- **WHEN** 客户端提交 cover_image 为 `"not-a-url"`
- **THEN** 返回 HTTP 422, `error_code: "validation_error"`, `details.cover_image` 包含错误描述

#### Scenario: cover_image 为空时允许发布

- **WHEN** 客户端提交 cover_image 为 `null` 或省略该字段
- **THEN** 请求正常处理（cover_image 为可选字段）
