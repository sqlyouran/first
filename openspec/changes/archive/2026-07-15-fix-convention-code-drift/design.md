## Context

项目在从 H2 迁至 MySQL 后，`application.yml` 和 `pom.xml` 已更新，但 `.qoder/rules/database-conventions.md` 仍描述旧的开发环境。同时 AI 模块引入可选依赖（KnowledgeSearchService、SpotQueryTool），`AiChatService` 和 `AiConfig` 使用了 `@Autowired(required = false)` 但 backend-conventions 没有覆盖这一模式。此外，3 个实体枚举列未声明 `@Column(length=N)`，与 database-conventions 的枚举持久化规约不一致（其他 5 个枚举列均已声明 length=20）。

## Goals / Non-Goals

**Goals:**
- 规约文档与代码现状完全对齐（单一事实源）
- 补全 3 个实体枚举列的 length 属性，消除 schema 隐患

**Non-Goals:**
- 不做数据库迁移（已在 MySQL 上运行）
- 不重构 `@Autowired` 用法（当前是合理的可选依赖模式）
- 不修改任何业务逻辑或 API 行为

## Decisions

### D1: 开发环境描述更新

**选择**：将 database-conventions.md 的"开发环境"小节从 H2 + create-drop 改为 MySQL 8 + update。

**理由**：`application.yml` 已指向 `jdbc:mysql://localhost:3306/wanderchina`，`ddl-auto: update`。H2 仅保留在 pom.xml 的 test scope 中供单元测试使用。

**替代方案**：保留双环境描述（H2 用于纯本地快启 / MySQL 用于开发）— 放弃，因为当前无此分流，保持简单。

### D2: 枚举列 length 统一取 20

**选择**：PostEntity.status、SpotEntity.status、VoteEntity.voteType 均添加 `@Column(length = 20)`。

**理由**：与项目已有模式一致（UserEntity.state、AiMessage.role、BookmarkEntity.entityType、CommentEntity.entityType 均用 length=20）。最长枚举值 `PUBLISHED`=9 字符，20 留有充足余量。

### D3: `@Autowired(required = false)` 例外条款

**选择**：在 backend-conventions 的"Service"小节下追加例外说明：

> 可选依赖（如 AI/RAG 等扩展功能模块）允许使用 `@Autowired(required = false)` 注入。核心业务 Service 仍必须使用构造器注入。

**理由**：KnowledgeSearchService 和 SpotQueryTool 是可选组件（MCP/Chroma 可能未启用），强行构造器注入会导致启动失败。这是 Spring 官方推荐的可选依赖模式。

## Risks / Trade-offs

- **[Risk] 枚举列 length 变更后 Hibernate update 是否自动 ALTER** → Mitigation：MySQL 下 `ddl-auto: update` 会自动扩展 VARCHAR 列长度，不会丢数据。重启后验证 `SHOW CREATE TABLE` 确认。
- **[Risk] 规约更新后被 AI agent 重新读取时行为变化** → Mitigation：本次变更是让规约追上代码，不引入新约束，对 agent 行为无负面影响。
