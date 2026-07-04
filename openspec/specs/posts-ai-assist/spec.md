## ADDED Requirements

### Requirement: AI 生成标题

已认证用户 SHALL 可通过 `POST /api/ai/post-assist` with `action: "generate_title"` 让 AI 根据正文内容生成帖子标题。

#### Scenario: 生成标题成功

- **GIVEN** 用户已登录且持有有效 access_token
- **WHEN** 客户端提交 `POST /api/ai/post-assist` with body `{ "action": "generate_title", "content": "<markdown content>" }`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`（UUID v4）
- **AND** 响应体包含 `result` 字段，值为生成的标题文本
- **AND** 生成标题长度不超过 200 字符

#### Scenario: 正文为空时拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` with `action: "generate_title"` 且 `content` 为空
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"`

#### Scenario: 未认证被拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: AI 推荐标签

已认证用户 SHALL 可通过 `POST /api/ai/post-assist` with `action: "recommend_tags"` 让 AI 根据正文内容推荐 5-8 个标签。

#### Scenario: 推荐标签成功

- **GIVEN** 用户已登录且持有有效 access_token
- **WHEN** 客户端提交 `POST /api/ai/post-assist` with body `{ "action": "recommend_tags", "content": "<markdown content>", "title": "optional title" }`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`
- **AND** 响应体包含 `result` 字段，值为标签数组（5-8 个字符串）
- **AND** 每个标签长度不超过 30 字符

#### Scenario: 正文为空时拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` with `action: "recommend_tags"` 且 `content` 为空
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"`

#### Scenario: 未认证被拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: AI 润色正文

已认证用户 SHALL 可通过 `POST /api/ai/post-assist` with `action: "polish"` 让 AI 润色 Markdown 正文，返回润色后的完整内容。

#### Scenario: 润色成功

- **GIVEN** 用户已登录且持有有效 access_token
- **WHEN** 客户端提交 `POST /api/ai/post-assist` with body `{ "action": "polish", "content": "<markdown content>" }`
- **THEN** 返回 HTTP `200`
- **AND** 响应体包含 `request_id`
- **AND** 响应体包含 `result` 字段，值为润色后的完整 Markdown 文本
- **AND** 润色结果保持 Markdown 格式

#### Scenario: 正文为空时拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` with `action: "polish"` 且 `content` 为空
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"`

#### Scenario: 未认证被拒绝

- **WHEN** 客户端提交 `POST /api/ai/post-assist` 且未携带 Authorization header
- **THEN** 返回 HTTP `401 Unauthorized`

---

### Requirement: 无效 action 被拒绝

客户端提交不支持的 `action` 值 SHALL 返回校验错误。

#### Scenario: 无效 action

- **WHEN** 客户端提交 `POST /api/ai/post-assist` with `action: "invalid_action"`
- **THEN** 返回 HTTP `422 Unprocessable Entity`
- **AND** 响应体 `error_code: "validation_error"`

---

### Requirement: 前端 AI 辅助交互

前端 `PostForm` SHALL 提供三个 AI 辅助按钮，仅在正文内容不为空时可用，点击后显示 loading 状态并将结果直接填充到对应表单字段。

#### Scenario: 生成标题按钮

- **GIVEN** 正文输入框内容不为空
- **WHEN** 用户点击「✨ AI 生成标题」按钮
- **THEN** 按钮显示 loading 状态（Loader2 旋转图标）
- **AND** 请求成功后标题输入框填充 AI 生成的标题
- **AND** 按钮恢复可点击状态

#### Scenario: 推荐标签按钮

- **GIVEN** 正文输入框内容不为空
- **WHEN** 用户点击「🏷️ AI 推荐标签」按钮
- **THEN** 按钮显示 loading 状态
- **AND** 请求成功后标签输入区域填充 AI 推荐的标签列表
- **AND** 按钮恢复可点击状态

#### Scenario: 润色正文按钮

- **GIVEN** 正文输入框内容不为空
- **WHEN** 用户点击「✨ AI 润色」按钮
- **THEN** 按钮显示 loading 状态
- **AND** 请求成功后正文编辑器内容直接替换为 AI 润色后的文本
- **AND** 按钮恢复可点击状态

#### Scenario: 正文为空时按钮禁用

- **GIVEN** 正文输入框内容为空
- **WHEN** 用户查看 AI 辅助按钮
- **THEN** 三个 AI 辅助按钮均处于 disabled 状态

#### Scenario: AI 请求失败

- **GIVEN** 正文输入框内容不为空
- **WHEN** 用户点击任意 AI 辅助按钮且后端请求失败（网络错误或 5xx）
- **THEN** 按钮恢复可点击状态
- **AND** 显示错误提示（toast 或 inline error）
- **AND** 表单字段内容不变
