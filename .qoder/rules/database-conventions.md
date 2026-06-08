---
trigger: always_on
---
# 数据库规约

后端使用 JPA (Hibernate) + PostgreSQL（开发阶段 H2 内存库）。以下为 SHOULD 级约定。

## BaseEntity 公共基类

所有业务实体 SHOULD 继承 `entity/BaseEntity`（`@MappedSuperclass`）：

```java
@MappedSuperclass
public abstract class BaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(nullable = false)
    private boolean deleted = false;

    @PrePersist  → set createdAt + updatedAt
    @PreUpdate   → set updatedAt
}
```

公共字段：
- `id`：UUID 主键，由 JPA 自动生成
- `createdAt`：创建时间，不可更新
- `updatedAt`：最后修改时间
- `deleted`：逻辑删除标记（`false` = 活跃）

访问性：
- `getId()` / `setId()`：public（测试需要 setId）
- `getCreatedAt()` / `getUpdatedAt()`：public getter only（无 setter）
- `isDeleted()` / `markDeleted()`：标记删除用方法，不暴露 `setDeleted(boolean)`

## 主键策略

- 统一使用 `UUID` + `@GeneratedValue(strategy = GenerationType.UUID)`
- 不使用自增 Long id（分布式安全 + 不暴露业务量）

## 列命名

- 数据库列名用 **snake_case**：通过 `@Column(name = "xxx_yyy")` 显式声明
- Java 字段用 camelCase
- 不依赖 Hibernate 的隐式命名策略

## 时间类型

- 统一用 `java.time.Instant`（UTC 时间戳）
- 不用 `LocalDateTime`（避免时区歧义）

## 枚举持久化

- 用 `@Enumerated(EnumType.STRING)` + `@Column(length = N)`
- 不用 `EnumType.ORDINAL`（插入新值会破坏映射）

## 查询约定

- Repository 继承 `JpaRepository<T, UUID>`
- 查询方法命名遵循 Spring Data 规范（`findByXxx` / `existsByXxx`）
- 涉及逻辑删除的查询需显式过滤：`findByXxxAndDeletedFalse`

## 开发环境

- H2 内存库：`jdbc:h2:mem:wanderchina;DB_CLOSE_DELAY=-1`
- DDL 策略：`create-drop`（每次启动重建）
- 生产目标：PostgreSQL（迁移到 Flyway 管理 schema 时再切换）
