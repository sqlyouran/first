# Tasks: homepage-hero

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针 + 同步治理文档。
> 后端 `backend/` 本变更**完全不动**。

## 0. 前置检查

- [x] 0.1 确认 `homepage-feature-nav` 已在 `openspec/changes/archive/` 下
- [x] 0.2 父仓与子仓 `git status` 干净，main 分支已合入 homepage-feature-nav
- [x] 0.3 父仓建工作分支 `change/homepage-hero`
- [x] 0.4 子仓建对应分支 `change/homepage-hero`
- [x] 0.5 Node ≥ 20.19 (`. ~/.nvm/nvm.sh && node -v`)

## 1. 子仓 — TDD R1（HeroSlot 渲染 `<h1>` + `<button>`）

### 1a. RED
- [x] 1a.1 新增 `frontend/app/regions/HeroSlot.test.tsx`，3 个用例：
  - `renders region container with data-region="hero"`
  - `renders exactly one h1 with non-empty text`
  - `renders exactly one button with non-empty text`
- [x] 1a.2 `npm test` 验证失败位置在 h1 / button 计数 = 0（当前 HeroSlot 是空 section）
- [x] 1a.3 子仓提交：`test(homepage-hero): RED - HeroSlot must render h1 and button`

### 1b. GREEN
- [x] 1b.1 新增 `frontend/app/regions/hero.data.ts`：
  ```ts
  export type HeroContent = { title: string; ctaLabel: string; ctaHref: string };
  const hero: HeroContent = {
    title: "占位标题",
    ctaLabel: "占位 CTA",
    ctaHref: "#",
  };
  export default hero;
  ```
- [x] 1b.2 改写 `frontend/app/regions/HeroSlot.tsx`：
  ```tsx
  import hero from "./hero.data";
  export default function HeroSlot() {
    return (
      <section data-region="hero">
        <h1>{hero.title}</h1>
        <button type="button" data-cta-href={hero.ctaHref}>{hero.ctaLabel}</button>
      </section>
    );
  }
  ```
- [x] 1b.3 `npm test` 1a 的 3 个用例 GREEN
- [x] 1b.4 子仓提交：`feat(homepage-hero): GREEN - render h1 and button from hero.data`

### 1c. REFACTOR
- [x] 1c.1 浏览 HeroSlot.tsx / hero.data.ts，确认无冗余代码与重复
- [x] 1c.2 `npm test` 仍全绿
- [x] 1c.3 子仓提交（无调整可跳过）

## 2. 子仓 — TDD R2（占位 ctaHref 严格 `#` + 边界守护）

### 2a. RED
- [x] 2a.1 在 `HeroSlot.test.tsx` 追加用例：
  - `cta href is exactly #`（读 `data-cta-href` 属性 === "#"）
- [x] 2a.2 当前 ctaHref 占位已是 "#"，本用例可能直接 GREEN；若是，按 TDD 规范临时把 hero.data.ts 的 ctaHref 改成 "/search" 让用例 RED，再恢复
- [x] 2a.3 子仓提交 RED：`test(homepage-hero): RED - cta href must be exact #`（如需 RED 演练则提交带演练改动的版本）

### 2b. GREEN
- [x] 2b.1 hero.data.ts 中 `ctaHref` 设回 `"#"`
- [x] 2b.2 `npm test` 全绿
- [x] 2b.3 子仓提交：`test(homepage-hero): href must be exact #`

## 3. 子仓 — 构建与回归

- [x] 3.1 `npm run build` 通过，无新警告
- [x] 3.2 启动 dev server，`curl http://localhost:<port>/` 含 `<section data-region="hero"><h1>` 与 `<button`
- [x] 3.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 3.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 3.5 `git diff main..HEAD -- lib/backend.ts package.json` 输出为空
- [x] 3.6 子仓推送 `change/homepage-hero`

## 4. 父仓追指针 + 治理同步

- [x] 4.1 父仓 `git add frontend` 追 submodule 指针
- [x] 4.2 更新 `frontend/README.md`（在子仓内提交）：在《首页骨架》小节标注 hero 已注入
- [x] 4.3 父仓提交：`bump: frontend -> <new-sha> (homepage-hero)`
- [x] 4.4 父仓推送

## 5. 验证清单

- [x] 5.1 `cd frontend && npm test` 全绿
- [x] 5.2 `cd frontend && npm run build` 通过
- [x] 5.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 5.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 5.5 `frontend/app/regions/HeroSlot.tsx` 中**未** import `lib/backend` / `fetchFromBackend` / `fetch(`
- [x] 5.6 `frontend/app/regions/hero.data.ts` 存在且 default-export 单对象
- [x] 5.7 `frontend/package.json` dependencies / devDependencies 字段未变
- [x] 5.8 父仓 `git diff --stat main..HEAD` 仅含 submodule 指针 + 本 change 4 件套

## 6. 归档（archive 时同步主 specs）

- [x] 6.1 archive 阶段：将本 change 的 delta `specs/homepage-shell/spec.md` MODIFIED 应用到主 spec
- [x] 6.2 archive 阶段：将本 change 的 ADDED 全部写入新主 spec `openspec/specs/homepage-hero/spec.md`
- [x] 6.3 移动 `openspec/changes/homepage-hero/` → `openspec/changes/archive/<YYYY-MM-DD>-homepage-hero/`
- [x] 6.4 父仓提交归档：`chore(openspec): archive homepage-hero`

## 7. 后续（不在本变更范围）

- [ ] 接入真实业务文案（独立 propose）
- [ ] 视觉设计（背景图 / 排版 / 响应式）（独立 propose）
- [ ] CTA 真实跳转 / 弹窗交互（独立 propose）
- [ ] 多语言、A/B、SEO meta（独立 propose）
- [ ] 余下 4 个区块的内容注入（city-grid / hot-posts / hot-spots / ai-launcher）
