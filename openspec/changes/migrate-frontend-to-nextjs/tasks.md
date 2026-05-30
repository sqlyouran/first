# Tasks: 前端切换到 Next.js

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针。
> 后端 `backend/` 本变更**完全不动**，启停命令保持 `mvn -f backend/pom.xml spring-boot:run`。

## 0. 前置检查
- [ ] 0.1 在 `frontend/` 子仓执行 `git status`，确认无未提交改动；如有先 commit 或 stash
- [ ] 0.2 在父仓执行 `git status`，确认干净
- [ ] 0.3 在父仓为本变更创建工作分支（建议名 `change/migrate-frontend-to-nextjs`）
- [ ] 0.4 子仓同步创建对应分支
- [ ] 0.5 确认本机 Node 版本 ≥ 20.19（`node -v`），否则升级

## 1. 子仓：清空旧 Vite 工程
- [ ] 1.1 进入 `frontend/`，删除 Vite 工程文件：`package.json`、`package-lock.json`、`vite.config.js`、`eslint.config.js`、`index.html`、`src/`、`public/`、`README.md`、`.gitignore`、`node_modules/`、`dist/`
  - 保留：`.git/`（子仓元数据）
- [ ] 1.2 子仓提交：`git add -A && git commit -m "chore: remove vite scaffolding for next.js migration"`
  - 此时子仓应为空目录（仅 `.git/`）

## 2. 子仓：用脚手架重建 Next.js 工程
- [ ] 2.1 在仓库根（**父仓位置**）执行：
      ```bash
      npx create-next-app@latest frontend --ts --app \
        --no-tailwind --no-eslint --no-src-dir \
        --import-alias "@/*" --use-npm
      ```
  - 全程默认；脚手架会在 `frontend/` 内重新生成 `package.json` 等
- [ ] 2.2 验证生成结果存在：`frontend/package.json`、`frontend/next.config.mjs`、`frontend/tsconfig.json`、`frontend/app/page.tsx`、`frontend/app/layout.tsx`
- [ ] 2.3 在 `frontend/` 执行 `npm install` 通过
- [ ] 2.4 在 `frontend/` 执行 `npm run dev` 能起到 `http://localhost:3000`，看到默认欢迎页（**仅冒烟，立即停止**）
- [ ] 2.5 子仓 `.gitignore` 由脚手架生成，确认包含 `node_modules`、`.next`、`.env.local`
- [ ] 2.6 子仓提交：`git add -A && git commit -m "feat: scaffold next.js 15 app router project"`

## 3. 子仓：BFF 封装 + 环境变量
- [ ] 3.1 创建 `frontend/.env.local`，内容：`BACKEND_URL=http://localhost:8080`
  - 确认 `.env.local` 在 `.gitignore` 中
- [ ] 3.2 创建 `frontend/lib/backend.ts`：
  - 首行 `import 'server-only';` 守护
  - 导出 `fetchFromBackend(path: string, init?: RequestInit): Promise<Response>` 函数
  - 内部：`process.env.BACKEND_URL + path` 拼接，附 `cache: 'no-store'` 默认值（薄 BFF：不缓存）
- [ ] 3.3 子仓提交：`git add -A && git commit -m "feat: add server-only BFF helper for backend fetch"`

## 4. 子仓 — TDD 第一轮（首页渲染 hello）

### 4a. RED
- [ ] 4a.1 安装测试栈：`npm install -D vitest @vitejs/plugin-react @testing-library/react @testing-library/jest-dom jsdom`
- [ ] 4a.2 创建 `frontend/vitest.config.ts`：
  - `plugins: [react()]`、`environment: 'jsdom'`、`setupFiles: ['./vitest.setup.ts']`
- [ ] 4a.3 创建 `frontend/vitest.setup.ts`：`import '@testing-library/jest-dom'`
- [ ] 4a.4 在 `frontend/package.json` 加 `"test": "vitest run"`、`"test:watch": "vitest"`
- [ ] 4a.5 创建 `frontend/app/page.test.tsx`：
  - 测试用例 `renders hello message from backend`
  - mock `lib/backend.ts` 让 `fetchFromBackend` 返回 `{ ok: true, text: async () => 'hello' }`
  - render 异步 Server Component 的 client 等价版本（或封装成可测的 client component），断言文本 `hello` 出现
- [ ] 4a.6 运行 `npm test`：**编译失败**或测试失败（`page.tsx` 还没改），符合预期 → 记录红状态

### 4b. GREEN
- [ ] 4b.1 改写 `frontend/app/page.tsx` 为 async Server Component：
  - 调用 `fetchFromBackend('/api/hello')`
  - `await res.text()` 拿到 `hello`
  - 渲染 `<h1>{message}</h1>`
