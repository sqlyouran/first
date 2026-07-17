## Why

项目当前没有测试覆盖率检查和自动化门禁。虽然已完成测试性能优化（`@DirtiesContext` → `@Transactional`，提速 2.9x），但缺少覆盖率基线和自动检查，新增代码的测试质量无法保障。引入 JaCoCo + pre-commit hook 可以在提交前自动拦截低覆盖率的代码，防止技术债累积。

## What Changes

- **pom.xml 集成 JaCoCo 插件**：添加 `jacoco-maven-plugin 0.8.12`，配置 `prepare-agent`（采集覆盖率）+ `report`（生成报告）+ `check`（门禁检查）三个执行目标
- **分层覆盖率门禁规则**：
  - Phase 1（立即生效）：service 层 ≥55%，controller 层 ≥90%，全局 ≥70%
  - Phase 2（2 周后）：service 层 ≥65%，controller 层 ≥90%，全局 ≥75%
  - Phase 3（1 月后）：service 层 ≥75%，controller 层 ≥90%，全局 ≥80%
- **覆盖率排除规则**：排除 `AppApplication`（启动类）、`config/**`（配置类）、`dto/**`（getter/setter 噪音）
- **pre-commit hook 机制**：
  - 在 `backend/hooks/` 目录存放 hook 脚本，入版本控制
  - 提供 `backend/scripts/install-hooks.sh` 安装脚本（`cp hooks/* → .git/hooks/`）
  - hook 检测 staged 文件是否包含 `.java`，无变更则跳过
  - 有变更时运行 `mvn test -Dgroups='!slow'`（排除慢测试）+ JaCoCo check
- **@Tag("slow") 标注**：给使用 `@DirtiesContext` 的 5 个类、依赖外部 API 的测试加 `@Tag("slow")`，pre-commit 跳过
- **pre-push hook**：跑全量测试（含 `@Tag("slow")`）+ JaCoCo check
- **CI 兜底**：GitHub Actions 跑 `mvn verify`，PR 级别强制覆盖率门禁

## Capabilities

### New Capabilities

- `jacoco-coverage-check`：JaCoCo Maven 插件集成 + 分层覆盖率规则配置 + 排除规则
- `git-hooks-coverage`：pre-commit / pre-push hook 脚本 + 安装机制 + 智能触发（仅 Java 文件变更时）
- `slow-test-tagging`：给慢测试加 `@Tag("slow")` 标签，支持 hook 分级执行

### Modified Capabilities

（无现有 spec 需要修改）

## Impact

- **后端构建**：`pom.xml` 新增 JaCoCo 插件（无新依赖，仅构建插件）
- **测试代码**：5 个测试类加 `@Tag("slow")` 注解（不改测试逻辑）
- **开发者工作流**：首次 clone 需跑 `./scripts/install-hooks.sh`；后续 commit 自动触发覆盖率检查
- **Git 结构**：`backend/hooks/` + `backend/scripts/` 新增目录（入 backend 子仓版本控制）
- **CI/CD**：需配置 GitHub Actions 跑 `mvn verify`（独立 change，本 change 不含 CI 配置）
