## 1. BaseEntity 抽象类

- [x] 1.1 创建 `entity/BaseEntity.java`：`@MappedSuperclass` 抽象类，包含 `id` (UUID, @GeneratedValue)、`createdAt` (Instant, updatable=false)、`updatedAt` (Instant)、`deleted` (boolean, default false)
- [x] 1.2 实现 `@PrePersist onCreate()`：设置 createdAt + updatedAt = Instant.now()
- [x] 1.3 实现 `@PreUpdate onUpdate()`：设置 updatedAt = Instant.now()
- [x] 1.4 实现访问器：`getId()` / `setId()`、`getCreatedAt()` / `getUpdatedAt()`（getter only）、`isDeleted()` / `markDeleted()`

## 2. BaseEntity 单元测试

- [x] 2.1 创建 `test/.../entity/BaseEntityTest.java`（使用 `@DataJpaTest` + 具体子类测试）
- [x] 2.2 测试：persist 后 id 非 null、createdAt 非 null、updatedAt 非 null、deleted == false
- [x] 2.3 测试：update 后 updatedAt 改变、createdAt 不变
- [x] 2.4 测试：markDeleted() 后 isDeleted() == true
- [x] 2.5 运行测试，确认 RED → GREEN

## 3. UserEntity 重构

- [x] 3.1 修改 `entity/UserEntity.java`：添加 `extends BaseEntity`，移除 id 字段、createdAt 字段、updatedAt 字段、getId/setId getter/setter、getCreatedAt/getUpdatedAt getter、@PrePersist onCreate、@PreUpdate onUpdate
- [x] 3.2 保留 UserEntity 自身业务字段：email、passwordHash、state、failedAttempts、lockedUntil

## 4. 回归验证

- [x] 4.1 运行 `mvnw test`，确认 AuthControllerTest 全部绿灯
- [x] 4.2 运行 `mvnw spring-boot:run`，确认应用正常启动
- [x] 4.3 验证 H2 console 中 `users` 表包含 `deleted` 列（boolean, default false）