- [ ] 4b.2 如果 4a.5 的测试需要 client component 包装，在 `app/_components/HelloMessage.tsx` 创建 client component 接收 `message` props，`page.tsx` 把数据传给它
- [ ] 4b.3 运行 `npm test`：测试转绿
- [ ] 4b.4 终端 A 起后端：`mvn -f backend/pom.xml spring-boot:run`
- [ ] 4b.5 终端 B 起前端：`cd frontend && npm run dev`
- [ ] 4b.6 浏览器打开 `http://localhost:3000`，**亲眼看到** `hello`
- [ ] 4b.7 浏览器查看页面源码（View Source），确认 `hello` 字样在初始 HTML 中（验证 SSR 真正生效，**不是**客户端 hydrate 后才出现）

### 4c. REFACTOR
- [ ] 4c.1 浏览代码确认无重复、无未使用 import、无 dead code
- [ ] 4c.2 子仓提交：`git add -A && git commit -m "feat: render hello from backend via SSR (TDD green)"`

## 5. 子仓：README 与文档
- [ ] 5.1 重写 `frontend/README.md`，包含：
  - 工具链（Node ≥ 20.19、Next.js 15、TypeScript、Vitest）
  - 启动命令（`npm install`、`npm run dev`、`npm test`、`npm run build`）
  - 端口（3000）与 `BACKEND_URL` 环境变量约定
  - 与 Spring Boot 后端联调的步骤（先起后端再起前端）
  - BFF 边界提示（链接到父仓 AGENTS.md「技术选型约束」）
- [ ] 5.2 子仓提交：`git add -A && git commit -m "docs: frontend readme for next.js + bff conventions"`

## 6. 子仓推送 + 父仓追指针
- [ ] 6.1 子仓 `git push origin <branch>`（如果尚未配置远端，跳过 push 但记录 SHA）
- [ ] 6.2 父仓回到根目录，`git add frontend && git commit -m "bump: frontend -> <new-sha> (next.js migration)"`
- [ ] 6.3 父仓 `git status` 确认仅 submodule 指针变化

## 7. 父仓：治理文档同步更新
- [ ] 7.1 更新 `AGENTS.md`「技术选型约束」：
  - 锁定栈表格："前端" 行 `React + Vite（现状）` → `React + Next.js 15（App Router）+ TypeScript`
  - 决定性理由补充：`SSR/SEO 能力`、`文件路由约定`、`Vercel 原生部署`
  - 「禁止动作」追加显式区分：
    - ✅ 允许：Next.js 仅做薄 BFF（SSR 预取 / 接口聚合 / 字段裁剪 / 缓存读）
    - ❌ 禁止：在 Route Handlers / Server Actions 写入业务（鉴权写、事务、领域逻辑）
- [ ] 7.2 更新 `openspec/project.md`「技术栈」：
  - 前端框架行：`React 19` → `React 19 + Next.js 15 (App Router) + TypeScript`
  - 前端构建行：`Vite 8` → `Next.js 15 内建`
  - 前端 dev 端口：`5173` → `3000`
  - 跨域行：`Vite dev proxy` → `Next.js Server Component 服务端 fetch（无 CORS 问题）`
  - 测试行新增：`前端测试 Vitest + React Testing Library`
- [ ] 7.3 更新 `openspec/specs/http-server/spec.md`：
  - Scenario「通过前端 dev server 代理访问」改写：前端走 Next.js 5173→3000，由 RSC 在服务端 fetch 后端；浏览器加载页面后**首屏 HTML 已含 `hello`**
  - 删除/改写涉及 `vite.config.js` 的描述
- [ ] 7.4 更新根 `README.md`「本地开发」段：前端命令从 `cd frontend && npm install && npm run dev` 后端口改为 3000；启动顺序明确"先后端后前端"
- [ ] 7.5 父仓提交：`git add -A && git commit -m "docs: align governance docs with next.js frontend"`

## 8. 验证清单（端到端）
- [ ] 8.1 `mvn -f backend/pom.xml test` 全绿（确认本变更未误伤后端）
- [ ] 8.2 `cd frontend && npm test` 全绿（Vitest 用例通过）
- [ ] 8.3 `cd frontend && npm run build` 通过（生产构建无错误）
- [ ] 8.4 端到端：起后端 + 起前端 → 浏览器访问 `http://localhost:3000` 看到 `hello`
- [ ] 8.5 浏览器 View Source 验证 `hello` 在初始 HTML（SSR 生效）
- [ ] 8.6 `frontend/` 目录下**不存在**任何 `app/api/**/route.ts` 文件（BFF 边界守护）
- [ ] 8.7 `frontend/lib/backend.ts` 首行为 `import 'server-only';`
- [ ] 8.8 父仓 `git diff --stat HEAD~..HEAD` 仅含治理文档与 submodule 指针，无业务代码

## 9. 后续（不在本变更范围）
- [ ] 引入 OpenAPI 契约管线：`backend` 增加 `springdoc-openapi`，`frontend` 增加 `openapi-typescript` 自动生成 TS 类型（建议命名 `add-openapi-contract`）
- [ ] Vercel 部署接入：环境变量、preview 部署、生产域名（建议命名 `deploy-frontend-to-vercel`）
- [ ] 引入 Tailwind / shadcn-ui（如有 UI 复杂度需求时再开 change）
- [ ] 端到端测试栈（Playwright，业务页面 ≥ 3 个时再考虑）
