## ADDED Requirements

### Requirement: CityEntity 实体定义

`CityEntity` SHALL 继承 `BaseEntity`（id / createdAt / updatedAt / deleted），映射到 `cities` 表，字段如下：

| 字段 | 类型 | 约束 | DB 列名 |
|------|------|------|---------|
| `name` | `VARCHAR(100)` | NOT NULL | `name` |
| `nameZh` | `VARCHAR(100)` | 可选 | `name_zh` |
| `slug` | `VARCHAR(120)` | NOT NULL, UNIQUE | `slug` |
| `coverImage` | `VARCHAR(2048)` | 可选 | `cover_image` |
| `description` | `TEXT` | 可选 | `description` |
| `bestSeason` | `VARCHAR(50)` | 可选 | `best_season` |

#### Scenario: 创建合法 CityEntity 后持久化

- **GIVEN** `CityEntity` 实例 `name="Beijing"`, `slug="beijing"`
- **WHEN** 通过 Repository 持久化
- **THEN** `id` 为 UUID，`createdAt` 和 `updatedAt` 不为 null，`deleted` 为 false
- **AND** 数据库 `cities` 表存在对应行

#### Scenario: slug 重复时抛 DataIntegrityViolationException

- **GIVEN** `cities` 表已存在 `slug="beijing"` 的行
- **WHEN** 持久化另一个 `slug="beijing"` 的 `CityEntity`
- **THEN** 抛出 `DataIntegrityViolationException`

---

### Requirement: CityRepository 查询方法

`CityRepository` SHALL 继承 `JpaRepository<CityEntity, UUID>`，提供：

- `findByDeletedFalse(Pageable)` — 分页查询所有未删除城市
- `findByIdAndDeletedFalse(UUID)` — 按 ID 查询未删除城市

#### Scenario: 分页查询返回未删除城市

- **GIVEN** `cities` 表有 8 条未删除记录
- **WHEN** 调用 `findByDeletedFalse(PageRequest.of(0, 20))`
- **THEN** 返回 8 条 `CityEntity`

#### Scenario: 逻辑删除城市不出现在列表

- **GIVEN** `cities` 表有 8 条记录，其中 1 条 `deleted=true`
- **WHEN** 调用 `findByDeletedFalse(PageRequest.of(0, 20))`
- **THEN** 返回 7 条 `CityEntity`

#### Scenario: 按 ID 查询逻辑删除城市返回空

- **GIVEN** `cities` 表存在 id=X 的记录，`deleted=true`
- **WHEN** 调用 `findByIdAndDeletedFalse(X)`
- **THEN** 返回 `Optional.empty()`

---

### Requirement: GET /api/cities 列表接口

`CityController` SHALL 提供 `GET /api/cities`，参数：`page`（默认 1）、`size`（默认 20，最大 100），返回 `CityListResponse`。

**响应格式**：
```json
{
  "request_id": "<uuid>",
  "items": [
    {
      "id": "<uuid>",
      "name": "Beijing",
      "name_zh": "北京",
      "slug": "beijing",
      "cover_image": "https://...",
      "description": "...",
      "best_season": "Autumn",
      "created_at": "...",
      "updated_at": "..."
    }
  ],
  "total": 8,
  "page": 1,
  "size": 20
}
```

**排序**：默认按 `name` 升序（`ORDER BY name ASC`）。

#### Scenario: 默认分页参数

- **WHEN** 请求 `GET /api/cities`（无参数）
- **THEN** HTTP 200，响应 `page=1`，`size=20`，`items` 包含所有城市（≤20 条时全部返回）

#### Scenario: 显式分页参数

- **GIVEN** `cities` 表有 8 条记录
- **WHEN** 请求 `GET /api/cities?page=1&size=3`
- **THEN** HTTP 200，响应 `items` 含 3 条，`total=8`，`page=1`，`size=3`

#### Scenario: 请求 size 超过最大值

- **WHEN** 请求 `GET /api/cities?size=200`
- **THEN** HTTP 400，响应 `error_code="validation_error"`

#### Scenario: 列表按 name 升序排列

