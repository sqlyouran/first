## Context

WanderChina 是面向境外用户的中国旅游探索平台。城市模块（cities-backend-api）已完成，提供 CityEntity + CRUD + 8 条种子城市。景点模块强依赖城市（cityId FK），现在具备开发条件。

当前后端已有模式可复用：BaseEntity 基类、CityService/Controller 分页模式、GlobalExceptionHandler 异常路由、data.sql 种子数据机制、StringListConverter（JSON 数组）。

## Goals / Non-Goals

**Goals:**
- 建立 SpotEntity 数据模型（基本信息 + 城市归属 + 统计字段）
- 提供景点列表接口（分页 + 城市筛选 + 排序）
- 提供景点详情接口
- 提供景点排行榜接口（评分 / 热度 / 收藏 Top N，独立端点）
- 种子数据覆盖多个城市的知名景点
- 全部接口遵循项目 API 规约（snake_case JSON、ApiResponse 结构）

**Non-Goals:**
- 不做景点-帖子关联表（SpotPostEntity）及关联帖子列表接口
- 不做景点 CRUD（创建/更新/删除），仅只读 API
- 不做用户实时评分/收藏/浏览的写入口
- 不做地理位置（经纬度/地图）和实用信息（门票/开放时间）

## Decisions

### 1. SpotEntity 字段集

字段分为三组：基本信息、城市归属、统计字段。

| 字段 | 类型 | 说明 |
|------|------|------|
| name | VARCHAR(200) NOT NULL | 英文名（必填） |
| nameZh | VARCHAR(200) | 中文名 |
| slug | VARCHAR(220) NOT NULL UNIQUE | URL 路由标识 |
| description | TEXT | 英文描述 |
| descriptionZh | TEXT | 中文描述 |
| coverImage | VARCHAR(2048) | 封面图 URL |
| gallery | TEXT (JSON List\<String\>) | 图片集，复用 StringListConverter |
| tags | TEXT (JSON List\<String\>) | 标签，复用 StringListConverter |
| cityId | UUID NOT NULL | 外键指向 cities |
| cityName | VARCHAR(100) | 冗余城市名，避免列表查询 JOIN |
| status | VARCHAR(20) NOT NULL | 枚举 STRING：DRAFT / PUBLISHED |
| rating | DECIMAL(2,1) | 评分，5 分制（0.0~5.0），默认 0.0 |
| viewCount | INT | 热度（浏览次数），默认 0 |
| bookmarkCount | INT | 收藏数，默认 0 |

继承 BaseEntity（id / createdAt / updatedAt / deleted）。

**理由**：Phase 1 只存静态统计值（种子数据写入），不做实时更新。排行榜直接基于这三个字段 ORDER BY DESC LIMIT N。后续增加用户行为写入口时，再通过异步聚合更新这些计数。

### 2. 排行榜设计

独立接口 `GET /api/spots/ranking?type=rating|heat|bookmark&top=10`：
- `type`：必填，枚举值 rating / heat / bookmark
- `top`：可选，默认 10，最大 50
- 返回 `SpotRankingResponse`，包含 `type` + `items[]`
- items 按对应字段 DESC 排序，只返回摘要字段（id / name / nameZh / slug / coverImage / cityName / rating / viewCount / bookmarkCount）
- 只查询 PUBLISHED 状态的景点

**理由**：排行榜有独立的 UI 展示形态（Top N 卡片），与列表页的分页表格不同，拆开更清晰。

### 3. 列表接口排序

`GET /api/spots?city_id=<uuid>&page=1&size=20&sort=latest`

排序选项：
- `latest`：按 created_at DESC（默认）
- `rating`：按 rating DESC
- `viewCount`：按 view_count DESC
- `bookmarkCount`：按 bookmark_count DESC

**理由**：列表接口也支持排序，方便用户在列表页切换查看方式。排行榜则是独立的 Top N 展示。

### 4. cityId 外键策略

JPA 层面用 `@Column(name = "city_id", nullable = false)` 存 UUID，不做 `@ManyToOne` 关联。cityName 冗余存储。

**理由**：与 PostEntity 的 authorId 模式一致。避免 JPA 懒加载问题，查询性能可控。

### 5. SpotStatus 枚举

独立枚举 `SpotStatus`（DRAFT / PUBLISHED），与 PostStatus 并列。

**理由**：不共用 PostStatus，语义独立。未来可能增加景点特有状态（如 CLOSED）。

### 6. 种子数据

data.sql 追加景点 INSERT IGNORE，覆盖至少 5 个城市的 15+ 景点，包含合理的 rating/viewCount/bookmarkCount 值以验证排行榜。

## Risks / Trade-offs

- **[cityName 冗余不一致]** → 种子数据阶段可控；后续管理后台创建景点时由 Service 层根据 cityId 自动填充
- **[统计字段无实时更新]** → Phase 1 为只读展示，种子数据静态值足够；Phase 2 增加用户行为写入口时再补聚合逻辑
- **[不做 @ManyToOne FK 约束]** → 数据库层面无外键约束，依赖 Service 层校验 cityId 存在。与 PostEntity 模式一致，可接受
