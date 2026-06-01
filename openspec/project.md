# Project Spec

> 项目级根 spec。所有 `specs/` 与 `changes/` 都建立在本文件描述的上下文之上。

## 项目名称

my-first-project

## 愿景

> 待你填写：一句话说清这个项目要解决什么问题、给谁用。

## 范围（in scope）

> 待你填写：明确做什么。例如：
> - 一个命令行工具，输入 X 输出 Y
> - 一个 Web 服务，提供 A/B/C 三个 API

## 非目标（out of scope）

> 待你填写：明确**不**做什么，避免日后争论。例如：
> - 不提供图形界面
> - 不支持 Windows
> - 不做用户登录

## 关键术语

| 术语 | 含义 |
|---|---|
| <Term1> | <定义> |
| <Term2> | <定义> |

## 技术栈

本项目使用前后端分离架构。后端 Spring Boot 负责业务 HTTP API；前端 Next.js 同时承担 UI 与薄 BFF（SSR 预取 / 接口聚合 / 字段裁剪 / 缓存读），**业务逻辑一律在后端**。

| 维度 | 选型 | 说明 |
|---|---|---|
| 语言 | Java 17 (Corretto) | 与 Spring Boot 3.x 兼容下限 |
| 后端框架 | Spring Boot 3.3.5 | spring-boot-starter-web |
| 后端构建 | Maven 单模块 (`backend/pom.xml`) | groupId `com.mooc`、artifactId `app`、打包 jar |
| 后端测试 | JUnit 5 + Spring Boot Test (`@WebMvcTest`) | 切片测试为主，避免全量上下文 |
| 前端框架 | React 19 + Next.js 16 (App Router) + TypeScript 5 | 薄 BFF 路由：`app/page.tsx` Server Component 预取，`app/HelloMessage.tsx` Client Component 呈现 |
| 前端样式 | Tailwind CSS 4 + shadcn/ui (base-nova / neutral) + lucide-react | shadcn 提供 a11y / 设计 token / Radix 实现；lucide 统一图标 |
| 前端构建 | Next.js 16 内建 (`frontend/`) | dev server 起于 3000（8080 为后端，被占时自动 fallback 到下一个可用端口） |
| 前端测试 | Vitest + @testing-library/react + happy-dom | Server Component 不可直接 render，需抽为 Client Component 后覆盖 |
| BFF 调用 | `frontend/lib/backend.ts`（`import 'server-only'`） | Server Component 中用 `fetchFromBackend('/api/...')` 调后端，无 CORS 问题 |
| 环境变量 | `frontend/.env.local`（不入仓） | `BACKEND_URL=http://localhost:8080` |
| Node 运行时 | Node.js ≥ 20.19 | Next.js 16 要求 |

变更记录见 `openspec/changes/archive/`。

## OpenSpec Conventions

本项目对 OpenSpec 工作流的额外约定（与 OpenSpec 官方 schema 兼容，但补充粒度规则）：

### Capability 粒度：每 change 一个 capability（精细粒度）

- 每个 OpenSpec change 对应**一个独立 capability**，命名与 change 名一致（kebab-case）。
- 例：change `frontend-styling-stack` → capability `frontend-styling`；change `homepage-shell` → capability `homepage-shell`。
- 选这个粒度的理由：archive 时 `openspec/specs/<capability>/spec.md` 各归各位、零冲突，支持 6+ 个区块 change 并行 apply。
- 不建议把多个 change 写到同一个 capability（会让 archive merge 时反复编辑同一文件，增加冲突面）。

### `openspec/notes/` 的角色

- `openspec/notes/<topic>/<name>.md` 存放**人类可读的工程 brief**——结构化但非 OpenSpec schema 格式（如 4 章节中文模板：边界 / 场景 / 数据结构 / Acceptance）。
- OpenSpec CLI **不会**扫到 `notes/`，仅 `specs/` 与 `changes/` 进入工作流。
- brief 用途：propose 阶段作为 LLM 上下文喂入；review 阶段作为团队对齐文档；不参与 archive 合入。
- 与 `openspec/specs/<capability>/spec.md`（capability 主索引，由 archive 自然填充）严格分工。

### Change 与 brief 的对照

| Change | Brief 路径 |
|---|---|
| `frontend-styling-stack` | `openspec/notes/homepage/frontend-styling-stack.md` |
| `homepage-shell` | `openspec/notes/homepage/homepage-shell.md` |
| `homepage-hero` | `openspec/notes/homepage/homepage-hero.md` |
| `homepage-feature-nav` | `openspec/notes/homepage/homepage-feature-nav.md` |
| `homepage-city-grid` | `openspec/notes/homepage/homepage-city-grid.md` |
| `homepage-hot-posts` | `openspec/notes/homepage/homepage-hot-posts.md` |
| `homepage-hot-spots` | `openspec/notes/homepage/homepage-hot-spots.md` |
| `homepage-ai-launcher` | `openspec/notes/homepage/homepage-ai-launcher.md` |

## 质量底线

- 所有改动走 TDD（见 `.qoder/skills/test-driven-development/`）。
- 主分支测试始终绿灯。
- 公开 API 改动必须先有对应 spec 更新。

## 维护

本文件每次 `/archive` 时检查是否需要更新。重大变化在对应 change 的 `design.md` 中写理由。
