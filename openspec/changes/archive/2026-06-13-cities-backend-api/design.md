## Context

项目是旅游平台 WanderChina，后端 Spring Boot 3.3.x + MySQL，前端 Next.js。现有模块：auth（用户/认证）、posts（帖子 CRUD/投票/评论/收藏）。城市模块是景点模块的前置依赖，前端首页 City Grid 已硬编码 8 个城市但无后端支撑。

当前 `application.yml` 使用 `ddl-auto: update`，无 `data.sql` 机制，无种子数据加载历史。

## Goals / Non-Goals

**Goals:**
- 建立 `CityEntity` + 标准分层（repository / service / controller）
- 提供只读 `GET /api/cities`（分页）和 `GET /api/cities/{id}`（详情）接口
- 通过 `data.sql` 注入 8 个种子城市（与前端 `cityGrid.data.ts` 对齐）
- 无需认证（城市数据为公开只读）

**Non-Goals:**
- 不实现城市 CRUD 的写入接口（创建/更新/删除）——Phase 1 只读
- 不做 slug 查询接口（`/api/cities/by-slug/{slug}`）——留给后续需要时再加（YAGNI）
- 不做城市与景点的关联查询接口——在 spots-backend-api change 中处理
- 不做前端对接——在后续独立 change 中处理

## Decisions

### D1：`bestSeason` 用 `String` 而非 `Enum`

**决策**：`bestSeason` 字段类型为 `VARCHAR(50)` / Java `String`。

**理由**：旅游场景季节表达灵活（"Spring & Autumn"、"All year round"），枚举会过度约束。前端现有数据也是简单字符串。

**备选**：`Enum Season { SPRING, SUMMER, AUTUMN, WINTER }` —— 排除，无法表达组合值。

---

### D2：种子数据用 `data.sql` + `INSERT IGNORE`

**决策**：使用 Spring Boot `data.sql` 机制，SQL 语句用 MySQL `INSERT IGNORE INTO cities` 确保幂等。

**配置变更**（`application.yml`）：
```yaml
spring:
  jpa:
    defer-datasource-initialization: true
  sql:
    init:
      mode: always
```

**理由**：
- `INSERT IGNORE`：重复启动时跳过已存在行（通过 `slug` UNIQUE 约束判断），不报错
- `defer-datasource-initialization: true`：等 Hibernate DDL 执行完再跑 `data.sql`，否则表不存在
- `mode: always`：每次启动都执行（`embedded` 仅对 H2 生效，本项目用 MySQL）

**备选**：`CommandLineRunner` Java 代码 —— 排除，城市数据是静态参考数据，SQL 更直接、更易维护。

---

### D3：列表接口采用标准分页，无 cursor

**决策**：`GET /api/cities?page=1&size=20`，返回 `{ items, total, page, size }`，不含 `next_cursor` / `has_more`。

**理由**：城市总量极少（<100），无需 cursor 分页；标准分页与 API 规约对齐，前端可用 page 直接跳转。

**备选**：cursor 分页（posts 模块用的）—— 排除，城市场景不需要无限滚动。

---

### D4：`CityListResponse` 不含 `next_cursor`

**决策**：`CityListResponse` 只含 `items / total / page / size` 四个业务字段，不含 cursor 相关字段。

**理由**：YAGNI——城市列表不需要无限滚动，标准分页够用。

---

### D5：接口无需认证

**决策**：`CityController` 不注入 `JwtService`，不检查 Authorization header。

**理由**：城市是公开参考数据，任何人可查看。与 `PostController` 中部分公开接口（`GET /api/posts`）保持一致模式。

---

### D6：`CityEntity` 字段命名对齐前端 `cityGrid.data.ts`

| Java 字段 | DB 列名 | 前端字段 | 说明 |
|-----------|---------|---------|------|
| `name` | `name` | `label` | 英文名（必填） |
| `nameZh` | `name_zh` | `labelZh` | 中文名 |
| `slug` | `slug` | — | URL slug（唯一） |
| `coverImage` | `cover_image` | `image` | 封面图 URL |
| `description` | `description` | `description` | 英文描述 |
| `bestSeason` | `best_season` | `bestSeason` | 最佳季节 |

> 注：前端字段名（`label`/`labelZh`/`image`）与后端不一致，在后续前端对接 change 中处理字段映射。

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|---------|
| `INSERT IGNORE` 在 `slug` UNIQUE 冲突时静默跳过，可能掩盖其他列约束错误 | `data.sql` 仅含 INSERT，其他约束（NOT NULL）由 Entity 层保证 |
| `mode: always` 在生产环境每次都跑种子 SQL | 当前为开发阶段；生产部署前切换为 `mode: never` 或改用 Flyway |
| 前后端字段名不一致（`label` vs `name`） | 后续前端对接 change 中通过 API 客户端映射处理 |

## Migration Plan

1. 新增文件，不修改任何现有 Java 代码
2. `application.yml` 追加 2 行配置（`defer-datasource-initialization` + `sql.init.mode`）
3. 重启后端 → Hibernate 建表 → `data.sql` 写入种子数据 → 接口可用
4. 回滚：删除 `data.sql` + 移除配置 → 表仍在（`ddl-auto: update` 不删表），手动 `DROP TABLE cities` 即可
