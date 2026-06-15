## Why

景点模块（spots）强依赖城市外键（`cityId`），但项目目前没有城市数据层。前端首页 City Grid 区域硬编码了 8 个城市，无后端支撑。先建城市模块是景点模块的必要前置。

## What Changes

- 新增 `CityEntity`（继承 `BaseEntity`），字段：`name`（必填）、`nameZh`、`slug`（唯一）、`coverImage`、`description`、`bestSeason`（String）
- 新增 `CityRepository`、`CityService`、`CityController` 标准分层
- 新增 `CityResponse` / `CityListResponse` DTO（继承 `BaseResponse`，snake_case JSON）
- 新增 `data.sql` 种子数据（8 个城市，与前端 `cityGrid.data.ts` 对齐）
- 修改 `application.yml`，启用 `spring.sql.init` + `defer-datasource-initialization`
- 提供 `GET /api/cities`（分页）+ `GET /api/cities/{id}`（详情）两个只读接口

## Capabilities

### New Capabilities

- `cities-backend-api`: 城市实体的 CRUD 分层、只读列表/详情接口、种子数据机制

### Modified Capabilities

_无需修改现有 spec（城市模块为全新领域，不影响已有规格）。_

## Impact

| 范围 | 影响 |
|------|------|
| `backend/` 子仓 | 新增 entity / repository / service / controller / dto / data.sql |
| `application.yml` | 追加 `spring.sql.init.*` 和 `defer-datasource-initialization` 配置 |
| 数据库 | 新增 `cities` 表（`ddl-auto: update` 自动建表） |
| 现有 API | 无破坏性变更，纯新增 |
| 前端 | 暂不影响（前端对接在后续 change 中） |
