## Why

景点模块（Spot）是 WanderChina 的核心内容模块之一，用户通过景点浏览、搜索、排行榜发现目的地。景点强依赖城市（cityId），而城市模块（cities-backend-api）已完成，具备了开发景点后端的条件。本次变更建立景点的数据模型和 API 接口，为前端景点列表页、详情页、排行榜提供数据支撑。

## What Changes

- 新增 `SpotEntity` 实体，包含基本信息（name/nameZh/slug/description/descriptionZh/coverImage/gallery/tags）、城市归属（cityId/cityName）、状态（status: DRAFT/PUBLISHED）、统计字段（rating/viewCount/bookmarkCount）
- 新增 `SpotRepository`，支持分页查询、城市筛选、按评分/热度/收藏排序
- 新增 `SpotService`，实现列表查询（分页 + 城市筛选 + 排序）和详情查询
- 新增 `SpotController`，暴露 2 个 GET 端点：列表 + 详情
- 新增 `SpotException` + `GlobalExceptionHandler` 扩展
- 新增 `SpotResponse` / `SpotListResponse` DTO（snake_case JSON）
- 新增景点种子数据（data.sql），覆盖中国主要城市的知名景点
- 新增排行榜接口（独立端点），支持按评分/热度/收藏 Top N 查询

## Capabilities

### New Capabilities
- `spots-backend-api`: 景点模块后端 API，包括 Entity / Repository / Service / Controller / DTO / Exception / 种子数据 / 排行榜接口

### Modified Capabilities

## Impact

- **后端代码**：新增 `entity/SpotEntity`、`repository/SpotRepository`、`service/SpotService`、`controller/SpotController`、`dto/response/SpotResponse`、`dto/response/SpotListResponse`、`exception/SpotException`
- **现有修改**：`GlobalExceptionHandler` 新增 SpotException handler、`SecurityConfig` 放开 `/api/spots/**`
- **数据库**：新增 `spots` 表（JPA 自动建表）、`data.sql` 追加种子数据
- **API 契约**：新增 3 个 GET 端点（`/api/spots`、`/api/spots/{id}`、`/api/spots/ranking`）
- **不做**：景点关联帖子列表（`/api/spots/{id}/posts`）和 SpotPostEntity 关联表推迟到下一个提案
