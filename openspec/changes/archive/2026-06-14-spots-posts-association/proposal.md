## Why

景点模块和帖子模块已独立完成，但两者之间缺少关联关系。用户在浏览景点详情时需要看到相关攻略帖子，在浏览帖子时也需要了解涉及的景点。本次变更建立 Spot-Post 多对多关联，并提供双向查询接口，打通景点与攻略的数据链路。

## What Changes

- 新增 `SpotPostEntity` 关联实体，映射 `spots_posts` 关联表（`spot_id` + `post_id` 联合主键 + BaseEntity 公共字段）
- 新增 `GET /api/spots/{id}/posts` 接口：返回景点关联的帖子列表（分页，仅 PUBLISHED + 未删除）
- 新增 `GET /api/posts/{id}/spots` 接口：返回帖子关联的景点列表（仅 PUBLISHED + 未删除）
- 新增 `data.sql` 关联种子数据，确保景点与帖子之间有可验证的关联关系
- 新增管理接口（可选）：关联/解除关联的写操作留待后续提案

## Capabilities

### New Capabilities
- `spots-posts-association`: 景点-帖子多对多关联表实体、Repository、Service、Controller，包含双向查询接口

### Modified Capabilities
- `spots-backend-api`: 新增 `GET /api/spots/{id}/posts` 端点到 SpotController
- `posts-backend-api`: 新增 `GET /api/posts/{id}/spots` 端点到 PostController

## Impact

- **后端代码**：新增 entity / repository / service / dto / exception 层代码；修改 SpotController 和 PostController
- **数据库**：新增 `spots_posts` 表，包含 `spot_id`、`post_id` 外键及 BaseEntity 公共字段
- **API**：新增 2 个 GET 端点，不影响现有接口行为
- **种子数据**：data.sql 追加 spots_posts INSERT 语句
- **测试**：每个新增组件均需配套单元测试（Entity / Repository / Service / Controller）
