## Why

评论（CommentEntity）和收藏（BookmarkEntity）当前硬绑 `post_id`，无法复用于景点（Spot）等其他内容类型。景点详情页需要评论和收藏功能，若为每个实体类型建独立表，将产生大量重复代码和 API 端点。将互动模型统一泛化为多态关联（`entity_id` + `entity_type`），一次性解决扩展性问题，并为未来投票（Vote）等互动的泛化铺路。

## What Changes

- **BREAKING**: `CommentEntity` 表结构变更 — `post_id` → `entity_id`(UUID) + `entity_type`(ENUM: POST/SPOT)，所有基于 `postId` 的查询方法改为 `(entityId, entityType)` 组合
- **BREAKING**: `BookmarkEntity` 表结构变更 — `post_id` → `entity_id`(UUID) + `entity_type`(ENUM: POST/SPOT)，唯一约束改为 `(entity_id, entity_type, user_id)`
- 新增 `EntityType` 枚举（POST / SPOT），供评论和收藏共享
- `BookmarkRepository` / `CommentRepository` 查询方法泛化，支持按 `(entityId, entityType)` 组合查询
- `BookmarkService` / `CommentService` 方法签名泛化，内部统一逻辑
- 新增 `SpotBookmarkController` — `GET /api/spots/{spotId}/bookmark-status` + `POST /api/spots/{spotId}/bookmark`（复用 BookmarkService）
- 新增 `SpotCommentController` — `GET /api/spots/{spotId}/comments` + `POST /api/spots/{spotId}/comments`（复用 CommentService）
- `GET /api/bookmarks` 列表端点新增可选参数 `entity_type`（POST/SPOT），不传返回全部
- 现有 `PostBookmarkController` / `PostCommentController` 端点路径不变，内部委托泛化后的 Service
- 种子数据（data.sql）和全部测试同步适配新表结构

## Capabilities

### New Capabilities

- `polymorphic-interactions`: 评论与收藏的多态关联模型（EntityType 枚举 + entity_id/entity_type 字段），支持任意内容类型的评论和收藏

### Modified Capabilities

- `post-interactions-backend`: 评论和收藏的 Entity/Repository/Service 层从 `postId` 迁移到 `(entityId, entityType)` 组合，API 端点路径不变但内部实现委托泛化逻辑

## Impact

- **数据库 Schema 变更**: `comments` 和 `bookmarks` 两张表的列名和约束变更（开发环境 H2 create-drop 无迁移负担）
- **种子数据**: data.sql 中 INSERT 语句适配新列名
- **测试影响面**: 所有涉及 CommentEntity / BookmarkEntity 的单元测试和集成测试需适配新字段
- **API 兼容性**: 现有帖子端点路径不变（`/api/posts/{postId}/comments`、`/api/posts/{postId}/bookmark`），对前端零破坏
- **新增端点**: 景点收藏 + 景点评论共 4 个端点
- **新增依赖**: 无（纯后端重构 + 端点新增）
