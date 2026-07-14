## Why

认证和帖子模块是全站最核心的业务逻辑，但目前这 5 个 Service 类完全没有单元测试覆盖。它们依赖的 Controller 层测试都用 Mockito mock 了这些 Service，导致真实业务逻辑（如登录锁定、token 刷新、投票切换、slug 生成）从未被直接验证。这次批量补齐 69 个测试用例，覆盖正常路径、异常路径和边界条件，防止重构时引入回归 bug。

## What Changes

- 新增 `TokenBlacklistServiceTest.java`（5 个测试）：纯内存集合的 add/isBlacklisted 操作
- 新增 `VerificationCodeStoreTest.java`（10 个测试）：内存 KV 存储 + 过期自动清理 + 大小写不敏感
- 新增 `AuthServiceTest.java`（22 个测试）：认证全流程（sendCode/register/login/refresh/logout/getMe/deleteMe），含限流、账户锁定、验证码校验、密码错误计数
- 新增 `VoteServiceTest.java`（12 个测试）：投票三种场景（新建/取消/切换）+ removeVote + getVoteStats
- 新增 `PostServiceTest.java`（20 个测试）：帖子 CRUD + slug 生成 + 3 种排序 + 游标分页 + 权限校验

## Capabilities

### New Capabilities

- `service-tests-batch1`: 5 个核心 Service 类的单元测试套件，覆盖认证、投票、帖子模块的关键业务逻辑

### Modified Capabilities

（无——本次不修改任何业务行为，仅补充测试）

## Impact

- **新增文件**：5 个测试文件在 `backend/src/test/java/com/mooc/app/service/`
- **依赖**：仅使用已有依赖（JUnit 5 + Mockito），无需新增 Maven 依赖
- **受影响代码**：无生产代码变更，不影响 API、数据库或其他模块
