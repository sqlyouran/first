## 1. 规约文档更新

- [x] 1.1 编辑 `.qoder/rules/database-conventions.md`：将第一行描述从 `后端使用 JPA (Hibernate) + PostgreSQL（开发阶段 H2 内存库）` 改为 `后端使用 JPA (Hibernate) + MySQL（生产目标 PostgreSQL）`
- [x] 1.2 编辑 `.qoder/rules/database-conventions.md` 第 70-74 行"开发环境"小节：H2 + create-drop 改为 MySQL 8（`jdbc:mysql://localhost:3306/wanderchina`）+ `ddl-auto: update`；H2 仅用于 test scope 单元测试
- [x] 1.3 编辑 `.qoder/rules/backend-conventions.md` 第 31 行 Service 小节：在"构造器注入"条目下追加例外——可选依赖（如 AI/RAG 扩展模块）允许 `@Autowired(required = false)`，核心业务 Service 仍必须构造器注入

## 2. 实体枚举列 length 补全

- [x] 2.1 修改 `backend/src/main/java/com/mooc/app/entity/PostEntity.java` 第 42 行：`@Column(nullable = false)` → `@Column(nullable = false, length = 20)`
- [x] 2.2 修改 `backend/src/main/java/com/mooc/app/entity/SpotEntity.java` 第 61 行：`@Column(nullable = false)` → `@Column(nullable = false, length = 20)`
- [x] 2.3 修改 `backend/src/main/java/com/mooc/app/entity/VoteEntity.java` 第 22 行：`@Column(name = "vote_type", nullable = false)` → `@Column(name = "vote_type", nullable = false, length = 20)`

## 3. 验证

- [x] 3.1 后端编译通过：`cd backend && ./mvnw compile -q`
- [x] 3.2 后端测试通过：`cd backend && ./mvnw test -q`
- [ ] 3.3 人工确认：重启后端服务后，`SHOW CREATE TABLE posts` / `spots` / `votes` 的 status/vote_type 列 VARCHAR(20)
