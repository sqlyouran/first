## Context

后端当前使用 H2 内存库（`jdbc:h2:mem:wanderchina;DB_CLOSE_DELAY=-1`），`ddl-auto: create-drop`，每次重启丢数据。已有 2 个 Entity（`UserEntity` + `PostEntity`）继承 `BaseEntity`，使用 UUID 主键 + `@Column(name = "snake_case")` 显式声明。

现需切换到本地 MySQL 8，保留数据并增量同步 schema。

约束：
- Spring Boot 3.3.5 + Hibernate 6.x + JPA
- 遵循 database-conventions：UUID 主键、snake_case 列名、Instant 时间类型
- 测试直连本地 MySQL（不保留 H2）

## Goals / Non-Goals

**Goals:**

- 将 datasource 从 H2 切到 MySQL 8（localhost:3306/wanderchina）
- UUID 存储格式：CHAR(36)（人类可读）
- ddl-auto: update（只增不删，保留数据）
- 密码通过环境变量 `${MYSQL_PASSWORD:123456}` 注入
- 移除 H2 所有配置与依赖

**Non-Goals:**

- 不引入 Flyway / Liquibase（后续 change）
- 不改 Entity / Repository / Service / Controller 业务代码
- 不配 CI MySQL（后续需要时再加）
- 不做 H2 → MySQL 数据迁移（当前 H2 无持久数据）

## Decisions

### D1: UUID 存储格式 — CHAR(36)

通过 Hibernate 6 属性配置全局生效：

```yaml
spring:
  jpa:
    properties:
      hibernate:
        type:
          preferred_uuid_jdbc_type: CHAR
```

**理由**：开发阶段优先可调试性。DBeaver / MySQL CLI 可直接看到 UUID 字符串，WHERE 条件可直接粘贴。性能差异在当前数据量（< 万条）可忽略。

### D2: 连接参数

```
jdbc:mysql://localhost:3306/wanderchina?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=utf8mb4
```

| 参数 | 理由 |
|------|------|
| `useSSL=false` | 本地开发无需 SSL |
| `allowPublicKeyRetrieval=true` | MySQL 8 默认 caching_sha2_password 需要 |
| `serverTimezone=UTC` | 与 `Instant` 时间类型对齐 |
| `characterEncoding=utf8mb4` | 支持 emoji 等 4-byte 字符 |

### D3: 密码管理 — 环境变量 + 默认值

```yaml
password: ${MYSQL_PASSWORD:123456}
```

**理由**：本地开发写默认值减少配置步骤；生产环境通过环境变量注入真实密码。

### D4: 测试策略 — 直连本地 MySQL

不保留 H2 作为 test scope。所有测试（含 `@DataJpaTest` / `@WebMvcTest` + mock）直连同一 MySQL 实例。

**理由**：
- 避免 H2 / MySQL 方言差异导致"测试绿了但实际跑不了"
- 当前阶段只有本地开发，CI 配置后续再处理
- 已有 `@WebMvcTest` 不需要真实 DB（mock service 层）

**权衡**：`@DataJpaTest` 测试需要 MySQL 启动，略增 setup 成本。

### D5: DDL 策略 — update

```yaml
spring.jpa.hibernate.ddl-auto: update
```

**理由**：
- `create-drop` → 每次丢数据，不适合 MySQL 持久化场景
- `update` → Hibernate 只新增表/列，不删已有列，适合开发阶段
- 后续引入 Flyway 后再改为 `validate`

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| 测试必须依赖 MySQL 运行 | 本地开发始终需要 MySQL 运行；`@WebMvcTest` 不需要真实 DB |
| `ddl-auto: update` 不能删列/改类型 | 当前无此需求；后续 Flyway 接管 |
| CHAR(36) 比 BINARY(16) 占空间多 | 数据量小，可忽略；后续迁移 PG 时可统一为 native UUID |
| MySQL 8 的 `caching_sha2_password` 可能被防火墙阻断 | 仅本地连接，不经过网络 |
