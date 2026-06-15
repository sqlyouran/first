## Context

当前评论（`CommentEntity`）和收藏（`BookmarkEntity`）都硬绑 `post_id`，无法服务于景点（Spot）等其他内容类型。后端已有完整的帖子互动 API（`post-interactions-backend` change），景点后端 API（`spots-backend-api` change）也已就绪，但缺少景点评论和收藏端点。

现有关键代码：
- `CommentEntity` — `postId(UUID)`, `userId(UUID)`, `content(TEXT)`, `parentCommentId(UUID)`
- `BookmarkEntity` — `postId(UUID)`, `userId(UUID)`，唯一约束 `(post_id, user_id)`
- `BookmarkController` — `/api/posts/{postId}/bookmark-status`, `/api/posts/{postId}/bookmark`, `/api/bookmarks`
- `CommentController` — `/api/posts/{postId}/comments`, `/api/comments/{commentId}/replies`, `DELETE /api/posts/{postId}/comments/{commentId}`
- `BookmarkService` / `CommentService` — 内部直接引用 `postId`

开发环境使用 H2 create-drop，Schema 变更无迁移负担。

## Goals / Non-Goals

**Goals:**

- CommentEntity / BookmarkEntity 统一泛化为 `entity_id` + `entity_type` 多态关联
- 新增 `EntityType` 枚举（POST / SPOT），评论和收藏共享
- 现有帖子端点路径不变（`/api/posts/{postId}/comments` 等），内部委托泛化 Service
- 新增景点端点：`/api/spots/{spotId}/comments` + `/api/spots/{spotId}/bookmark` 等
- `GET /api/bookmarks` 支持 `entity_type` 可选筛选参数
- 种子数据和全部测试同步适配
- 所有新代码 TDD 覆盖

**Non-Goals:**

- 不泛化 VoteEntity（投票泛化留到后续 change，当前只改评论和收藏）
- 不新增景点投票端点
- 不做前端组件适配（由 `spots-frontend-detail` change 负责）
- 不做数据库迁移脚本（H2 create-drop 自动重建）
- 不做 SpotPostEntity 关联表（相关攻略预留区块由前端 placeholder 处理）

## Decisions

### D1: 多态关联模式 — 单表 + entity_type 列

**选择**：在 `comments` 和 `bookmarks` 表中用 `entity_id` + `entity_type` 替代 `post_id`，所有实体类型共享同一张表。

**替代方案**：
- 独立表（`spot_comments` / `spot_bookmarks`）→ 表数量随实体类型线性增长，Service/Repository 代码大量重复
- JPA 继承策略（`@Inheritance`）→ 过度设计，当前只需区分 entity_type，无需多态查询

**理由**：单表 + 枚举列是最简单的多态关联实现，查询性能无损（`(entity_id, entity_type)` 组合索引），新增实体类型只需加枚举值。

### D2: EntityType 枚举位置 — 独立文件

**选择**：新建 `entity/EntityType.java` 独立枚举，评论和收藏共享引用。

**替代方案**：
- 放在 CommentEntity 内部 → 收藏模块依赖评论模块，耦合不合理
- 用 String 代替枚举 → 失去编译期类型安全

**理由**：独立枚举文件是最小耦合方案，未来新增实体类型（如 Story）只需扩展此枚举。

### D3: API 路径策略 — 方案 B（保持直觉路径）

**选择**：保留 `/api/posts/{postId}/comments` 等现有路径，新增 `/api/spots/{spotId}/comments` 等景点路径。内部共享 Service 逻辑。

**替代方案**：
- 统一入口 `/api/comments?entity_type=POST&entity_id=xxx` → 对前端不直觉，URL 结构不一致
- REST 资源型 `/api/entities/{type}/{id}/comments` → 不符合现有 URL 约定

**理由**：保持每个资源模块的 URL 直觉性（帖子在 `/api/posts/` 下，景点在 `/api/spots/` 下），内部通过 Service 层 `entityType` 参数统一逻辑。

### D4: Controller 组织 — 新增 SpotXxxController

**选择**：新增 `SpotBookmarkController` 和 `SpotCommentController`，各自调用泛化后的 Service。

**替代方案**：
- 在现有 BookmarkController 中加景点端点 → Controller 职责混乱（帖子和景点混合）
- 抽取公共 BaseController → 过度抽象，当前只有两个资源类型

**理由**：按资源模块拆分 Controller 与现有分层架构一致（PostController / SpotController 已独立），职责清晰。

### D5: 收藏列表 entity_type 筛选

**选择**：`GET /api/bookmarks?entity_type=POST|SPOT` 可选参数，不传返回全部收藏（按 createdAt DESC 分页）。

**替代方案**：
- 必填参数 → 破坏现有前端调用（当前无 entity_type 参数）
- 分拆端点 `/api/bookmarks/posts` + `/api/bookmarks/spots` → 不灵活

**理由**：可选参数向后兼容，前端按需筛选，不传时保持现有行为。

### D6: 现有 Repository 方法适配策略

**选择**：保留方法名语义但改参数，例如 `findByPostIdAndUserId` → `findByEntityIdAndEntityTypeAndUserId`。Post 端点的 Controller 传入 `EntityType.POST`。

**替代方案**：
- 保留旧方法名做 adapter → 代码冗余，两套方法共存
- 新建泛化 Repository 接口 → 过度抽象

**理由**：直接改方法名最清晰，所有调用点在编译期暴露，不会有遗漏。

## Risks / Trade-offs

- **[风险] 测试影响面大**：CommentEntity / BookmarkEntity 字段变更影响所有涉及评论和收藏的测试 → 缓解：TDD 流程中逐步修改测试，每改一个 Entity 立即跑全量测试确认绿灯
- **[风险] 种子数据 INSERT 语句需全部重写**：data.sql 中 comments / bookmarks 的 INSERT 语句列名变更 → 缓解：data.sql 随 Entity 同步修改，启动时自动验证
- **[权衡] Vote 暂不泛化**：投票模块仍绑 `postId`，与评论/收藏不一致 → 接受，Vote 泛化留到后续 change，避免本次改动面过大
- **[权衡] H2 限定**：当前方案依赖 create-drop 自动重建，迁移到 PostgreSQL 时需写 Flyway 迁移脚本 → 接受，Flyway 在后续 change 中引入
