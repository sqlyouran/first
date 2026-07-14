## Context

JwtService 是认证模块的纯工具类，构造器注入 3 个配置值（secret、access-token-expiry、refresh-token-expiry），提供 token 生成与解析方法，无状态、无外部依赖。当前其他测试通过 Mockito mock JwtService，其真实行为从未被直接验证。

## Goals / Non-Goals

**Goals:**

- 为 JwtService 的 5 个公开方法建立完整的行为契约测试
- 测试运行快速（<1秒），不启动 Spring 容器
- 测试可读性强，每个测试方法名清晰表达意图

**Non-Goals:**

- 不测试 AuthService（黑名单、刷新逻辑在 AuthService 层，不在 JwtService）
- 不测试 TokenBlacklistService
- 不修改 JwtService 生产代码（除非测试过程中发现真实 bug）
- 不测试 `@Value` 注入机制（那是 Spring 的职责）

## Decisions

### 1. 测试框架：纯 JUnit 5 + AssertJ

**选择**：不用 `@SpringBootTest`，直接 `new JwtService(secret, accessExpiry, refreshExpiry)`。

**理由**：
- JwtService 构造器只接收原始值，无需 Spring 容器
- 测试速度快一个数量级（毫秒 vs 秒级启动）
- 符合项目 TDD 规约——单元测试优先于集成测试

**备选**：`@SpringBootTest` 集成测试——被否决，过重且无法测试边界条件（如 secret 太短）。

### 2. 断言库：JUnit 5 原生 Assertions

**选择**：使用 `assertEquals` / `assertTrue` / `assertThrows` 等 JUnit 5 原生断言。

**理由**：项目已有 JUnit 5 依赖，不额外引入 AssertJ 减少依赖面。

### 3. 测试数据构造：手动 new UserEntity

**选择**：创建辅助方法 `createTestUser(UUID id, String email, UserEntity.State state)` 手动赋值。

**理由**：不需要持久化，不需要 Repository，直接 setId/setEmail/setState 即可。

### 4. 时间断言：允许 ±2 秒误差

**选择**：验证 `exp - iat` 的 Duration 与配置的 expiry 值偏差在 2 秒内。

**理由**：token 生成到解析之间存在毫秒级时间差，但 JWT 精度为秒，±2 秒足够宽容。

### 5. 过期 token 测试：expiry=0 构造法

**选择**：创建一个 `expiry=0` 的 JwtService 实例来生成"立即过期"的 token。

**理由**：比手动构造 JWT 字符串更简洁、更贴近真实使用路径。

## Risks / Trade-offs

- **[风险] secret 长度限制**：HMAC-SHA256 要求 key ≥ 32 字节。测试需确保 secret 足够长；"secret 太短"作为独立的异常路径测试用例。→ 缓解：测试 secret 固定为 48 字符字符串。
- **[风险] 时间敏感性**：测试在 CI 慢机器上可能因时间差导致 exp 断言失败。→ 缓解：±2 秒容差 + 使用 Duration 而非精确时间戳对比。
- **[取舍] 不测试 HMAC 算法细节**：不验证具体用了哪种签名算法，只验证"同一个 key 签的能解、不同 key 签的不能解"。→ 可接受，算法选择是 JJWT 库的内部实现。
