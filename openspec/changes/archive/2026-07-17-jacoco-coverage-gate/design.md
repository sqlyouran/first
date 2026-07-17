## Context

**当前状态**：
- 后端 176 个源文件 / 69 个测试文件，全局 line 覆盖率 75.1%，service 层 59.5%，controller 层 98.5%
- 已完成 `@DirtiesContext` → `@Transactional` 优化（全量测试从 ~360s 降至 125s）
- 5 个测试类仍用 `@DirtiesContext`（因内存状态污染：RateLimitService fallback、VectorStore mock）
- `pom.xml` 无 JaCoCo 插件，无覆盖率检查，无 git hooks
- `backend` 是 git submodule，hook 文件存在 `.git/modules/backend/hooks/`

**约束**：
- 不引入新运行时依赖（JaCoCo 仅构建插件）
- 不改变现有测试逻辑（只加注解标签）
- hook 脚本必须能在 submodule 场景下工作

## Goals / Non-Goals

**Goals:**
- 每次 `mvn verify` 自动检查分层覆盖率，不达标则 BUILD FAILURE
- 开发者 commit 前自动拦截低覆盖率代码（快速测试 + JaCoCo check）
- 开发者 push 前跑全量测试（含慢测试）+ JaCoCo check
- 覆盖率门槛分 3 阶段递增，不阻塞当前开发节奏

**Non-Goals:**
- 不配置 GitHub Actions CI（独立 change）
- 不接入前端 Vitest 覆盖率（独立 change）
- 不做增量覆盖率检查（只看全量，简单可靠）
- 不改测试用例本身的逻辑或断言

## Decisions

### D1: JaCoCo 版本与集成方式

**选择**：`jacoco-maven-plugin 0.8.12`，通过 `pluginManagement` + `plugins` 双层配置

**理由**：
- 0.8.12 是最新稳定版，支持 Java 17
- `pluginManagement` pin 版本避免子模块继承冲突
- 三个 execution goal 分离职责：`prepare-agent`（挂载采集器）→ `report`（生成 HTML/CSV/XML）→ `check`（门禁断言）

**替代方案**：
- Cobertura：已停止维护
- IntelliJ Coverage：IDE 绑定，CLI 不可用

### D2: 分层门禁规则

**选择**：用 JaCoCo `<rules>` 按 `PACKAGE` 粒度设不同门槛

```
BUNDLE (全局):  LINE ≥ 0.70
PACKAGE service:  LINE ≥ 0.55
PACKAGE controller: LINE ≥ 0.90
```

**理由**：
- service 层是业务核心但覆盖率最低（59.5%），需要单独卡线防止倒退
- controller 层覆盖率极高（98.5%），卡 90% 留足缓冲
- 全局兜底防止其他包（entity/dto/filter）覆盖率暴跌

**替代方案**：
- 全局一刀切 70%：遮住了 service 层 59.5% 的债务
- 按类粒度卡：太细，维护成本高

### D3: 排除规则

**选择**：排除 `AppApplication`、`config/**`、`dto/**`

**理由**：
- 启动类只有 `main()` 方法，测不了也不该测
- 配置类是 Spring 胶水代码
- DTO 的 getter/setter/record 占大量行数，拉高覆盖率数字但无实际价值

### D4: Hook 分发机制

**选择**：`backend/hooks/` 目录入仓 + `scripts/install-hooks.sh` 安装脚本

**理由**：
- hook 脚本入版本控制，团队共享
- 安装脚本用 `cp` 复制到 `$(git rev-parse --git-dir)/hooks/`
- submodule 场景下 `$(git rev-parse --git-dir)` 解析为 `.git/modules/backend`，正确路由

**替代方案**：
- `core.hooksPath`：全局配置，影响开发者其他项目
- Husky (Node.js)：引入前端依赖到后端，不合理
- pre-commit framework (Python)：引入 Python 依赖，增加环境复杂度

### D5: 测试分级（快速 vs 慢速）

**选择**：`@Tag("slow")` 标注慢测试，pre-commit 排除，pre-push 跑全量

**理由**：
- 5 个 `@DirtiesContext` 类 + AI 测试每次启动 Spring 容器 ~2-3s，全量 125s
- pre-commit 跑快速测试 ~40s，可接受的提交体验
- pre-push 跑全量 ~125s，push 频率低可接受
- `@Tag` 是 JUnit 5 标准机制，与 surefire 的 `-Dgroups` 配合

**需要标注 `@Tag("slow")` 的类**（5 个）：
- `BookmarkControllerTest`（13 用例，33.8s）
- `CommentControllerTest`（12 用例，20.6s）
- `SpotBookmarkControllerTest`（8 用例，7.9s）
- `SpotCommentControllerTest`（6 用例，7.0s）
- `AiChatServiceRagTest`（3 用例，2.1s）

### D6: Hook 触发条件

**选择**：检测 `git diff --cached --name-only` 是否包含 `.java` 文件

**理由**：
- 只改 markdown/yaml/css 时不跑测试，避免无意义等待
- 简单 grep 判断，无额外依赖

## Risks / Trade-offs

| 风险 | 等级 | 缓解 |
|------|------|------|
| Hook 不被 clone 带过去 | 中 | 安装脚本 + README 说明；CI 做兜底 |
| `--no-verify` 可跳过 hook | 低 | 故意保留逃生门；CI PR 检查是最后防线 |
| 全量测试 125s 仍偏长 | 中 | pre-commit 只跑快速测试（~40s）；后续优化 `@DirtiesContext` 类 |
| DTO 排除后覆盖率数字变化 | 低 | 排除使数字更真实；Phase 1 门槛已预留余量 |
| Phase 2/3 门槛提高时部分类不达标 | 中 | 渐进式提门槛，给团队 2-4 周补测试的时间 |
