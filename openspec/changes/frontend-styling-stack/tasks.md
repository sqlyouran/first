# Tasks: 引入前端样式栈

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针。
> 后端 `backend/` 本变更**完全不动**。

## 0. 前置检查
- [ ] 0.1 在 `frontend/` 子仓执行 `git status`，确认无未提交改动
- [ ] 0.2 在父仓执行 `git status`，确认干净（propose 阶段产出已提交至工作分支）
- [ ] 0.3 父仓为本变更创建工作分支 `change/frontend-styling-stack`
- [ ] 0.4 子仓同步创建对应分支 `change/frontend-styling-stack`
- [ ] 0.5 确认本机 Node ≥ 20.19（`source ~/.nvm/nvm.sh && node -v`）
- [ ] 0.6 记录基线 First Load JS：`cd frontend && npm run build`，记录 `/` 路由的 First Load JS 数值，用于后续 ≤ +50KB 验证

## 1. 子仓：安装 Tailwind CSS 4 与配套依赖
- [ ] 1.1 在 `frontend/` 执行：
      ```bash
      npm install -D tailwindcss@^4 @tailwindcss/postcss tailwindcss-animate
      npm install class-variance-authority clsx tailwind-merge lucide-react
      ```
- [ ] 1.2 验证 `package.json` 含上述 7 个包；`package-lock.json` 已更新
- [ ] 1.3 创建 `frontend/postcss.config.mjs`：
      ```js
      export default {
        plugins: { '@tailwindcss/postcss': {} },
      };
      ```
- [ ] 1.4 创建 `frontend/tailwind.config.ts`（content 字段含 `app/**` 与 `components/**`，darkMode: ['class']，插件含 `tailwindcss-animate`）
- [ ] 1.5 子仓提交：`feat(styling): install tailwind 4 + animate plugin`

## 2. 子仓 — TDD 第一轮（Tailwind class 生效）

### 2a. RED
- [ ] 2a.1 在 `app/page.tsx` 临时插入 `<div data-testid="tw-probe" className="bg-red-500 p-4">x</div>`
- [ ] 2a.2 创建 `frontend/app/__tests__/tailwind-probe.test.tsx`，用例：render page、断言探针 div 的 `class` 字符串包含 `bg-red-500` 与 `p-4`
- [ ] 2a.3 `npm test` 运行：当前 `globals.css` 未接入 Tailwind directives，**class 字符串能匹配（合理）但浏览器未生效**——此处单测仅验证 class 注入；浏览器生效在 2b.4 端到端验证。先记录测试通过。
- [ ] 2a.4 起 dev 跑 `curl -s http://localhost:3000 | rg 'bg-red-500'` 确认 HTML 含 class 但 **CSS 不生效**（红状态：视觉未变红）

### 2b. GREEN
- [ ] 2b.1 修改 `frontend/app/globals.css`：首行加 `@import 'tailwindcss';`（Next 16 默认 globals.css 内容保留在其下）
- [ ] 2b.2 重启 dev server
- [ ] 2b.3 `curl -s http://localhost:3000 | rg 'bg-red-500'` 仍命中
- [ ] 2b.4 浏览器打开 `http://localhost:3000`：探针 div 视觉为红色背景、内边距 1rem（绿状态）
- [ ] 2b.5 `npm test` 仍全绿

### 2c. REFACTOR
- [ ] 2c.1 移除 `app/page.tsx` 中的探针 div 与 `app/__tests__/tailwind-probe.test.tsx`（探针已完成历史使命，避免污染骨架）
- [ ] 2c.2 子仓提交：`feat(styling): wire tailwind directives into globals.css`

## 3. 子仓：shadcn/ui 初始化
- [ ] 3.1 执行 `npx --yes shadcn@latest init`，交互选择：
  - Style: `new-york`
  - Base color: `slate`
  - CSS variables: `Yes`
  - 路径别名沿用 `@/*`
- [ ] 3.2 验证生成的文件：
  - `frontend/components.json`（与 spec 第 3.3 节对齐）
  - `frontend/lib/utils.ts`（含 `cn` 函数，import `clsx` 与 `twMerge`）
  - `frontend/app/globals.css` 已被 shadcn 追加 `:root` / `.dark` CSS 变量段
- [ ] 3.3 人工 diff 检查：globals.css 的 Tailwind directive 仍在；新增的 shadcn 段位于其后
- [ ] 3.4 验证 `lib/backend.ts` 未被 shadcn init 改动（首行仍为 `import "server-only";`）
- [ ] 3.5 验证 `frontend/app/` 下未新增 `api/auth/route.ts` 等 Route Handler（`find frontend/app -name 'route.ts'` 应为空）
- [ ] 3.6 子仓提交：`chore(styling): init shadcn-ui (new-york / slate / css vars)`

## 4. 子仓 — TDD 第二轮（shadcn Button + lucide + cn 集成）

