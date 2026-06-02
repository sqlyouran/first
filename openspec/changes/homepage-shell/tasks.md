# Tasks: 首页骨架（homepage-shell）

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针。
> 后端 `backend/` 本变更**完全不动**。

## 0. 前置检查（apply 启动前必须全过）

- [x] 0.1 **D1 强制 trigger**：确认 `openspec/changes/archive/` 下存在以 `frontend-styling-stack` 结尾的目录（即 styling-stack 已完成 archive）。否则**必须先 apply + archive styling-stack**，本变更暂停。
- [x] 0.2 在 `frontend/` 子仓执行 `git status`，确认无未提交改动
- [x] 0.3 在父仓执行 `git status`，确认干净（propose 阶段产出已提交至工作分支）
- [x] 0.4 父仓为本变更创建工作分支 `change/homepage-shell`
- [x] 0.5 子仓同步创建对应分支 `change/homepage-shell`
- [x] 0.6 确认本机 Node ≥ 20.19（`. ~/.nvm/nvm.sh && node -v`） v20.20.2

## 1. 子仓 — TDD 第一轮（page 渲染 5 个 region）

### 1a. RED
- [x] 1a.1 创建 `frontend/app/page.test.tsx`，用例 1：`renders 5 regions in document order`
  - render `<Page />`（async server component 用 `renderToString` 或抽 client wrapper；如 testing-library/react 不支持 async，参考 styling-stack 已建立的 setup 或拆为 sync 子组件测）
  - 断言 `container.querySelectorAll('[data-region]').length === 5`
  - 断言 `data-region` 值列表 === `['hero','feature-nav','city-grid','hot-posts','hot-spots']`
- [x] 1a.2 用例 2：`does not render ai-launcher in page`
  - 断言 `container.querySelector('[data-region="ai-launcher"]') === null`
- [x] 1a.3 `cd frontend && npm test`：RED（page.tsx 仍 import server-only 仓 lib/backend，测试加载失败）
- [x] 1a.4 子仓提交：`test(homepage-shell): RED - page renders 5 regions in order`

### 1b. GREEN
- [x] 1b.1 创建 `frontend/app/regions/` 目录
- [x] 1b.2 创建 5 个页内 Slot 文件（按 D2 完全空容器）
- [x] 1b.3 重写 `frontend/app/page.tsx`：去掉 HelloMessage 与 fetchFromBackend 的 import 与调用；按 D1-D5 顺序渲染 5 个 Slot
- [x] 1b.4 `npm test`：1a 的 2 个用例 GREEN
- [x] 1b.5 子仓提交：`feat(homepage-shell): GREEN - render 5 region slots in page`

### 1c. REFACTOR
- [x] 1c.1 浏览 5 个 Slot 文件确认完全同形、无任何子节点、无 inline style
- [x] 1c.2 浏览 page.tsx 确认无任何 HelloMessage / lib/backend 残留 import
- [x] 1c.3 子仓提交（无调整，跳过）

## 2. 子仓 — TDD 第二轮（layout 注入 ai-launcher 常驻槽位）

### 2a. RED
- [x] 2a.1 创建 `frontend/app/layout.test.tsx`，用例：`mounts ai-launcher slot after children`
  - 抽离一个测试帮助：render layout 时传入带 `data-testid="children-marker"` 的子节点
  - 断言：`html` 含 `data-region="ai-launcher"`
  - 断言：DOM 顺序上 `[data-region="ai-launcher"]` **在** `[data-testid="children-marker"]` **之后**
- [x] 2a.2 `npm test`：用例 RED（layout 还没挂 AiLauncherSlot）。在 vitest.setup.ts 里 mock next/font/google。
- [x] 2a.3 子仓提交：`test(homepage-shell): RED - layout mounts ai-launcher after children`

