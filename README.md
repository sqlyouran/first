# my-first-project

一个基于 **Harness + OpenSpec + Superpowers** 三大理念初始化的 AI coding 项目骨架。

## 这是什么

它不是一个业务项目，而是一套**给 AI 编码 agent 用的工作流脚手架**：

- **Harness**：本仓库针对 Qoder，配置在 `.qoder/`
- **OpenSpec**（[Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)）：通过 `openspec init --tools qoder` **真实初始化**，CLI 由 `@fission-ai/openspec` 提供
- **Superpowers**（[obra/superpowers](https://github.com/obra/superpowers)）：8 个核心 skills 的本地化模板，与 OpenSpec 官方 skill 共存

## 目录速览

```
.
├── AGENTS.md              # AI agent 入口（先读这个）
├── .qoder/                # Harness 层
│   ├── rules/             # always-on 规则
│   ├── commands/          # 斜杠命令（propose/apply/archive）
│   ├── agents/            # subagent 定义
│   └── skills/            # superpowers 风格 skills
├── openspec/              # Spec 层
│   ├── project.md         # 项目愿景与范围
│   ├── specs/             # 已稳定的能力 spec
│   └── changes/           # 进行中的变更提案
├── backend/                # Spring Boot 后端（0002 变更后）
└── frontend/               # Vite + React 前端（0002 变更后）
```

## 怎么用

1. 重启 Qoder 让 OpenSpec 注入的斜杠命令生效。
2. 用 `/opsx:propose 加一个 hello world 命令行工具` 开局。
3. OpenSpec 会按流程生成 `openspec/changes/<name>/{proposal,design,tasks}.md`，等你签字。
4. 用 `/opsx:apply` 推进实现——superpowers 的 `test-driven-development` skill 会自动触发，强制 RED→GREEN→REFACTOR。
5. 完成后 `/opsx:archive` 归档。

## 依赖

- **Node.js ≥ 20.19**（OpenSpec CLI 要求，前端同样依赖）。本机用 nvm 管理。
- **JDK 17**（Corretto / Temurin 均可）。
- **Maven ≥ 3.6.1**（老版本本仓库已在 `backend/pom.xml` 中钉住了兼容插件版本；Maven 3.6.3+ 则可拆除那段 `pluginManagement`）。
- 仓库**未** `git init`，运行 `git init` 自行开始。

## 本地开发

> 后端跟前端要起两个终端；前端通过 Vite proxy 把 `/api` 路由给后端。

```bash
# 终端 A：后端（启动后监听 localhost:8080）
mvn -f backend/pom.xml spring-boot:run

# 终端 B：前端（启动后监听 localhost:5173）
cd frontend && npm install && npm run dev
```

打开浏览器访问 <http://localhost:5173/>，看到页面显示 `Backend says: hello` 即代表前后端联调通了。

### 跳测试

```bash
mvn -f backend/pom.xml test
```

### 端口 / 代理约定

| 路径 | 运行位置 | 说明 |
|---|---|---|
| `http://localhost:8080/api/hello` | Spring Boot | 返回纯文本 `hello` |
| `http://localhost:5173/` | Vite dev server | React 页面 |
| `http://localhost:5173/api/*` | Vite proxy | 转发到 `http://localhost:8080/api/*` |

## 升级 OpenSpec

```bash
npx @fission-ai/openspec@latest update
```
