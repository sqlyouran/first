## Context

当前后端只有一个 JPA 实体 `UserEntity`，手动持有 id / createdAt / updatedAt 字段及 `@PrePersist` / `@PreUpdate` 回调。无公共基类。

现有 UserEntity 结构：
```java
@Entity @Table(name = "users")
public class UserEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
    // ... 业务字段
    @PrePersist protected void onCreate() { ... }
    @PreUpdate  protected void onUpdate() { ... }
}
```

项目规约（`database-conventions.md`）已明确 BaseEntity 的目标设计。

## Goals / Non-Goals

**Goals:**
- 提供 `@MappedSuperclass BaseEntity` 抽象类，统一管理 id / createdAt / updatedAt / deleted
- UserEntity 继承 BaseEntity 后行为不变（所有现有测试绿灯）
- 新增 `deleted` 列支持逻辑删除基础设施
- BaseEntity 单元测试覆盖生命周期回调和 markDeleted 行为

**Non-Goals:**
- 不改造 UserRepository 查询为 `findByXxxAndDeletedFalse`（UserEntity 有自己的 State.deleted 业务语义）
- 不引入 Spring Data JPA Auditing（`@EnableJpaAuditing` / `@CreatedDate`）
- 不改变 API 响应格式
- 不做 UserEntity 的 State enum 与 BaseEntity.deleted 的联动
- 不引入 `@Where(clause = "deleted = false")` 全局过滤（显式优于隐式）

## Decisions

### D1: 继承策略——@MappedSuperclass

**选择**: `@MappedSuperclass`
**替代方案**: `@Inheritance(strategy = SINGLE_TABLE / TABLE_PER_CLASS)`
**理由**:
- 不需要 JPA 多态查询（不会 `SELECT * FROM base_entity`）
- `@MappedSuperclass` 仅在 Java 层提供字段继承，数据库层面各子类表独立，零额外开销
- 与 `database-conventions.md` 已定义的规约一致

### D2: 时间戳管理——@PrePersist / @PreUpdate

**选择**: 实体内部生命周期回调
**替代方案**: Spring Data JPA Auditing (`@CreatedDate` + `@EnableJpaAuditing`)
**理由**:
- YAGNI：当前无 `@CreatedBy` / `@LastModifiedBy` 需求
- 与现有 UserEntity 已有的模式完全一致，改动最小
- 回调在实体内部可见，不依赖外部配置"魔法"
- 未来需要 Auditor 时迁移成本低（改注解 + 加配置类即可）

### D3: 逻辑删除——boolean deleted

**选择**: `boolean deleted` + `markDeleted()` 方法
**替代方案**: `Instant deletedAt`（null = 活跃）
**理由**:
- 简单：查询条件 `WHERE deleted = false`，比 `WHERE deleted_at IS NULL` 直观
- UserEntity 已有 `State.deleted` 业务状态，BaseEntity 的 `deleted` 是基础设施级标记，两者职责分离
- 不暴露 `setDeleted(boolean)` 防止误操作，只提供 `markDeleted()` 单向操作

### D4: setId() 可见性

**选择**: public `setId(UUID id)`
**理由**: 测试中需要手动设置 id（`entity.setId(UUID.randomUUID())`），不提供 setter 会导致测试代码用反射，增加脆弱性。

### D5: UserEntity.State.deleted 与 BaseEntity.deleted 的关系

**选择**: 不联动，各自独立
**理由**:
- `State.deleted` 是业务层语义（用户账户已注销）
- `BaseEntity.deleted` 是基础设施层逻辑删除标记
- UserEntity 当前不使用 `BaseEntity.deleted`（通过 State 管理），后续业务实体（景点、攻略）才会用到
- 未来如需联动，可在 UserService 中 `user.markDeleted()` 同步调用

## Architecture

```
┌─────────────────────────────────────────┐
│    @MappedSuperclass BaseEntity         │
├─────────────────────────────────────────┤
│  - id: UUID           (PK, generated)   │
│  - createdAt: Instant (updatable=false)  │
│  - updatedAt: Instant                    │
│  - deleted: boolean   (default=false)    │
├─────────────────────────────────────────┤
│  # @PrePersist onCreate()               │
│  # @PreUpdate  onUpdate()               │
│  + getId() / setId(UUID)                │
│  + getCreatedAt() / getUpdatedAt()      │
│  + isDeleted() / markDeleted()          │
└─────────────────────────────────────────┘
              ▲
              │ extends
              │
┌─────────────────────────────────────────┐
│  @Entity UserEntity                     │
├─────────────────────────────────────────┤
│  - email: String                        │
│  - passwordHash: String                 │
│  - state: State (enum)                  │
│  - failedAttempts: int                  │
│  - lockedUntil: Instant                 │
└─────────────────────────────────────────┘
```

**改动范围**：

| 文件 | 动作 |
|------|------|
| `entity/BaseEntity.java` | 新增 |
| `entity/UserEntity.java` | 重构：移除 id/timestamps/callbacks，加 `extends BaseEntity` |
| `repository/UserRepository.java` | 不变（签名兼容） |
| `test/.../BaseEntityTest.java` | 新增 |
| `test/.../AuthControllerTest.java` | 应保持绿灯（回归验证） |

## Risks / Trade-offs

- **[风险] UserEntity 表新增 `deleted` 列** → H2 `create-drop` 模式自动处理，无需手动 migration。生产环境切换时需 Flyway 脚本 `ALTER TABLE users ADD COLUMN deleted BOOLEAN NOT NULL DEFAULT false`
- **[风险] @PrePersist 继承链是否正确触发** → JPA 规范保证 `@MappedSuperclass` 的 lifecycle callbacks 对子类有效，H2 集成测试验证
- **[权衡] boolean deleted 不记录删除时间** → 简单优先；未来如需审计可再加 `deletedAt` 字段
- **[权衡] 不加 `@Where` 全局过滤** → 显式优于隐式；忘记加 `AND deleted = false` 是程序员错误，通过 code review 和规约约束
