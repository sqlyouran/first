# Tasks: 前端切换到 Next.js

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针。
> 后端 `backend/` 本变更**完全不动**，启停命令保持 `mvn -f backend/pom.xml spring-boot:run`。

## 0. 前置检查
- [x] 0.1 在 `frontend/` 子仓执行 `git status`，确认无未提交改动；如有先 commit 或 stash
- [x] 0.2 在父仓执行 `git status`，确认干净（propose 阶段产出已提交至工作分支）
- [x] 0.3 在父仓为本变更创建工作分支 `change/migrate-frontend-to-nextjs`
- [x] 0.4 子仓同步创建对应分支 `change/migrate-frontend-to-nextjs`
- [x] 0.5 确认本机 Node 版本 ≥ 20.19（实际 v20.20.2，需 `source ~/.nvm/nvm.sh` 激活）

## 1. 子仓：清空旧 Vite 工程
- [x] 1.1 进入 `frontend/`，删除 Vite 工程文件：`package.json`、`package-lock.json`、`vite.config.js`、`eslint.config.js`、`index.html`、`src/`、`public/`、`README.md`、`.gitignore`（`node_modules/` 与 `dist/` 本仓未生成，跳过）
  - 保留：`.git/`（子仓元数据）
- [x] 1.2 子仓提交（commit `7078735`）：`chore: remove vite scaffolding for next.js migration`

## 2. 子仓：用脚手架重建 Next.js 工程
- [x] 2.1 在仓库根（**父仓位置**）执行：
      ```bash
      npx --yes create-next-app@latest frontend --ts --app \
        --no-tailwind --no-eslint --no-src-dir \
        --import-alias "@/*" --use-npm --no-turbopack
      ```
  - 实际装到 Next.js 16.2.6 + React 19.2.4 + TypeScript 5；脚手架额外生成 `frontend/AGENTS.md` 与 `frontend/CLAUDE.md`（Next 16 默认 AI 提示，与父仓作用域不冲突，保留）
- [x] 2.2 验证生成结果存在：`frontend/package.json`、`frontend/next.config.ts`（非 .mjs）、`frontend/tsconfig.json`、`frontend/app/page.tsx`、`frontend/app/layout.tsx`
- [x] 2.3 在 `frontend/` 执行 `npm install`（脚手架已含，跳过重复执行）
- [x] 2.4 在 `frontend/` 执行 `npm run dev` 起服务：HTTP 200，渲染 Next 默认页；实际端口 3001（3000 被其它本机 node 进程 PID 26982 占用，Next 自动 fallback）。冗余进程不属本变更范围
- [x] 2.5 子仓 `.gitignore` 已含 `node_modules`、`.next`、`.env*`（涵盖 `.env.local`）→ 已验证
- [x] 2.6 子仓提交（commit `f258fb3`）：`feat: scaffold next.js 16 app router project`

## 3. 子仓：BFF 封装 + 环境变量
- [x] 3.1 创建 `frontend/.env.local`，内容：`BACKEND_URL=http://localhost:8080`
  - 确认 `.env.local` 在 `.gitignore` 中（Next.js 16 默认 `.gitignore` 已含 `.env*`）
- [x] 3.2 创建 `frontend/lib/backend.ts`：
  - 首行 `import 'server-only';` 守护
  - 导出 `fetchFromBackend(path: string, init?: RequestInit): Promise<Response>` 函数
  - 内部：`process.env.BACKEND_URL + path` 拼接，附 `cache: 'no-store'` 默认值（薄 BFF：不缓存）
  - 安装 `server-only` 包（`npm install server-only`）
- [x] 3.3 子仓提交（commit `08f17ad`）：`feat: add server-only BFF helper for backend fetch`

## 4. 子仓 — TDD 第一轮（首页渲染 hello）

### 4a. RED
- [x] 4a.1 安装测试栈：`npm install -D vitest @vitejs/plugin-react @testing-library/react @testing-library/jest-dom jsdom`（同包已含 @testing-library/dom、@types/react、@types/react-dom）
- [x] 4a.2 创建 `frontend/vitest.config.ts`：
  - `plugins: [react()]`、`environment: 'jsdom'`、`setupFiles: ['./vitest.setup.ts']`
- [x] 4a.3 创建 `frontend/vitest.setup.ts`：`import '@testing-library/jest-dom'`
- [x] 4a.4 在 `frontend/package.json` 加 `"test": "vitest run"`、`"test:watch": "vitest"`
- [x] 4a.5 创建 `frontend/app/HelloMessage.test.tsx`（原为 page.test.tsx，改测 client component HelloMessage）：
  - 测试用例 `renders hello message from backend`
  - 直接 render `<HelloMessage message="hello" />`，断言 h1 文本 `hello`
- [x] 4a.6 运行 `npm test`：**编译失败**（`HelloMessage` 不存在），符合预期 → 记录红状态

### 4b. GREEN
- [x] 4b.1 创建 `frontend/app/HelloMessage.tsx`（client component，`"use client"`）：
  - 接收 `message` props，渲染 `<h1>{message}</h1>`
- [x] 4b.2 改写 `frontend/app/page.tsx` 为 async Server Component：
  - 调 `fetchFromBackend('/api/hello')`，`await res.text()` 拿 `hello`
  - 传 `<HelloMessage message={message} />`
- [x] 4b.3 运行 `npm test`：测试转绿（1 passed, 161ms）
- [x] 4b.4 后端复用已监听的 8080（PID 7886 已起的 Spring Boot 实例，未重跑 Maven）
- [x] 4b.5 起前端：`cd frontend && npm run dev`（实际在 3001，3000 被占）
- [x] 4b.6 curl `http://localhost:3001` HTTP 200
- [x] 4b.7 SSR 真生效验证：`curl http://localhost:3001` HTML 内含 `<h1>hello</h1>` 与 RSC payload `{"message":"hello"}`