- **GIVEN** `cities` 表有 Beijing、Shanghai、Chengdu
- **WHEN** 请求 `GET /api/cities`
- **THEN** `items[0].name="Beijing"`，`items[1].name="Chengdu"`，`items[2].name="Shanghai"`

---

### Requirement: GET /api/cities/{id} 详情接口

`CityController` SHALL 提供 `GET /api/cities/{id}`，返回 `CityResponse`。

#### Scenario: 查询存在的城市

- **GIVEN** `cities` 表存在 id=X 的未删除城市
- **WHEN** 请求 `GET /api/cities/X`
- **THEN** HTTP 200，响应包含完整城市字段（`id`, `name`, `name_zh`, `slug`, `cover_image`, `description`, `best_season`, `created_at`, `updated_at`）

#### Scenario: 查询不存在的城市

- **WHEN** 请求 `GET /api/cities/<不存在的UUID>`
- **THEN** HTTP 404，响应 `error_code="not_found"`，`message` 含提示信息

#### Scenario: 查询已逻辑删除的城市

- **GIVEN** `cities` 表存在 id=X，`deleted=true`
- **WHEN** 请求 `GET /api/cities/X`
- **THEN** HTTP 404，响应 `error_code="not_found"`

---

### Requirement: CityResponse 与 CityListResponse DTO

`CityResponse` SHALL 继承 `BaseResponse`（自带 `request_id`），所有字段 `private final`，使用 `@JsonProperty` 显式声明 snake_case 序列化。

`CityListResponse` SHALL 继承 `BaseResponse`，字段：`items`（`List<CityResponse>`）、`total`（`long`）、`page`（`int`）、`size`（`int`）。

#### Scenario: CityResponse JSON 字段名为 snake_case

- **WHEN** `CityResponse` 序列化为 JSON
- **THEN** 字段名为 `name_zh`、`cover_image`、`best_season`、`created_at`、`updated_at`（非 camelCase）

#### Scenario: CityListResponse 包含分页元数据

- **WHEN** `CityListResponse` 序列化为 JSON
- **THEN** 响应体包含 `request_id`、`items`、`total`、`page`、`size` 字段

---

### Requirement: CityException 统一异常

cities 模块 SHALL 使用 `CityException`（继承 `RuntimeException`），持有 `HttpStatus` + `errorCode`（snake_case）+ `message`，由 `GlobalExceptionHandler` 统一映射到 `ErrorResponse`。

#### Scenario: CityException 映射到 ErrorResponse

- **WHEN** `CityService` 抛出 `CityException(HttpStatus.NOT_FOUND, "not_found", "City not found")`
- **THEN** `GlobalExceptionHandler` 返回 HTTP 404
- **AND** 响应体 `error_code="not_found"`，`message="City not found"`

---

### Requirement: data.sql 种子数据

项目 SHALL 在 `backend/src/main/resources/data.sql` 中提供 8 个城市的种子数据，使用 `INSERT IGNORE INTO cities` 确保幂等。

**种子数据对齐前端 `cityGrid.data.ts`**：Beijing、Shanghai、Chengdu、Xi'an、Hangzhou、Guilin、Lijiang、Xiamen。

`application.yml` SHALL 配置：
```yaml
spring:
  jpa:
    defer-datasource-initialization: true
  sql:
    init:
      mode: always
```

#### Scenario: 首次启动后 cities 表含 8 条记录

- **GIVEN** `cities` 表为空（或不存在）
- **WHEN** 应用启动
- **THEN** `cities` 表包含 8 条记录，slug 分别为 `beijing`, `shanghai`, `chengdu`, `xian`, `hangzhou`, `guilin`, `lijiang`, `xiamen`

#### Scenario: 重复启动不报错、不重复插入

- **GIVEN** `cities` 表已含 8 条种子数据
- **WHEN** 应用重启
- **THEN** 启动成功，`cities` 表仍为 8 条记录，无重复行

#### Scenario: 种子数据包含完整字段

- **WHEN** 查询 `slug="beijing"` 的记录
- **THEN** `name="Beijing"`，`name_zh="北京"`，`cover_image` 非空，`description` 非空，`best_season="Autumn"`