### 4a. RED
- [ ] 4a.1 创建 `frontend/components/ui/__tests__/button.test.tsx`，用例：
  - 用例 1：`render(<Button>x</Button>)` 输出 `<button>` 含 class `inline-flex` 与 `items-center`
  - 用例 2：`render(<Button variant="outline">x</Button>)` 输出 class 含 `border`
  - 用例 3：`render(<Sparkles data-testid="ic" className="h-4 w-4" />)` 输出 svg、`aria-hidden="true"`、class 含 `h-4 w-4`
  - 用例 4：`expect(cn('a', 'b')).toBe('a b')`；`expect(cn('p-2', 'p-4')).toBe('p-4')`
- [ ] 4a.2 `npm test`：编译失败（`@/components/ui/button` 不存在），符合预期 → RED 记录

### 4b. GREEN
- [ ] 4b.1 执行 `npx shadcn@latest add button card input`，组件源码下载到 `frontend/components/ui/`
- [ ] 4b.2 验证三个文件存在：`button.tsx` / `card.tsx` / `input.tsx`
- [ ] 4b.3 `npm test`：4 个用例全绿（GREEN）

### 4c. REFACTOR
- [ ] 4c.1 浏览 `components/ui/*.tsx`：保持 shadcn 原版，**不**人工修改（便于未来 `shadcn diff` 升级）
- [ ] 4c.2 子仓提交：`feat(styling): add shadcn button/card/input with TDD integration test`

## 5. 子仓：构建与回归
- [ ] 5.1 `cd frontend && npm run build`：通过，无 warning
- [ ] 5.2 比对 `/` 路由 First Load JS：相对 0.6 记录的基线增量 ≤ 50KB
- [ ] 5.3 `npm test`：HelloMessage.test.tsx + button.test.tsx 全绿（≥ 5 用例）
- [ ] 5.4 dev server 起：`/` 视觉无破坏（仍渲染 HelloMessage 链路）
- [ ] 5.5 子仓推送：`git push -u origin change/frontend-styling-stack`，记录 head SHA

## 6. 父仓：追指针 + 治理文档同步
- [ ] 6.1 父仓 `git submodule update --remote frontend` 或手工进入子仓 fetch 后 `git add frontend`
- [ ] 6.2 更新父仓 `AGENTS.md`「禁止动作」清单：
  - 移除：`❌ 引入 Tailwind / shadcn-ui / 任何 CSS 框架（YAGNI，骨架阶段保持 vanilla CSS）`
  - 新增：`❌ 引入 Tailwind + shadcn/ui + lucide-react 之外的其它 CSS 方案（styled-components / emotion / vanilla-extract / MUI / Chakra / Ant Design 等）`
- [ ] 6.3 更新父仓 `AGENTS.md`「锁定栈」表格：新增样式栈行 `样式 | Tailwind CSS 4 + shadcn/ui (new-york / slate) + lucide-react | shadcn 提供 a11y / 设计 token / Radix 实现`
- [ ] 6.4 更新父仓 `openspec/project.md`「技术栈」段：新增样式栈一行（措辞与 6.3 对齐）
- [ ] 6.5 父仓提交：`docs(governance): allow tailwind+shadcn stack; sync agents/project`
- [ ] 6.6 父仓 `git add frontend` 追指针；提交：`bump: frontend -> <new-sha> (frontend-styling-stack)`
- [ ] 6.7 父仓推送

## 7. 验证清单（端到端）
- [ ] 7.1 `cd frontend && npm test` 全绿
- [ ] 7.2 `cd frontend && npm run build` 通过
- [ ] 7.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空（BFF 边界守护）
- [ ] 7.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [ ] 7.5 父仓 `grep -n 'Tailwind' AGENTS.md`：不命中「❌ 引入 Tailwind」
- [ ] 7.6 父仓 `grep -n 'shadcn' AGENTS.md`：命中锁定栈表格新增行
- [ ] 7.7 父仓 `git diff --stat origin/main..HEAD` 仅含治理文档（AGENTS.md / openspec/project.md）+ submodule 指针 + 本 change 三件套，无业务代码外漏
- [ ] 7.8 子仓 `components/ui/` 下文件数 = 3（button.tsx / card.tsx / input.tsx），未夹带其它 shadcn 组件

## 8. 归档（实现完成后）
- [ ] 8.1 移动 `openspec/changes/frontend-styling-stack/` → `openspec/changes/archive/<YYYY-MM-DD>-frontend-styling-stack/`
- [ ] 8.2 父仓提交归档动作：`chore(openspec): archive frontend-styling-stack`

## 9. 后续（不在本变更范围）
- [ ] 自定义品牌色 / 字体 token：`frontend-design-tokens`
- [ ] 暗色模式切换：`dark-mode-support`（`next-themes` 集成）
- [ ] 6 个区块 change 中按需 `shadcn add` 各自所需组件（Sheet / Dialog / Tabs / Form 等）
