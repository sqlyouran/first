# Design: 前端切换到 Next.js（App Router）

## 决策一览

| 决策 | 选择 | 理由 |
|---|---|---|
| 前端框架 | **Next.js 16（App Router）** | 解决 SSR/SEO 硬伤；文件路由 + 嵌套布局是事实标准；Vercel 原生支持 |
| 路由模式 | App Router（`app/`），不用 Pages Router | Next.js 16 官方主线；后续 RSC / streaming 演进路径在 App Router 上 |
| 语言 | **TypeScript** | Next.js 官方默认；AI 生成质量更高；为未来 OpenAPI 类型对齐打基础 |
| 包管理 | npm | 与现仓库 `package-lock.json` 历史一致，避免无谓发明 |
| 创建方式 | `npx create-next-app@latest frontend --ts --app --no-tailwind --no-eslint --import-alias "@/*"` | 官方脚手架；显式关闭本次不需要的 Tailwind/ESLint 默认引入，由后续 change 自行决定 |
| CSS 方案 | vanilla CSS + CSS Modules（Next.js 默认） | YAGNI；不引入 Tailwind / styled-components |
| 测试栈 | **Vitest + @testing-library/react** | Next.js 官方文档支持；冷启动比 Jest 快；与 Vite 生态无依赖 |
| BFF 边界 | **薄 BFF**：仅 SSR 数据预取 + 多接口聚合 + 字段裁剪 | AGENTS.md 已锁；写操作 / 业务逻辑全部走 Spring Boot |
| Hello 调用方式 | 在 Server Component 内直接 `fetch('http://localhost:8080/api/hello', { cache: 'no-store' })`，渲染到页面 | 演示 SSR 数据流；BFF 实践样板 |
| 跨域处理 | **不再用 dev proxy**；前端在 server 端直连后端 8080 | App Router 的 RSC 在服务端发起请求，浏览器不直接打 `/api`，无 CORS 问题 |
| 端口约定 | 前端 3000（Next.js 默认，被占时 next dev 自动 fallback 到下一个可用端口） / 后端 8080（保持） | 不发明；BACKEND_URL 不依赖前端端口 |
| 后端环境变量 | `BACKEND_URL=http://localhost:8080` 写入 `frontend/.env.local` | 部署时由 Vercel 环境变量注入；不硬编码 |
| 旧工程处理 | **整目录覆盖**重建 `frontend/`，git 历史保留 | 一次性切换的语义；不留 `frontend.legacy/` |
| 旧 Vite 测试覆盖 | 当前 Vite 工程**无测试**，无迁移成本 | 验证：仅 `eslint.config.js` + 几个 `.jsx` |

frontend 在脚手架验证后实际为 **Next.js 16.2.x + React 19.2.x + TypeScript 5**；与原 spec 的 "Next.js 15" 偏差是脚手架主版本迭代造成的，本变更跟随官方最新。

## 系统结构（变更后）

```
my-first-project/
├── backend/                       Spring Boot（不动）
│   └── ... 原样
│
├── frontend/                      Next.js 16（重建）
│   ├── package.json
│   ├── next.config.ts             TS 配置（Next 16 默认）
│   ├── tsconfig.json
│   ├── AGENTS.md                  Next 16 自带的 AI 提示（子仓作用域）
│   ├── CLAUDE.md                  同上、指向 AGENTS.md
│   ├── .env.local                 BACKEND_URL=http://localhost:8080
│   ├── app/
│   │   ├── layout.tsx             根布局
│   │   ├── page.tsx               首页：SSR 调 /api/hello 并渲染
│   │   └── page.test.tsx          Vitest + RTL：断言渲染出 "hello"
│   ├── lib/
│   │   └── backend.ts             薄 BFF：封装 fetch(BACKEND_URL + path)
│   └── public/
│
├── openspec/  ...
├── AGENTS.md                      技术选型约束章节同步更新
└── README.md                      本地开发命令同步更新
```

## 端到端数据流（开发期）

```
   浏览器 ──GET / ──▶  Next.js dev :3000 (RSC 渲染)
                            │
                            │ Server Component 内 fetch
                            ▼
                       lib/backend.ts → http://localhost:8080/api/hello
                            ▼
                       Spring Boot ──▶ HelloController ──▶ "hello"
                            │
                            ▼  HTML 流（已含 "hello"）
   浏览器 ◀──────────── Next.js dev :3000
```

