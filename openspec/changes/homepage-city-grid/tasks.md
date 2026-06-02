# Tasks: homepage-city-grid

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针 + 同步治理文档。
> 后端 `backend/` 本变更**完全不动**。

## 0. 前置检查

- [x] 0.1 确认 `homepage-hero`（或 `homepage-feature-nav` 之后任一前序 capability）已在 `openspec/changes/archive/` 下
- [x] 0.2 父仓与子仓 `git status` 干净，main 分支已合入前序变更
- [x] 0.3 父仓建工作分支 `change/homepage-city-grid`
- [x] 0.4 子仓建对应分支 `change/homepage-city-grid`
- [x] 0.5 Node ≥ 20.19

## 1. 子仓 — TDD R1（CityGridSlot 渲染至少 1 个 `<a>`）

### 1a. RED
- [x] 1a.1 新增 `frontend/app/regions/CityGridSlot.test.tsx`，3 个用例：
  - `renders region container with data-region="city-grid"`
  - `renders at least one anchor with non-empty text`
  - `data file default-export is an array of {label, href}`
- [x] 1a.2 `npm test` 验证失败位置在 anchor 计数 = 0
- [x] 1a.3 子仓提交：`test(homepage-city-grid): RED - CityGridSlot must render at least one anchor`

### 1b. GREEN
- [x] 1b.1 新增 `frontend/app/regions/cityGrid.data.ts`：
  ```ts
  export type CityGridItem = { label: string; href: string };
  const items: readonly CityGridItem[] = [
    { label: "占位城市", href: "#" },
  ];
  export default items;
  ```
- [x] 1b.2 改写 `frontend/app/regions/CityGridSlot.tsx`：
  ```tsx
  import items from "./cityGrid.data";
  export default function CityGridSlot() {
    return (
      <section data-region="city-grid">
        {items.map((it) => (
          <a key={it.label} href={it.href}>{it.label}</a>
        ))}
      </section>
    );
  }
  ```
- [x] 1b.3 `npm test` 1a 的 3 个用例 GREEN
- [x] 1b.4 子仓提交：`feat(homepage-city-grid): GREEN - render anchors from hard-coded data`

### 1c. REFACTOR
- [x] 1c.1 浏览代码，确认无冗余
- [x] 1c.2 `npm test` 仍全绿
- [x] 1c.3 子仓提交（无调整可跳过）

## 2. 子仓 — TDD R2（href 严格 `#` + 边界守护）

### 2a. RED
- [x] 2a.1 在 `CityGridSlot.test.tsx` 追加用例：`every anchor href is exactly #`
- [x] 2a.2 当前 data 已是 "#"；按 TDD 临时把某项改成 "/cities/x" 让用例 RED，再恢复
- [x] 2a.3 子仓提交：`test(homepage-city-grid): RED - href must be exact #`

### 2b. GREEN
- [x] 2b.1 cityGrid.data.ts 中所有 href 设回 `"#"`
- [x] 2b.2 `npm test` 全绿
- [x] 2b.3 子仓提交：`test(homepage-city-grid): href must be exact #`

## 3. 子仓 — 构建与回归

- [x] 3.1 `npm run build` 通过
- [x] 3.2 dev server `curl /` 含 `<section data-region="city-grid"><a href="#">`
- [x] 3.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 3.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 3.5 `git diff main..HEAD -- lib/backend.ts package.json` 输出为空
- [x] 3.6 子仓推送 `change/homepage-city-grid`

## 4. 父仓追指针 + 治理同步

- [x] 4.1 父仓 `git add frontend` 追指针
- [x] 4.2 子仓更新 `frontend/README.md`：在《首页骨架》小节标注 city-grid 已注入
- [x] 4.3 父仓提交：`bump: frontend -> <new-sha> (homepage-city-grid)`
- [x] 4.4 父仓推送

## 5. 验证清单

- [x] 5.1 `cd frontend && npm test` 全绿
- [x] 5.2 `cd frontend && npm run build` 通过
- [x] 5.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 5.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 5.5 `frontend/app/regions/CityGridSlot.tsx` 中**未** import `lib/backend` / `fetchFromBackend` / `fetch(`
- [x] 5.6 `frontend/app/regions/cityGrid.data.ts` 存在且 default-export 数组
- [x] 5.7 `frontend/package.json` dependencies / devDependencies 字段未变
- [x] 5.8 父仓 `git diff --stat main..HEAD` 仅含 submodule 指针 + 本 change 4 件套

## 6. 归档（archive 时同步主 specs）

- [ ] 6.1 archive 阶段：将 delta `specs/homepage-shell/spec.md` MODIFIED 应用到主 spec
- [ ] 6.2 archive 阶段：将 ADDED 全部写入新主 spec `openspec/specs/homepage-city-grid/spec.md`
- [ ] 6.3 移动 change 目录到 `openspec/changes/archive/<YYYY-MM-DD>-homepage-city-grid/`
- [ ] 6.4 父仓提交归档：`chore(openspec): archive homepage-city-grid`

## 7. 后续（不在本变更范围）

- [ ] 接入真实城市清单（独立 propose）
- [ ] 城市图片 / icon（独立 propose）
- [ ] 视觉 grid 布局（独立 propose）
- [ ] 创建 `/cities/*` 业务路由（独立 propose）
- [ ] 余下 3 个区块的内容注入（hot-posts / hot-spots / ai-launcher）
