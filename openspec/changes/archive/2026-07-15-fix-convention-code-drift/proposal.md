## Why

规约文档与代码现状出现 3 处漂移：database-conventions 仍声明 H2 + create-drop（实际已迁至 MySQL + update）；backend-conventions 禁止 `@Autowired` 但未覆盖可选依赖的例外场景；3 个实体枚举列缺少 `@Column(length=N)` 属性。规约是团队协作的单一事实来源，漂移会降低其可信度并误导后续开发。

## What Changes

- 更新 `.qoder/rules/database-conventions.md`：开发环境描述从 H2 + create-drop 改为 MySQL + update，保留"生产目标 PostgreSQL + Flyway"的演进方向
- 更新 `.qoder/rules/backend-conventions.md`：在"构造器注入"条目下补充可选依赖例外说明（`@Autowired(required = false)` 允许用于非核心可选组件）
- 修复 `PostEntity.status`、`SpotEntity.status`、`VoteEntity.voteType` 三个枚举列，添加 `@Column(length = N)` 属性

## Capabilities

### New Capabilities
（无新增 capability）

### Modified Capabilities
（无 spec 级别的行为变更；本次仅修正规约文档与代码注解，不涉及 API 或业务逻辑变化）

## Impact

- **规约文档**：`database-conventions.md`、`backend-conventions.md`（仅 `.qoder/rules/` 内部）
- **后端代码**：`PostEntity.java`、`SpotEntity.java`、`VoteEntity.java`（仅添加 `length` 属性，无行为变更）
- **数据库 schema**：Hibernate `ddl-auto: update` 会自动同步列长度，无需手动 migration
- **API / 前端**：无影响
