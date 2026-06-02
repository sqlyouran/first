# Tasks: homepage-feature-nav

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针 + 同步治理文档。
> 后端 `backend/` 本变更**完全不动**。

## 0. 前置检查

- [ ] 0.1 确认 `homepage-shell` 已在 `openspec/changes/archive/` 下（D5 触发器）
- [ ] 0.2 父仓与子仓 `git status` 干净，main 分支已合入 homepage-shell
- [ ] 0.3 父仓建工作分支 `change/homepage-feature-nav`
- [ ] 0.4 子仓建对应分支 `change/homepage-feature-nav`
- [ ] 0.5 Node ≥ 20.19 (`. ~/.nvm/nvm.sh && node -v`)

## 1. 子仓 — TDD R1（FeatureNavSlot 渲染至少 1 个 `<a>`）

### 1a. RED
- [ ] 1a.1 新增 `frontend/app/regions/FeatureNavSlot.test.tsx`，3 个用例：
  - `renders region container with data-region="feature-nav"`
  - `renders at least one anchor child`
  - `every anchor has non-empty textContent`
- [ ] 1a.2 `cd frontend && npm test`：3 个用例 RED
- [ ] 1a.3 子仓提交：`test(homepage-feature-nav): RED - FeatureNavSlot renders at least 1 anchor`

### 1b. GREEN
- [ ] 1b.1 新增 `frontend/app/regions/featureNav.data.ts`：
  - 定义 `export type FeatureNavItem = { label: string; href: string };`
  - default-export `readonly FeatureNavItem[]`，至少 1 项，所有 `href === "#"`
- [ ] 1b.2 改写 `frontend/app/regions/FeatureNavSlot.tsx`：
  - 保留 `<section data-region="feature-nav" aria-label="feature-nav placeholder">`
  - 内部 map 渲染 `<a key={...} href={item.href}>{item.label}</a>`
- [ ] 1b.3 `npm test`：1a 的 3 个用例 GREEN，其它 4 个 Slot 单测仍绿
- [ ] 1b.4 子仓提交：`feat(homepage-feature-nav): GREEN - render anchors from hard-coded data`

### 1c. REFACTOR
- [ ] 1c.1 浏览 FeatureNavSlot.tsx 确认无 inline style、无 className、无任何后端引用
- [ ] 1c.2 浏览 featureNav.data.ts 确认类型严格、所有 href 严格 `"#"`
- [ ] 1c.3 子仓提交（如有调整）：`refactor(homepage-feature-nav): tidy slot/data`

## 2. 子仓 — TDD R2（href 严格 `#` + BFF 边界守护）

### 2a. RED
- [ ] 2a.1 在 `FeatureNavSlot.test.tsx` 追加用例：
  - `every anchor href is exactly "#"`
- [ ] 2a.2 `npm test`：若 1b data 无意混入了非 `#` href 则 RED；若已严格 `#` 则用例 GREEN（直接进 2b 进行守护类断言）
- [ ] 2a.3 子仓提交（视情况）：`test(homepage-feature-nav): href must be exact "#"`

### 2b. 静态守护（无运行期）
- [ ] 2b.1 `grep -E "fetchFromBackend|fetch\(|import.*lib/backend" frontend/app/regions/FeatureNavSlot.tsx`：输出为空
- [ ] 2b.2 `find frontend/app -name 'route.ts' -o -name 'route.tsx'`：输出为空
- [ ] 2b.3 `head -1 frontend/lib/backend.ts`：输出 `import "server-only";`
- [ ] 2b.4 `git diff main..HEAD -- frontend/package.json`：输出为空
- [ ] 2b.5 `git diff main..HEAD -- frontend/lib/backend.ts`：输出为空

## 3. 子仓：构建与回归

- [ ] 3.1 `cd frontend && npm run build`：通过，无 warning
- [ ] 3.2 `npm test`：全绿（应 8 + 至少 4 个新用例 = ≥12）
- [ ] 3.3 dev server `npm run dev` 起来后 `curl -s http://localhost:<port>/ | grep '<a '` 命中 ≥ data 长度
- [ ] 3.4 `curl -s http://localhost:<port>/ | grep -o 'data-region="feature-nav"' | wc -l` 输出 `1`
- [ ] 3.5 子仓推送：`git push -u origin change/homepage-feature-nav`，记录 head SHA

## 4. 父仓：追指针 + 治理同步

- [ ] 4.1 父仓 `git add frontend` 追指针
- [ ] 4.2 子仓内更新 `frontend/README.md`：在《首页骨架》小节中标注 feature-nav 区块状态由"空容器"变为"含占位 anchor"
- [ ] 4.3 父仓提交：`bump: frontend -> <new-sha> (homepage-feature-nav)`
- [ ] 4.4 父仓推送 `change/homepage-feature-nav`

## 5. 验证清单（端到端）

- [ ] 5.1 `cd frontend && npm test` 全绿
- [ ] 5.2 `cd frontend && npm run build` 通过
- [ ] 5.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [ ] 5.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [ ] 5.5 `git diff origin/main..HEAD -- frontend/package.json` 输出为空（无依赖变更）
- [ ] 5.6 `git diff origin/main..HEAD -- frontend/lib/backend.ts` 输出为空（lib/backend 未变）
- [ ] 5.7 `frontend/app/regions/featureNav.data.ts` 存在；其 default export 长度 `>= 1`
- [ ] 5.8 `frontend/app/regions/FeatureNavSlot.tsx` 中无 `fetchFromBackend` / `fetch(` / `lib/backend` 关键字
- [ ] 5.9 父仓 `git diff --stat origin/main..HEAD` 仅含 `frontend` 指针 + 本 change 4 件套，无其它业务代码外漏

## 6. 归档（archive 时同步主 specs）

- [ ] 6.1 archive 阶段：将本 change 的 delta `specs/homepage-shell/spec.md` MODIFIED 应用到 `openspec/specs/homepage-shell/spec.md`（覆写"所有 Slot 必须为完全空容器"该 Requirement）
- [ ] 6.2 archive 阶段：将本 change 的 ADDED 全部写入新主 spec `openspec/specs/homepage-feature-nav/spec.md`
- [ ] 6.3 移动 `openspec/changes/homepage-feature-nav/` → `openspec/changes/archive/<YYYY-MM-DD>-homepage-feature-nav/`
- [ ] 6.4 父仓提交归档：`chore(openspec): archive homepage-feature-nav`

## 7. 后续（不在本变更范围）

- [ ] 接入真实 icon 系统（独立 propose）
- [ ] 接入后端或本地 JSON 数据源（独立 propose）
- [ ] 创建 `/flights` 等业务路由（独立 propose）
- [ ] 视觉设计（grid / 间距 / 响应式）（独立 propose）
- [ ] 余下 5 个区块的内容注入（hero / city-grid / hot-posts / hot-spots / ai-launcher，参照本变更模式）
