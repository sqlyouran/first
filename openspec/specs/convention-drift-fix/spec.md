### Requirement: 规约文档与代码现状对齐
`.qoder/rules/` 下的规约文档 SHALL 准确反映项目当前的技术栈与实现方式，不得描述已被替换的技术方案。

#### Scenario: database-conventions 开发环境描述与实际一致
- **WHEN** 开发者阅读 database-conventions.md 的"开发环境"小节
- **THEN** 文档描述 MySQL 8 + `ddl-auto: update`（非 H2 + create-drop）

#### Scenario: backend-conventions 覆盖可选依赖模式
- **WHEN** 开发者在 Service 中需要注入可选组件（如 AI/RAG 扩展）
- **THEN** backend-conventions 明确允许 `@Autowired(required = false)` 用于非核心可选依赖

### Requirement: 所有枚举列声明 length
每个使用 `@Enumerated(EnumType.STRING)` 的字段 SHALL 同时声明 `@Column(length = N)`，N 与项目统一取值保持一致。

#### Scenario: PostEntity.status 有 length 属性
- **WHEN** 检查 PostEntity.status 的 @Column 注解
- **THEN** 包含 `length = 20`

#### Scenario: SpotEntity.status 有 length 属性
- **WHEN** 检查 SpotEntity.status 的 @Column 注解
- **THEN** 包含 `length = 20`

#### Scenario: VoteEntity.voteType 有 length 属性
- **WHEN** 检查 VoteEntity.voteType 的 @Column 注解
- **THEN** 包含 `length = 20`
