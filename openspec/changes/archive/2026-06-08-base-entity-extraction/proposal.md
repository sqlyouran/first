## Why

当前 `UserEntity` 手动管理 UUID 主键 + `@PrePersist/@PreUpdate` 时间戳，无公共基类。后续业务模块（城市、景点、攻略等）都需要相同的公共字段模式（id / createdAt / updatedAt / soft-delete）。如果每个实体都复制粘贴这些字段和回调，违反 DRY 原则，且一旦公共字段策略调整需要逐个修改。

本变更提取 `BaseEntity` 抽象基类，建立统一的实体公共字段契约，为后续业务模块开发扫清基础设施障碍。

## What Changes

- **新增 `entity/BaseEntity.java`**：`@MappedSuperclass` 抽象类，包含：
  - `UUID id`（`@GeneratedValue(strategy = GenerationType.UUID)`）
  - `Instant createdAt`（`@Column(updatable = false)`）
  - `Instant updatedAt`
  - `boolean deleted`（逻辑删除标记，默认 `false`）
  - `@PrePersist` / `@PreUpdate` 生命周期回调
  - `markDeleted()` 方法（不暴露 `setDeleted(boolean)`）

- **重构 `entity/UserEntity.java`**：继承 `BaseEntity`，移除重复的 id / createdAt / updatedAt / @PrePersist / @PreUpdate

- **调整 `UserRepository`**：确保签名 `JpaRepository<UserEntity, UUID>` 不变（BaseEntity 的 id 类型一致）

## Capabilities

### New Capabilities
- `base-entity`: JPA 实体公共基类，提供 UUID 主键 + 审计时间戳 + 逻辑删除的统一基础设施

### Modified Capabilities
- 无（UserEntity 外部行为不变，仅内部继承结构调整）

## Impact

- **后端文件**：`entity/BaseEntity.java`（新增）、`entity/UserEntity.java`（重构）
- **测试**：新增 `BaseEntity` 单元测试；现有 `AuthControllerTest` 应保持绿灯（外部行为不变）
- **依赖**：无新增依赖
- **API 行为**：无变化（纯内部重构）
- **数据库 schema**：字段不变，新增 `deleted` 列（boolean, default false）
