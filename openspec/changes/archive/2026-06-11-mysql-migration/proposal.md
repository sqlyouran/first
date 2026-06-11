## Why

当前后端使用 H2 内存库（`create-drop`），每次重启数据丢失，无法进行真实的数据持久化开发与验证。项目已进入 posts 模块阶段，需要稳定的本地数据库来保存开发数据、验证 schema 演进。

切换到本地 MySQL 8 后：
- 数据重启不丢失，可积累测试数据
- `ddl-auto: update` 支持增量 schema 同步
- 与生产目标（PostgreSQL / MySQL）的 SQL 方言更接近

## What Changes

- `pom.xml`：移除 `com.h2database:h2` 依赖，新增 `com.mysql:mysql-connector-j`（runtime scope）
- `application.yml`：datasource 切换为 MySQL 8 连接串 + 环境变量密码 + UUID 存储为 CHAR(36) + 移除 h2.console 配置
- 外部操作：创建 `wanderchina` 数据库（utf8mb4_unicode_ci）

## Capabilities

### New Capabilities

（无新 capability——本次为基础设施变更，不新增业务功能）

### Modified Capabilities

- 所有现有 capability（auth / posts）数据持久化从 H2 内存切换到 MySQL 8 本地实例

## Impact

- **后端代码**：仅 `pom.xml` + `application.yml` 两文件变更，Entity / Repository / Service / Controller 不动
- **数据库**：需本地运行 MySQL 8 并创建 `wanderchina` 库
- **测试**：测试直连本地 MySQL（方案 C），跑测试前需 MySQL 启动
- **前端**：不影响
- **CI**：后续如配 CI 需加 MySQL service container
