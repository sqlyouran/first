## Why

JwtService 是认证体系的核心工具类，负责 access/refresh token 的生成与解析，但当前没有任何专属单元测试。其他模块（AuthService、Controller 层）的测试中仅以 mock 方式引用 JwtService，其真实行为（签名正确性、claims 完整性、过期计算、异常容错）从未被验证。补齐测试可以防止未来重构时引入回归 bug，也为新人理解 token 结构提供活文档。

## What Changes

- 新增 `JwtServiceTest.java`，纯 JUnit 5 单元测试（不依赖 Spring 容器）
- 覆盖 18 个测试用例：构造器校验、access token 生成与 claims 验证、refresh token 生成与 jti 唯一性、parseToken 正常/异常路径（签名错误、过期、非法格式、null、空串、篡改）、getter 方法

## Capabilities

### New Capabilities

- `jwt-service-tests`: JwtService 单元测试套件，验证 token 生成、解析、异常处理的正确性

### Modified Capabilities

（无——本次不修改任何业务行为，仅补充测试）

## Impact

- **新增文件**：`backend/src/test/java/com/mooc/app/service/JwtServiceTest.java`
- **依赖**：仅使用已有依赖（JUnit 5 + JJWT），无需新增 Maven 依赖
- **受影响代码**：无生产代码变更，不影响 API、数据库或其他模块