### 4c. REFACTOR
- [x] 4c.1 浏览代码确认无重复、无未使用 import、无 dead code
- [x] 4c.2 子仓提交（commit `90ccd2e`）：`feat: render hello from backend via SSR (TDD green)`

## 5. 子仓：README 与文档
- [x] 5.1 重写 `frontend/README.md`，包含：
  - 工具链（Node ≥ 20.19、Next.js 16、TypeScript、Vitest）
  - 启动命令（`npm install`、`npm run dev`、`npm test`、`npm run build`）
  - 端口（3000，被占时自动 fallback）与 `BACKEND_URL` 环境变量约定
  - 与 Spring Boot 后端联调的步骤（先起后端再起前端）
  - BFF 边界提示（链接到父仓 AGENTS.md「技术选型约束」）
- [x] 5.2 子仓提交（commit `a78cec3`）：`docs: frontend readme for next.js + bff conventions`

## 6. 子仓推送 + 父仓追指针
- [x] 6.1 子仓切 SSH remote（`git@github.com:sqlyouran/first_frontend.git`）并 push：`git push -u origin change/migrate-frontend-to-nextjs`（远端 HEAD = `a78cec3`）
- [x] 6.2 父仓同步切 `.gitmodules` HTTPS → SSH（frontend + backend 一起），`git submodule sync` 验证
- [x] 6.3 父仓 `git add frontend .gitmodules && git commit -m "bump: frontend -> a78cec3 (next.js migration); switch submodule urls to ssh"`（commit `69bcdd9`）

## 7. 父仓：治理文档同步更新
- [x] 7.1 更新 `AGENTS.md`「技术选型约束」：
  - 锁定栈表格："前端" 行 `React + Vite（现状）` → `React 19 + Next.js 16（App Router）+ TypeScript`
  - 决定性理由补充：`SSR/SEO 能力`、`文件路由约定`、`Vercel 原生部署`
  - 「禁止动作」下增 Next.js BFF 边界必读约束（允许项 + 禁止项 + 可验收点）
  - 仓库拓扑表中 frontend 行：`Vite 8 + React 19（端口 5173）` → `Next.js 16 (App Router) + React 19 + TypeScript（端口 3000）`
  - frontend 子模块说明部分重写（启动 / 构建 / 测试 / 工具链）
- [x] 7.2 更新 `openspec/project.md`「技术栈」：
  - 前端框架行：`React 19` → `React 19 + Next.js 16 (App Router) + TypeScript 5`
  - 前端构建行：`Vite 8` → `Next.js 16 内建`，端口 5173 → 3000
  - 跨域行删除，新增：前端测试 / BFF 调用 / 环境变量 三行
- [x] 7.3 更新 `openspec/specs/http-server/spec.md`：
  - Scenario「通过前端 dev server 代理访问」重写为「通过前端 Next.js SSR 调后端访问」（8080 不变，前端 5173 → 3000，Vite proxy → RSC 服务端 fetch，验证点从 DOM 出现 → 首屏 HTML 含 `<h1>hello</h1>`）
  - 新增 Scenario：前端 Client Component 单测覆盖呈现逻辑（Vitest + RTL）
- [x] 7.4 更新根 `README.md`「本地开发」段：前端启动介绍从 Vite proxy 重写为 Next.js SSR，端口 5173 → 3000，补 `.env.local` / `BACKEND_URL` 说明，补前端测试命令
- [x] 7.5 父仓提交（commit `3ae1937`）：`docs: sync governance docs for next.js migration (agents/project/http-server spec)`

## 8. 验证清单（端到端）
- [x] 8.1 ~~`mvn -f backend/pom.xml test`~~ **跳过**（Maven 未安装；本变更未修改任何 backend/ 文件，父仓 diff 证明零 backend 变动，记为 spec drift，后端质量负担为 0）
- [x] 8.2 `cd frontend && npm test` 全绿（1 passed）
- [x] 8.3 `cd frontend && npm run build` 通过（Compiled successfully，`/` 为 Dynamic SSR）
- [x] 8.4 端到端：起后端（复用 PID 7886 的 Spring Boot）+ 起前端 → `curl http://localhost:3001` HTTP 200
- [x] 8.5 SSR 验证：首屏 HTML 含 `<h1>hello</h1>` 与 RSC payload `{"message":"hello"}`【Batch 5 已验证】
- [x] 8.6 `frontend/app/` 下**不存在** `route.ts` / `route.tsx`（`find` 返回 0，BFF 边界守护成功）
- [x] 8.7 `frontend/lib/backend.ts` 首行为 `import "server-only";`
- [x] 8.8 父仓 `git diff --stat origin/main..HEAD` 仅含治理文档与 submodule 指针，无业务代码（8 files：.gitmodules / AGENTS.md / README.md / frontend指针 / openspec二者三件套）

## 9. 后续（不在本变更范围）
- [ ] 引入 OpenAPI 契约管线：`backend` 增加 `springdoc-openapi`，`frontend` 增加 `openapi-typescript` 自动生成 TS 类型（建议命名 `add-openapi-contract`）
- [ ] Vercel 部署接入：环境变量、preview 部署、生产域名（建议命名 `deploy-frontend-to-vercel`）
- [ ] 引入 Tailwind / shadcn-ui（如有 UI 复杂度需求时再开 change）
- [ ] 端到端测试栈（Playwright，业务页面 ≥ 3 个时再考虑）
