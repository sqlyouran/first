## ADDED Requirements

### Requirement: 登录页面

用户在 `/login` 页面输入 email + password 提交登录，前端根据后端响应展示对应结果。

#### Scenario: 登录成功跳转首页

- **WHEN** 用户在登录表单输入正确的 email 和 password 并提交
- **THEN** 系统调用 `POST /api/auth/login`
- **AND** 收到 200 响应后，将 access_token 存入 auth store
- **AND** 页面跳转到首页 `/`

#### Scenario: 登录失败——凭据错误

- **WHEN** 后端返回 HTTP 401
- **THEN** 页面显示错误提示「邮箱或密码错误」
- **AND** 不区分邮箱不存在与密码错误

#### Scenario: 登录失败——账户锁定

- **WHEN** 后端返回 HTTP 423 并携带 `locked_until`
- **THEN** 页面显示「账户已锁定，请于 {time} 后重试」

#### Scenario: 登录失败——邮箱未验证

- **WHEN** 后端返回 HTTP 403 且 `error_code` 为 `email_unverified`
- **THEN** 页面显示「邮箱未验证，请先完成验证」
- **AND** 本期不处理 `resend_available` 重发交互（属于邮箱变更后续 scope）

#### Scenario: 登录失败——IP 限流

- **WHEN** 后端返回 HTTP 429 并携带 `Retry-After` header
- **THEN** 页面显示「请求过于频繁，请稍后重试」

#### Scenario: 表单前端校验

- **WHEN** 用户提交表单时 email 格式无效或 password 为空
- **THEN** 显示行内校验错误，不发起网络请求

#### Scenario: 提交时 Loading 状态

- **WHEN** 用户点击登录按钮且前端校验通过
- **THEN** 按钮进入 loading 状态（disabled + spinner）
- **AND** 请求完成（成功或失败）后恢复按钮可点击状态

#### Scenario: 导航到注册页

- **WHEN** 用户点击登录页底部的「没有账号？去注册」链接
- **THEN** 页面跳转到 `/register`

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

---

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

### Requirement: Mock API 层

提供与 auth spec 一致的 mock 函数，模拟后端各种响应场景，确保前端所有错误态均可被测试驱动。

#### Scenario: mock login——成功

- **WHEN** 调用 mock login 函数且凭据匹配预设用户（email: `test@example.com`, password: `password123`）
- **THEN** 返回 status 200 和 `{ access_token: "<jwt-like-string>" }`

#### Scenario: mock login——凭据错误

- **WHEN** 调用 mock login 函数且凭据不匹配预设用户
- **THEN** 返回 status 401 和 `{ error: "invalid_credentials" }`

#### Scenario: mock login——账户锁定

- **WHEN** 调用 mock login 函数且 email 为预设锁定用户（`locked@example.com`）
- **THEN** 返回 status 423 和 `{ locked_until: "<future-timestamp>" }`

#### Scenario: mock login——邮箱未验证

- **WHEN** 调用 mock login 函数且 email 为预设未验证用户（`unverified@example.com`）
- **THEN** 返回 status 403 和 `{ error_code: "email_unverified" }`

#### Scenario: mock login——IP 限流

- **WHEN** 调用 mock login 函数且 email 为预设限流触发用户（`ratelimit@example.com`）
- **THEN** 返回 status 429 并携带 `Retry-After: 900` header

#### Scenario: mock send-code——成功

- **WHEN** 调用 mock send-code 函数
- **THEN** 始终返回 status 200（反枚举，与 spec 一致）

#### Scenario: mock send-code——限流

- **WHEN** 调用 mock send-code 函数且 email 为预设限流触发邮箱（`ratelimit@example.com`）
- **THEN** 返回 status 429 并携带 `Retry-After` header

#### Scenario: mock register——成功

- **WHEN** 调用 mock register 函数且验证码为预设正确值（`123456`）
- **THEN** 返回 status 201

#### Scenario: mock register——验证码错误

- **WHEN** 调用 mock register 函数且验证码不匹配预设正确值
- **THEN** 返回 status 400 和 `{ error_code: "invalid_code" }`

#### Scenario: mock register——验证码过期

- **WHEN** 调用 mock register 函数且验证码为预设过期值（`000000`）
- **THEN** 返回 status 400 和 `{ error_code: "expired_code" }`

#### Scenario: mock register——限流

- **WHEN** 调用 mock register 函数且 email 为预设限流触发邮箱（`ratelimit@example.com`）
- **THEN** 返回 status 429 并携带 `Retry-After` header
