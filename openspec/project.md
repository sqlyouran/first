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
| 前端构建 | Next.js 16 内建 (`frontend/`) | dev server 起于 3000（8080 为后端，被占时自动 fallback 到下一个可用端口） |
| 前端测试 | Vitest + @testing-library/react + jsdom | Server Component 不可直接 render，需抽为 Client Component 后覆盖 |
| BFF 调用 | `frontend/lib/backend.ts`（`import 'server-only'`） | Server Component 中用 `fetchFromBackend('/api/...')` 调后端，无 CORS 问题 |
| 环境变量 | `frontend/.env.local`（不入仓） | `BACKEND_URL=http://localhost:8080` |
| Node 运行时 | Node.js ≥ 20.19 | Next.js 16 要求 |

变更记录见 `openspec/changes/archive/`。

## 质量底线

- 所有改动走 TDD（见 `.qoder/skills/test-driven-development/`）。
- 主分支测试始终绿灯。
- 公开 API 改动必须先有对应 spec 更新。

## 维护

本文件每次 `/archive` 时检查是否需要更新。重大变化在对应 change 的 `design.md` 中写理由。
