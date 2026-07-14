## Context

5 个核心 Service 类（TokenBlacklistService、VerificationCodeStore、AuthService、VoteService、PostService）目前零测试覆盖。它们被 Controller 层 mock，真实逻辑从未被验证。

## Goals / Non-Goals

**Goals:**

- 为 5 个 Service 建立 69 个单元测试，覆盖正常路径、异常路径、边界条件
- 纯内存类（TokenBlacklistService、VerificationCodeStore）用 JUnit 5 直接 new
- 有 DB 依赖的（AuthService、VoteService、PostService）用 Mockito mock Repository
- 测试运行快速（<2秒），不启动 Spring 容器

**Non-Goals:**

- 不修改生产代码（除非测试过程中发现真实 bug）
- 不测试 Repository 层（那是集成测试范畴）
- 不测试 Controller 层（已有测试覆盖）
- 不测试 Spring 依赖注入

## Decisions

### 1. 测试框架选择

**选择**：JUnit 5 + Mockito，不用 `@SpringBootTest`。

**理由**：
- 纯内存类不需要 Spring 容器
- 有依赖的类用 Mockito mock Repository，比启动容器快 10 倍
- 符合项目 TDD 规约——单元测试优先

### 2. 测试数据构造

**选择**：每个测试类内部创建 helper 方法（如 `createTestUser()`、`createTestPost()`）。

**理由**：
- 不同 Service 需要的测试数据字段不同
- 避免跨测试类耦合
- 比 Builder 模式更直观

### 3. 时间敏感测试

**选择**：VerificationCodeStore 的过期测试用 `ttl=0` 构造"立即过期"的验证码。

**理由**：
- 比 `Thread.sleep` 快
- 比手动构造 Instant 更贴近真实使用路径

### 4. AuthService 复杂依赖

**选择**：mock 6 个依赖（UserRepository、PasswordEncoder、JwtService、TokenBlacklistService、VerificationCodeStore、RateLimitService）。

**理由**：
- AuthService 是业务编排层，不直接操作 DB
- 所有外部行为都通过依赖注入，易于 mock

### 5. PostService slug 测试

**选择**：直接测试 `createPost` 生成的 slug 格式，不测试私有方法 `generateSlug`。

**理由**：
- 通过公开方法间接测试
- 避免反射调用私有方法

## Risks / Trade-offs

- **[风险] Mockito mock 行为与实际不符**：mock 的 Repository 行为可能和真实 JPA 有差异。→ 缓解：只 mock 基本行为（findById/save/existsBy），不 mock 复杂查询
- **[风险] 时间敏感测试在 CI 慢机器上失败**：VerificationCodeStore 的过期测试。→ 缓解：用 `ttl=0` 而非短时间 sleep
- **[取舍] 不测试并发安全性**：TokenBlacklistService 和 VerificationCodeStore 用 ConcurrentHashMap，但不测试并发场景。→ 可接受，并发测试属于集成测试范畴
- **[取舍] PostService 游标分页测试简化**：只测试 cursor 模式的基本行为，不测试所有排序组合。→ 可接受，避免测试数量爆炸
