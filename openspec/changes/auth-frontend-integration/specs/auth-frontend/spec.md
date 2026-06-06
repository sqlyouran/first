## MODIFIED Requirements

### Requirement: Auth Store（Zustand）

前端使用 Zustand store 管理认证状态，包含 token、用户信息、登录/登出动作、会话初始化。

#### Scenario: 登录后 store 更新

- **WHEN** 登录接口返回成功
- **THEN** store 中 `accessToken` 被设为返回的 token 值
- **AND** `isAuthenticated` 变为 `true`

#### Scenario: 登出清空 store

- **WHEN** 调用 store 的 `logout` action
- **THEN** `accessToken` 被清空
- **AND** `user` 被清空
- **AND** `isAuthenticated` 变为 `false`
- **AND** 调用 `POST /api/auth/logout` 通知后端

#### Scenario: fetchMe 写入用户信息

- **WHEN** 调用 store 的 `fetchMe` action 且 accessToken 有效
- **THEN** 调用 `GET /api/auth/me` 获取用户信息
- **AND** store 中 `user` 设为 `{ id, email, state, created_at }`

#### Scenario: initialize 恢复会话

- **WHEN** AuthProvider 调用 store 的 `initialize` action
- **THEN** 尝试调用 `/api/auth/refresh` 获取新 accessToken
- **AND** 成功后调用 `fetchMe()` 获取用户信息
- **AND** 无论成功失败，`isInitialized` 设为 `true`

---

### Requirement: 注册页面（两步流程）

用户在 `/register` 页面完成两步注册：Step 1 输入邮箱发送验证码，Step 2 输入验证码 + 密码完成注册。

#### Scenario: Step 1——发送验证码成功

- **WHEN** 用户输入有效邮箱并点击「发送验证码」
- **THEN** 系统调用 `POST /api/auth/send-code`
- **AND** 收到 200 响应后，页面切换到 Step 2
- **AND** 显示倒计时（60s）防止重复发送

#### Scenario: Step 1——发送验证码被限流

- **WHEN** 后端返回 HTTP 429
- **THEN** 页面显示「请求过于频繁，请稍后重试」

#### Scenario: Step 2——注册成功

- **WHEN** 用户输入验证码和密码并提交
- **THEN** 系统调用 `POST /api/auth/register`
- **AND** 收到 201 响应后，页面跳转到 `/login` 并显示「注册成功，请登录」

#### Scenario: Step 2——验证码错误

- **WHEN** 后端返回 HTTP 400 且 `error_code` 为 `invalid_code`
- **THEN** 页面显示「验证码错误，请重新输入」

#### Scenario: Step 2——验证码过期

- **WHEN** 后端返回 HTTP 400 且 `error_code` 为 `expired_code`
- **THEN** 页面显示「验证码已过期，请重新发送」
- **AND** 提供「重新发送」按钮回到 Step 1

#### Scenario: Step 2——邮箱已注册

- **WHEN** 后端返回 HTTP 409 且 `error_code` 为 `email_already_registered`
- **THEN** 页面显示「该邮箱已注册，请直接登录」
- **AND** 提供「去登录」链接跳转到 `/login`

#### Scenario: Step 2——注册被限流

- **WHEN** 后端返回 HTTP 429
- **THEN** 页面显示「请求过于频繁，请稍后重试」

#### Scenario: 注册表单前端校验

- **WHEN** 用户提交时 email 格式无效、验证码为空、或密码长度不足 8 位
- **THEN** 显示行内校验错误，不发起网络请求

#### Scenario: 提交时 Loading 状态

- **WHEN** 用户点击「发送验证码」或「注册」按钮且前端校验通过
- **THEN** 对应按钮进入 loading 状态（disabled + spinner）
- **AND** 请求完成后恢复按钮可点击状态

#### Scenario: 导航到登录页

- **WHEN** 用户点击注册页底部的「已有账号？去登录」链接
- **THEN** 页面跳转到 `/login`
