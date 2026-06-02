# Project Spec

> 项目级根 spec。所有 `specs/` 与 `changes/` 都建立在本文件描述的上下文之上。

## 项目名称

Wanderchina

## 愿景

> 让境外旅行者发现旅行指南之外的中国。
>
> Wanderchina 是一个面向境外用户的入境中国旅游目的地探索平台。
> 通过城市导览、深度攻略、小众景点与 AI 行程规划，
> 帮助非中国用户规划并发现"明信片之外"的中国旅行体验。
>
> 对标：Visit Japan / Tourism New Zealand / Discover Vietnam 等国际目的地营销站。

## 范围（in scope）

- **城市导览**：中国主要旅游城市卡片，含地理信息、最佳季节、概览描述。
- **旅行攻略**：英文深度游记 / 路线攻略，含标题、封面图、标签、摘要。
- **小众景点推荐**：非常规目的地推荐（Off-the-Beaten-Path Spots），强调深度体验。
- **AI 行程规划助手**：常驻式 AI 入口（跨页面），辅助用户生成行程、回答旅行问题。
- **内容语言策略**：英文为主、中文为辅——标题 / 导航 / CTA 全英文，内容卡片英文主标题 + 中文地名副标。
- **后端 HTTP API**：Spring Boot 提供城市 / 攻略 / 景点的 CRUD 与搜索接口，供前端 SSR 预取。
- **部署形态**：前端 Vercel / 后端 Docker 自托管。

## 非目标（out of scope）

- **OTA 交易**：本期不做机票 / 酒店 / 门票预订与支付，但不排除后续版本。
- **UGC 社区**：不做用户发帖、评论、点赞、关注等社交功能。
- **中文用户主界面**：当前产品定位面向境外用户，中文 UI 版本不在本期范围内。
- **移动端 App**：仅提供响应式 Web 端，不开发 iOS / Android 原生 App。
- **实时地图**：不内嵌交互式地图（仅展示静态位置信息 + 外链跳转至 Google Maps / 高德）。
- **后端内容管理系统**：本期内容以硬编码 / 数据库种子数据为主，不搭建 CMS 后台。

## 关键术语

| 术语 | 含义 |
|---|---|
| Region Slot | 首页 6 个内容区块的统称（hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher），由 `homepage-shell` 定义挂载契约 |
| City Card | 城市导览卡片，`city-grid` 区块的核心 UI 单元，含城市名、封面图、简要描述 |
| Story | 旅行攻略条目，`hot-posts` 区块展示，含标题 / 封面图 / 摘要 / 标签 |
| Hidden Spot | 小众景点，`hot-spots` 区块展示，强调深度 / 非旅游团体验 |
| AI Launcher | AI 行程助手入口按钮，跨页面常驻于 layout，点击后打开对话界面 |
| BFF | Browser-For-Frontend，前端 Next.js 薄层，负责 SSR 预取与接口聚合，不承担业务逻辑 |
| Capability Spec | OpenSpec 体系中一个独立能力单元的规格文档，对应 `openspec/specs/<capability>/spec.md` |

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
