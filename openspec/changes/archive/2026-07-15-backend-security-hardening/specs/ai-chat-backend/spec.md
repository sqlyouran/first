## ADDED Requirements

### Requirement: AI 聊天接口匿名限流

`AiChatController` 的 `/api/ai/chat` 和 `/api/ai/conversations` 接口 SHALL 实施匿名限流：未登录用户每 IP 每天最多 20 次调用，已登录用户不限流（由 `AuthUtil.optionalUserId` 判断）。

#### Scenario: 匿名用户超过每日限额

- **GIVEN** 未登录用户从 IP `1.2.3.4` 当天已调用 20 次 `/api/ai/chat`
- **WHEN** 该用户再次请求 `/api/ai/chat`
- **THEN** HTTP 429，响应 `error_code: "rate_limited"`

#### Scenario: 已登录用户不受匿名限流限制

- **GIVEN** 已登录用户从同一 IP 当天已调用 25 次 `/api/ai/chat`
- **WHEN** 该用户请求 `/api/ai/chat`（携带有效 Token）
- **THEN** 正常处理，不触发限流

#### Scenario: 新 IP 首次调用

- **GIVEN** IP `5.6.7.8` 当天未调用过 AI 接口
- **WHEN** 请求 `/api/ai/chat`
- **THEN** 正常处理
