# AGENTS.md

本仓库是 **AIWorkSpace** —— 一个由 AI coding agent 驱动、Spec-Driven 的多仓工作区。任何 agent（Qoder / Claude Code / Codex / Cursor 等）进入仓库时，**先读这一份**。

## 仓库拓扑

| 角色 | Git 仓库 | 路径 | 内容 |
|---|---|---|---|
| 工作区父仓 | https://github.com/sqlyouran/first | `.` | Harness（`.qoder/`）+ Spec（`openspec/`）+ submodule 指针 |
| Backend submodule | https://github.com/sqlyouran/first_backend | `backend/` | Java 17 + Spring Boot 3.3.5，HTTP API（端口 8080） |
| Frontend submodule | https://github.com/sqlyouran/first_frontend | `frontend/` | Vite 8 + React 19，UI（端口 5173） |

> 父仓只追踪两个子仓的 commit SHA，**不直接持有业务代码**。业务代码写在对应 submodule 内。

### 首次 clone 必须 `--recursive`

```bash
git clone --recursive https://github.com/sqlyouran/first.git
# 已 clone 但 submodule 是空目录时：
git submodule update --init --recursive
```

### 升级 submodule 指针

子仓 push 后，父仓需要更新指针：

```bash
cd backend && git pull origin main && cd ..
git add backend
git commit -m "bump: backend -> <new-sha>"
git push
```

frontend 同理。

## 三层架构（父仓内的治理层）

| 层 | 目录 | 职责 |
|---|---|---|
| Harness | `.qoder/` | 当前 IDE 的 agent 配置（rules / skills / commands / agents） |
| OpenSpec | `openspec/` | Spec-driven 工作流：先对齐 spec，再写代码 |
| Superpowers | `.qoder/skills/` | 可组合的 skill 方法论，自动触发 |

## 子模块说明

### `backend/` — Spring Boot HTTP 服务

- 仓库：https://github.com/sqlyouran/first_backend
- 包名：`com.mooc.app`，启动类 `AppApplication`
- 启动：`mvn -f backend/pom.xml spring-boot:run` → `http://localhost:8080`
- 测试：`mvn -f backend/pom.xml test`
- 工具链：JDK 17 / Maven 3.6.1（pluginManagement pin maven-compiler-plugin@3.10.1 + maven-surefire-plugin@2.22.2）

### `frontend/` — Vite + React UI

- 仓库：https://github.com/sqlyouran/first_frontend
- 启动：`cd frontend && npm install && npm run dev` → `http://localhost:5173`
- 构建：`npm run build`
- 工具链：Node 20.20.2 / Vite 8 / React 19

## 硬规则（不可违反）

1. **任何代码改动前必须先走 OpenSpec 流程**：在父仓 `openspec/changes/<change-name>/` 下产出 `proposal.md` → `design.md` → `tasks.md`，人类签字后才动 submodule 内的代码。
2. **业务改动落在 submodule 内**：`backend/` 和 `frontend/` 是独立 git 仓库，`git add` / `commit` / `push` 都要在子仓目录内执行；父仓只追加 submodule 指针。
3. **TDD 不可绕过**：实现阶段严格 RED → GREEN → REFACTOR，先写失败测试。
4. **YAGNI / DRY**：不做没要求的事，不搞预防性抽象。
5. **变更完成后归档**：把 `openspec/changes/<name>/` 移入 `openspec/changes/archive/<date>-<name>/`，并在父仓同步更新对应 submodule 指针。

## 快速入口

- 编码规约：[`.qoder/rules/coding-conventions.md`](.qoder/rules/coding-conventions.md)
- 工作流规则：[`.qoder/rules/spec-driven-workflow.md`](.qoder/rules/spec-driven-workflow.md)
- OpenSpec 官方命令：`.qoder/commands/opsx/{propose,apply,archive,explore}.md`
- OpenSpec 官方 skills：`.qoder/skills/openspec-{propose,apply-change,archive-change,explore}/SKILL.md`
- Superpowers skills：`.qoder/skills/{brainstorming,writing-plans,executing-plans,test-driven-development,subagent-driven-development,using-git-worktrees,requesting-code-review,verification-before-completion}/SKILL.md`
- OpenSpec 配置：[`openspec/config.yaml`](openspec/config.yaml)
- 项目级 spec：[`openspec/project.md`](openspec/project.md)
- 当前进行中的变更：`openspec/changes/`

## 第一次使用

本项目用 `openspec init --tools qoder` 初始化，斜杠命令由 OpenSpec CLI 提供：

- `/opsx:propose <idea>` — 创建变更（生成 proposal/design/tasks）
- `/opsx:apply` — 按 tasks.md 推进实现（走 superpowers 的 TDD skill）
- `/opsx:archive` — 归档完成的变更
- `/opsx:explore` — 浏览已有 specs 与 changes

> 重启 Qoder 让斜杠命令生效。