> 关键差异：浏览器**不再**发起 `/api/hello` 请求。RSC 在服务端拼好 HTML，首屏即含 "hello"。这正是 SSR/SEO 的来源。

## BFF 边界（必读约束）

**允许**（薄 BFF 范围）：
- SSR 数据预取：在 Server Component 内 fetch 后端
- 多接口聚合：一次 RSC 渲染调用多个后端端点拼装视图模型
- 字段裁剪：从后端响应中只挑前端需要的字段返回给客户端
- 缓存策略：用 `fetch` 的 `cache` / `next.revalidate` 配置（仅缓存读，不缓存写）

**禁止**（业务后端范围，违反 AGENTS.md）：
- ❌ 在 Route Handlers / Server Actions 写入数据库
- ❌ 在 Next.js 实现鉴权（凭据校验仍由 Spring Boot 完成；前端只透传 cookie/token）
- ❌ 在 Next.js 处理领域事务、状态机、定时任务、消息队列消费
- ❌ 在 Next.js 维护任何业务规则代码

任何越界都视为 AGENTS.md 红线违反，须先开新 change 推翻禁令条款。

## 备选方案

**Pages Router 而不是 App Router**——上手成本低、社区文档多。
拒绝：Next.js 主线已是 App Router，新功能（partial prerendering、parallel routes）只在 App Router 提供。我们刚切栈，没必要立刻面对二次迁移。

**保留 Vite + 加一个轻量 SSR 框架（如 Vike）**——改动小。
拒绝：用户已明确要求"切换为 Next.js"；Vike 生态远不如 Next.js，不符合长期可持续场景的"生态成熟度"维度。

**保留 Vite 工程并行运行 + 增量迁移**——风险低。
拒绝：用户已选定"一次性切换"；并行双栈维护成本高，且骨架阶段只有一个 Hello 页面，无增量迁移价值。

**新前端用 JS 而不是 TS**——延续现有风格。
拒绝：Next.js 官方默认 TS；AI 生成质量更高；BFF 层有类型保护更安全。这点轻微违反"贴合现状"原则，但收益足够大。

**用 Tailwind / shadcn-ui**——更"现代"。
拒绝：YAGNI，骨架阶段没有任何 UI 复杂度。Tailwind 由后续 change 决策。

**保留 Vite proxy 习惯，由浏览器打 `/api`**——开发期无 CORS 问题。
拒绝：放弃了 SSR 数据预取的核心收益。RSC server-side fetch 才是 Next.js 的正确姿势。

## 风险

- **环境变量泄漏**：`BACKEND_URL` 若被写成 `NEXT_PUBLIC_*` 前缀会暴露到客户端 bundle。
  **缓解**：变量名严禁加 `NEXT_PUBLIC_` 前缀；`lib/backend.ts` 仅在 server-only 上下文使用，加 `import 'server-only'` 守护。
- **BFF 越界**：开发者在 Route Handler 里写业务被 AI 误导。
  **缓解**：本变更不创建任何 `app/api/**/route.ts`；新增 Route Handler 必须先开 change 走 propose。
- **Next.js dev 与 Spring Boot 并行启动复杂度**：开发者忘了起后端，前端 SSR 报 ECONNREFUSED。
  **缓解**：README 增加"先起后端再起前端"提示；`page.tsx` 对 fetch 失败提供清晰错误信息。
- **Vitest + Next.js App Router 集成踩坑**：Server Component 不能直接被 RTL render。
  **缓解**：测试 RED 阶段先写一个客户端组件版本断言；如确需测 Server Component，使用 Playwright 端到端，但本变更先不引入。
- **submodule 层面的提交**：`frontend/` 是独立 git 仓库，删-建-提交都要在子仓内执行；父仓只追指针。
  **缓解**：tasks.md 显式分离子仓与父仓提交步骤。
- **覆盖式重建丢失"未提交"的本地改动**：执行前需确认子仓 `git status` 干净。
  **缓解**：tasks.md 第 1 步强制 `git status` 检查。

## 不引入

- TypeScript 之外的类型层（tRPC / GraphQL / Zod schema 共享）
- Tailwind / shadcn / 任何 CSS-in-JS
- 状态管理（Zustand / Redux / Jotai）
- 路由库（App Router 原生足够）
- 端到端测试（Playwright / Cypress）
- OpenAPI 契约管线（留待后续 change）
- 任何 `backend/` 端依赖或代码改动
- Vercel 实际部署动作（仅保证本地可起）
