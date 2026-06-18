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