### 2b. GREEN
- [x] 2b.1 创建 `frontend/app/regions/AiLauncherSlot.tsx`
- [x] 2b.2 修改 `frontend/app/layout.tsx`：import AiLauncherSlot 并在 `<body>{children}<AiLauncherSlot /></body>`
- [x] 2b.3 `npm test`：2a 用例 GREEN
- [x] 2b.4 子仓提交：`feat(homepage-shell): GREEN - mount ai-launcher slot in root layout`

### 2c. REFACTOR
- [x] 2c.1 确认 `AiLauncherSlot.tsx` 与其它 5 个 Slot 完全同形（仅容器从 `<section>` 改为 `<div>`、`data-region` 改为 `ai-launcher`）
- [x] 2c.2 子仓提交（无调整，跳过）

## 3. 子仓：构建与回归

- [x] 3.1 `cd frontend && npm run build`：通过，无 warning
- [x] 3.2 `npm test`：全绿（8 用例）
- [x] 3.3 dev server 已起 `http://localhost:3001`
- [x] 3.4 `curl -s http://localhost:3001/ | grep data-region`：命中 6 次
- [x] 3.5 `curl -s http://localhost:3001/ | grep '<h1>hello'`：计数 = 0
- [x] 3.6 验证 D3：`head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 3.7 验证 D3：`HelloMessage.tsx` / `HelloMessage.test.tsx` 存在未变
- [x] 3.8 异常路径：page.tsx 不依赖后端，curl 返回 200 + 6 个 data-region
- [x] 3.9 BFF 边界守护：`find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 3.10 子仓推送：`git push -u origin change/homepage-shell`，head SHA = `fa6c3fa`

## 4. 父仓：追指针 + 治理文档同步

- [x] 4.1 父仓 `git submodule update --remote frontend` 或手工进入子仓 fetch 后 `git add frontend`
- [x] 4.2 更新 `openspec/specs/http-server/spec.md`：将“通过前端 Next.js SSR 调后端访问”场景的断言从“首页 UI 出现 hello”调整为“`HelloMessage.test.tsx` 单测断言含 hello”——首页 UI 不再依赖后端，HelloMessage 链路保留为单测覆盖
- [x] 4.3 更新父仓 `frontend/README.md`（在子仓内提交）：追加《首页骨架》小节，列出 6 个 region 与对应后续 spec 单元
- [x] 4.4 父仓提交：`docs(governance): sync http-server spec for homepage-shell`
- [x] 4.5 父仓 `git add frontend` 追指针；提交：`bump: frontend -> <new-sha> (homepage-shell)`
- [x] 4.6 父仓推送

## 5. 验证清单（端到端）

- [x] 5.1 `cd frontend && npm test` 全绿
- [x] 5.2 `cd frontend && npm run build` 通过
- [x] 5.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 5.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 5.5 `frontend/app/HelloMessage.tsx` 与 `HelloMessage.test.tsx` 文件存在、内容未变
- [x] 5.6 `frontend/app/page.tsx` 中**未** import `HelloMessage` 或 `fetchFromBackend`
- [x] 5.7 `frontend/app/regions/` 下恰好 6 个 `*.tsx`（HeroSlot / FeatureNavSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot / AiLauncherSlot）
- [x] 5.8 父仓 `git diff --stat origin/main..HEAD` 仅含治理文档（http-server/spec.md）+ submodule 指针 + 本 change 4 件套，无其它业务代码外漏

## 6. 归档（实现完成后）

- [ ] 6.1 移动 `openspec/changes/homepage-shell/` → `openspec/changes/archive/<YYYY-MM-DD>-homepage-shell/`
- [ ] 6.2 父仓提交归档动作：`chore(openspec): archive homepage-shell`

## 7. 后续（不在本变更范围）

- [ ] 6 个区块各自的 propose：`homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher`，本 archive 后可并行启动
- [ ] 当出现非 `/` 业务路由且该路由不希望渲染 AI 助手时，propose `route-group-public-isolate` 把 launcher 提到 `(public)/layout.tsx`（D4 trigger）
- [ ] hero 接入真实数据后评估 HelloMessage 是否在 hero change 中清理（D3 衍生）
