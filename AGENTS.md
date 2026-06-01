# AGENTS.md

本仓库是 **AIWorkSpace** —— 一个由 AI coding agent 驱动、Spec-Driven 的多仓工作区。任何 agent（Qoder / Claude Code / Codex / Cursor 等）进入仓库时，**先读这一份**。

## 仓库拓扑

| 角色 | Git 仓库 | 路径 | 内容 |
|---|---|---|---|
| 工作区父仓 | https://github.com/sqlyouran/first | `.` | Harness（`.qoder/`）+ Spec（`openspec/`）+ submodule 指针 |
| Backend submodule | https://github.com/sqlyouran/first_backend | `backend/` | Java 17 + Spring Boot 3.3.5，HTTP API（端口 8080） |
| Frontend submodule | https://github.com/sqlyouran/first_frontend | `frontend/` | Next.js 16 (App Router) + React 19 + TypeScript，UI 与薄 BFF（端口 3000） |

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

### `frontend/` — Next.js + React UI / 薄 BFF

- 仓库：https://github.com/sqlyouran/first_frontend
- 启动：`cd frontend && npm install && npm run dev` → `http://localhost:3000`（3000 被占时自动 fallback到下一个可用端口）
- 构建：`npm run build`
- 测试：`npm test`（Vitest + React Testing Library）
- 工具链：Node ≥ 20.19 / Next.js 16 / React 19 / TypeScript 5

## 技术选型约束

本项目定位为**线上可持续运行迭代**的产品（非一次性 MVP），所有选型决策围绕"长期可维护"展开，不为短期开发速度妥协长期工程性。

### 场景前提

- **生命周期**：长期运营，持续迭代（非 8 周一次性 MVP）
- **团队基线**：前端 React 经验充足；后端 Spring Boot 经验充足
- **部署形态**：前端 Vercel / 后端 Docker 自托管
- **协作模式**：AI 辅助开发为主，spec-driven + TDD

### 决策维度优先级（长期场景下）

按权重从高到低：

1. **可持续迭代能力**（强类型、严格分层、重构友好）
2. **生态成熟度**（分布式事务 / 消息队列 / 批处理 / 可观测性 / APM 开箱即用）
3. **框架约定强度**（多人协作不跑偏，新人上手有路径）
4. **团队学习成本**（已有经验直接归零，禁止为了新潮翻栈）
5. **AI 生成质量**（重要，但不是第一优先级；可通过 OpenAPI 契约 + spec-driven 流程补齐跨语言对齐成本）
6. 部署敏捷度（长期看 Docker/K8s 与 Vercel 持平，不构成决定性因素）

> 注意：在 MVP 短周期场景下，优先级会反转（AI 生成质量、部署敏捷度上浮）。本项目**不适用**该反转。

### 锁定栈

| 层 | 选型 | 决定性理由 |
|---|---|---|
| 前端 | **React 19 + Next.js 16（App Router）+ TypeScript** | SSR/SEO 能力 + 文件路由约定 + Vercel 原生部署；Next.js 仅作薄 BFF，不承担业务逻辑 |
| 样式 | **Tailwind CSS 4 + shadcn/ui (base-nova / neutral) + lucide-react** | shadcn 提供 a11y / 设计 token / Radix 实现；lucide 统一图标 |
| 后端 | **Spring Boot 3.3.x** | 团队经验 + 生态完备 + 分层约定强 + 长期可维护 |
| 接口契约 | **OpenAPI / springdoc-openapi** | 后端生成 schema，前端用 `openapi-typescript` 生成 TS 类型，弥补跨语言上下文 |
| 数据库 | Postgres | OLTP + JSON 兼容 |

### 禁止动作（除非走 propose 流程推翻）

- ❌ 把后端切到 Next.js API Routes / Server Actions（仅适用于短周期 MVP，不适用本项目长期场景）
- ❌ 把前端切到 Vue / Nuxt / Svelte 等非 React 系（团队学习成本归零原则）
- ❌ 引入 Tailwind + shadcn/ui + lucide-react 之外的其它 CSS 方案（styled-components / emotion / vanilla-extract / MUI / Chakra / Ant Design 等）
- ❌ 用 "AI 生成质量更高" 单一理由推翻已锁定栈（须同时满足长期工程性维度）

#### Next.js BFF 边界（必读约束）

前端是薄 BFF，不是业务后端。违反这些边界需重新 propose：

- ✅ **允许**（薄 BFF 范围）：Server Component SSR 预取 / 多接口聚合 / 字段裁剪 / 缓存读（`fetch` 的 `cache` 与 `next.revalidate`）
- ❌ **禁止**（业务后端范围）：在 Route Handlers (`app/api/**/route.ts`) 写入业务、在 Server Actions 实现鉴权写 / 事务 / 领域逻辑、写数据库 / 操作消息队列 / 状态机
- 薄 BFF 可验收：`frontend/lib/backend.ts` 首行 `import 'server-only'`；codebase 内不出现 `app/api/**/route.ts`

### 何时需要重新评估

触发任一条件，必须发起 `/opsx:propose` 重新评审本节：

1. 业务定位变更（如转向短周期试错型项目）
2. 团队人员结构剧烈变动（如 Spring Boot / React 经验流失）
3. 出现明确性能 / 可维护性瓶颈，且现有栈无法通过常规手段解决

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
