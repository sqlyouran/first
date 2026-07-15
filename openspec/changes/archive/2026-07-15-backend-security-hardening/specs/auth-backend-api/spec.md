## MODIFIED Requirements

### Requirement: 敏感字段全局过滤

全局 Response Filter SHALL 确保任何 JSON 响应中不出现 `password_hash`、`salt`、`verification_code` 字段，即使 DTO 映射遗漏。

此外，`UserEntity.passwordHash` 字段 SHALL 标注 `@JsonIgnore`，作为字段级双保险防护。

#### Scenario: 即使 DTO 意外包含敏感字段也被过滤

- **WHEN** 某个端点的响应 DTO 意外包含 `password_hash` 字段
- **THEN** 最终 HTTP 响应的 JSON 中不存在 `password_hash` 键

#### Scenario: 正常字段不受影响

- **WHEN** 响应包含 `email`、`state`、`created_at` 等正常字段
- **THEN** 这些字段正常出现在最终响应中

#### Scenario: UserEntity 序列化时 passwordHash 被忽略

- **WHEN** Jackson 序列化 `UserEntity` 对象
- **THEN** 输出 JSON 不包含 `passwordHash` 或 `password_hash` 字段

---

### Requirement: 验证码存储迁移到 Redis

`VerificationCodeStore` SHALL 使用 Redis 替代内存 `ConcurrentHashMap` 存储验证码。验证码的 key 为邮箱（lowercase），value 为验证码字符串，TTL 为配置值（默认 600 秒）。Redis 不可用时 SHALL 降级到内存存储并记录 warn 日志。

#### Scenario: 验证码存入 Redis

- **WHEN** `sendCode` 生成验证码并调用 `codeStore.save(email, code, 600)`
- **THEN** Redis 中存储该 key-value 对，TTL 为 600 秒

#### Scenario: 服务重启后验证码仍有效

- **GIVEN** 验证码已存入 Redis
- **WHEN** 应用重启
- **THEN** 重启后 `codeStore.getCode(email)` 仍返回之前存储的验证码（Redis 未过期）

#### Scenario: Redis 不可用时降级到内存

- **GIVEN** Redis 连接失败
- **WHEN** `codeStore.save(email, code, 600)` 被调用
- **THEN** 验证码存入内存 Map，应用不崩溃，记录 warn 日志

---

### Requirement: 限流计数器迁移到 Redis

`RateLimitService` SHALL 使用 Redis sorted set 实现滑动窗口限流。每个限流 key 对应一个 sorted set，score 为请求时间戳。Redis 不可用时 SHALL 降级到内存存储。

#### Scenario: 限流计数持久化到 Redis

- **WHEN** `isRateLimited("login:ip:1.2.3.4", 20, 3600)` 被调用
- **THEN** Redis 中 `login:ip:1.2.3.4` sorted set 新增一条记录

#### Scenario: 服务重启后限流计数保留

- **GIVEN** 某 IP 已触发 15 次登录请求（限制 20 次）
- **WHEN** 应用重启
- **THEN** 重启后该 IP 的限流计数仍为 15，再请求 5 次后被限流

#### Scenario: Redis 不可用时降级到内存

- **GIVEN** Redis 连接失败
- **WHEN** `isRateLimited` 被调用
- **THEN** 使用内存 `ConcurrentHashMap` 计数，应用不崩溃，记录 warn 日志

---

### Requirement: 验证码不写入 info 日志

`AuthService.sendCode()` SHALL 不再在 info 级别记录验证码明文。验证码仅在 debug 级别记录，且不包含邮箱地址。

#### Scenario: info 日志不包含验证码

- **GIVEN** 日志级别为 INFO
- **WHEN** `sendCode` 被调用
- **THEN** 日志中不出现验证码值

#### Scenario: debug 日志可记录验证码（不含邮箱）

- **GIVEN** 日志级别为 DEBUG
- **WHEN** `sendCode` 被调用
- **THEN** 日志记录验证码已生成，但不包含邮箱地址和验证码值的组合
