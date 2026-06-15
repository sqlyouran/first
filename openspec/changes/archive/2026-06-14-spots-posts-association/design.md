## Context

景点模块（spots-backend-api）和帖子模块（posts-backend-api）已独立完成，各自拥有完整的 Entity / Repository / Service / Controller / DTO 栈。当前两个模块之间无数据关联——用户浏览景点详情时无法看到相关攻略，浏览帖子时也无法了解涉及的景点。

现有关键代码：
- `SpotEntity`：`spots` 表，UUID 主键，继承 BaseEntity
- `PostEntity`：`posts` 表，UUID 主键，继承 BaseEntity
- 两者均为独立模块，无 `@ManyToMany` 或关联表

## Goals / Non-Goals

**Goals:**
- 建立 Spot ↔ Post 多对多关联关系，提供双向查询能力
- 景点详情页展示关联帖子列表（分页）
- 帖子详情页展示关联景点列表（无需分页，通常数量较少）
- 种子数据中包含有意义的关联关系用于测试验证

**Non-Goals:**
- 关联/解除关联的写操作（POST/DELETE）——留待后续提案
- 前端页面改造——本次仅后端 API
- 关联帖子的实时统计字段更新（如通过关联表更新 spot 的 viewCount）

## Decisions

### 1. SpotPostEntity 继承 BaseEntity（而非 @IdClass 纯关联表）

**选择**：关联表实体继承 BaseEntity，拥有独立 `id` UUID + `createdAt` / `updatedAt` / `deleted`。

**备选方案**：使用 `@IdClass` + `@ManyToOne` 的轻量联合主键方案（无 BaseEntity）。

**理由**：
- 与项目统一基类保持一致，所有实体均继承 BaseEntity
- 支持逻辑删除——解除关联时 `markDeleted()` 而非物理删除
- `createdAt` 可用于"按关联时间排序"的需求
- 独立 UUID 主键比联合主键在 Repository 层更简洁

### 2. 独立 spots_posts 表 + Repository 原生查询（而非 JPA @ManyToMany）

**选择**：独立 `SpotPostEntity` + `SpotPostRepository`，通过 JPQL/方法命名实现双向查询。

**备选方案**：在 SpotEntity/PostEntity 上使用 `@ManyToMany` + `@JoinTable` 注解。

**理由**：
- `@ManyToMany` 会引入 Lazy Loading / N+1 查询问题，且关联表无法携带 BaseEntity 公共字段
- 独立实体方案允许关联表有自己的 `deleted` 字段和 `createdAt` 时间戳
- Repository 查询更显式、可测试，符合项目分层约定

### 3. 双向查询接口的归属

**选择**：
- `GET /api/spots/{id}/posts` → SpotController 新增端点，委托 SpotPostService
- `GET /api/posts/{id}/spots` → PostController 新增端点，委托 SpotPostService

**理由**：URL 结构遵循 RESTful 子资源约定，与现有 Controller 职责对齐。SpotPostService 作为关联层的 Service，被两个 Controller 共享。

### 4. SpotPostEntity 联合唯一约束

**选择**：`(spot_id, post_id)` 设置 `UNIQUE` 约束，防止重复关联。

**理由**：同一景点与同一帖子不应有多条有效关联记录。联合唯一约束在数据库层保证数据一致性。

### 5. 查询时过滤关联记录的有效性

**选择**：所有查询均过滤 `SpotPostEntity.deleted = false`，且关联的 Post/Spot 也需满足 `deleted = false` + `status = PUBLISHED`。

**理由**：与现有模块的逻辑删除策略保持一致；用户侧只能看到已发布的关联内容。

### 6. 种子数据策略

**选择**：在 `data.sql` 中追加 `INSERT IGNORE INTO spots_posts` 语句，基于现有 spots 和 posts 种子数据的 UUID 建立关联。

**理由**：保持幂等种子数据策略，与 cities/spots 的 data.sql 模式一致。

## Risks / Trade-offs

- **[SpotPostEntity 冗余 id 列]** → 关联表多了独立 UUID id 列，略有存储开销。换取与 BaseEntity 的一致性和逻辑删除能力，可接受。
- **[无写操作接口]** → 本次只有只读查询，无法通过 API 创建/删除关联。种子数据提供测试数据，写操作在后续 change 中实现。
- **[PostEntity/SpotEntity 不感知关联]** → 两个实体上不添加 `@OneToMany` 映射，保持模块解耦。查询走 SpotPostRepository 实现。
