## ADDED Requirements

### Requirement: 查看自己的完整资料

系统 SHALL 提供 `GET /api/users/me/profile` 端点，需 JWT 认证，返回当前用户的完整个人资料。

#### Scenario: 已登录用户查看资料

- **WHEN** 已登录用户 GET `/api/users/me/profile`
- **THEN** 返回 HTTP 200，响应体包含 `{ request_id, id, username, nickname, avatar_url, bio, interest_tags, email, created_at }`

#### Scenario: 资料未填写

- **WHEN** 用户尚未填写资料（所有 profile 字段为 null）
- **THEN** 返回 HTTP 200，`username`/`nickname`/`avatar_url`/`bio`/`interest_tags` 均为 null

#### Scenario: 未认证

- **WHEN** 请求未携带有效 JWT
- **THEN** 返回 HTTP 401

---

### Requirement: 编辑个人资料

系统 SHALL 提供 `PUT /api/users/me/profile` 端点，需 JWT 认证，更新当前用户的个人资料。

#### Scenario: 首次设置资料（含 username）

- **WHEN** 用户首次编辑资料，提交 `{ username: "traveler01", nickname: "Alice", avatar_url: "https://...", bio: "Love hiking", interest_tags: ["Hiking", "Street Food"] }`
- **THEN** 返回 HTTP 200，资料更新成功
- **AND** username 保存为小写

#### Scenario: username 已被占用

- **WHEN** 提交的 username 已被其他用户使用
- **THEN** 返回 HTTP 409，`error_code: "username_taken"`

#### Scenario: username 格式无效

- **WHEN** 提交的 username 不匹配 `^[a-zA-Z0-9_-]{3,20}$`
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`，`details.username` 包含具体错误

#### Scenario: 尝试修改已设置的 username

- **WHEN** 用户已有 username，提交新的 username 值
- **THEN** 后端忽略 username 字段（不更新），其余字段正常更新
- **AND** 返回 HTTP 200

#### Scenario: nickname 校验失败

- **WHEN** nickname 为空/纯空格/少于 2 字符/超过 30 字符/包含 `<>"` 字符
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`，`details.nickname` 包含具体错误

#### Scenario: bio 超长

- **WHEN** bio 超过 500 字符
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`，`details.bio` 包含具体错误

#### Scenario: interest_tags 校验

- **WHEN** interest_tags 包含不在预定义列表中的标签，或超过 10 个
- **THEN** 返回 HTTP 422，`error_code: "validation_error"`，`details.interest_tags` 包含具体错误

#### Scenario: 可选字段为空

- **WHEN** 提交的 `avatar_url`/`bio`/`interest_tags` 为 null 或空
- **THEN** 对应字段清空为 null，返回 HTTP 200

---

### Requirement: 查看他人公开资料

系统 SHALL 提供 `GET /api/users/{username}` 端点，公开访问，返回用户的公开资料。

#### Scenario: 用户存在

- **WHEN** GET `/api/users/{username}`，username 对应一个 active 用户
- **THEN** 返回 HTTP 200，响应体包含 `{ request_id, id, username, nickname, avatar_url, bio, interest_tags, created_at }`
- **AND** 不包含 email 字段

#### Scenario: 用户不存在

- **WHEN** username 不对应任何用户
- **THEN** 返回 HTTP 404，`error_code: "not_found"`

#### Scenario: 用户已删除

- **WHEN** 用户 state = deleted
- **THEN** 返回 HTTP 404（对外表现与不存在一致）

---

### Requirement: 获取预定义兴趣标签列表

系统 SHALL 提供 `GET /api/users/interest-tags` 端点，公开访问，返回所有可选兴趣标签。

#### Scenario: 获取标签列表

- **WHEN** GET `/api/users/interest-tags`
- **THEN** 返回 HTTP 200，响应体包含 `{ request_id, tags: [{ name: "Hiking", category: "outdoors" }, ...] }`
- **AND** 包含全部 24 个预定义标签

---

### Requirement: UserEntity 新增 profile 字段

系统 SHALL 在 `UserEntity` 中新增以下字段：`username`(VARCHAR 20, UNIQUE, NULLABLE)、`nickname`(VARCHAR 30, NULLABLE)、`avatar_url`(VARCHAR 2048, NULLABLE)、`bio`(VARCHAR 500, NULLABLE)、`interest_tags`(TEXT, NULLABLE, JSON array)。

#### Scenario: 字段持久化

- **WHEN** 用户保存资料，所有字段均有效
- **THEN** 数据库正确写入所有字段，`interest_tags` 以 JSON 数组格式存储

#### Scenario: username 唯一约束

- **WHEN** 两个用户尝试使用相同 username
- **THEN** 数据库 UNIQUE 约束阻止第二个写入

## MODIFIED Requirements

### Requirement: 他人公开资料页

他人公开资料页 `/users/[username]` SHALL 在已登录用户访问时显示 "Send Message" 按钮，点击后跳转至与该用户的会话（已有则复用，无则新建）。

#### Scenario: 已登录用户查看他人资料

- **WHEN** 已登录用户访问 `/users/{username}`
- **THEN** 页面显示 "Send Message" 按钮

#### Scenario: 未登录用户查看他人资料

- **WHEN** 未登录用户访问 `/users/{username}`
- **THEN** 页面不显示 "Send Message" 按钮

#### Scenario: 点击 Send Message

- **WHEN** 已登录用户点击 "Send Message"
- **THEN** 调用 `POST /api/conversations` 查找或创建会话，跳转 `/messages/{conversation_id}`
