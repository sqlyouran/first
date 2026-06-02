# Tasks: homepage-ai-launcher

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 原则上对应一次提交。
> `frontend/` 是独立子仓，所有 `git add/commit/push` 在子仓内执行；父仓最后只追加 submodule 指针 + 同步治理文档。
> 后端 `backend/` 本变更**完全不动**。
> 本变更是"区块内容注入"工作流的**收尾变更**：archive 时需要从主 `homepage-shell` spec 中**整条删除**"完全空容器" Requirement。

## 0. 前置检查

- [x] 0.1 确认前序 5 个 capability（hero / feature-nav / city-grid / hot-posts / hot-spots）已在 `openspec/changes/archive/` 下
- [x] 0.2 父仓与子仓 `git status` 干净，main 分支已合入前序变更
- [x] 0.3 父仓建工作分支 `change/homepage-ai-launcher`
- [x] 0.4 子仓建对应分支 `change/homepage-ai-launcher`
- [x] 0.5 Node ≥ 20.19

## 1. 子仓 — TDD R1（AiLauncherSlot 容器为 div + 渲染恰好 1 个 button）

### 1a. RED
- [x] 1a.1 改写 `frontend/app/regions/AiLauncherSlot.test.tsx`，3 个用例：
  - `renders div container with data-region="ai-launcher"`
  - `renders exactly one button with non-empty text`
  - `data file default-export is { buttonLabel: string }`
- [x] 1a.2 `npm test` 失败位置在 button 计数 = 0（旧 placeholder 实现下）
- [x] 1a.3 子仓提交：`test(homepage-ai-launcher): RED - AiLauncherSlot must render exactly one button`

### 1b. GREEN
- [x] 1b.1 新增 `frontend/app/regions/aiLauncher.data.ts`：
  ```ts
  export type AiLauncherContent = { buttonLabel: string };
  const aiLauncher: AiLauncherContent = { buttonLabel: "占位 AI 助手" };
  export default aiLauncher;
  ```
- [x] 1b.2 改写 `frontend/app/regions/AiLauncherSlot.tsx`：
  ```tsx
  import aiLauncher from "./aiLauncher.data";
  export default function AiLauncherSlot() {
    return (
      <div data-region="ai-launcher">
        <button>{aiLauncher.buttonLabel}</button>
      </div>
    );
  }
  ```
  > 注意：删除原 placeholder 形态下的 `aria-label="ai-launcher placeholder"` 属性。
- [x] 1b.3 `npm test` 1a 的 3 个用例 GREEN
- [x] 1b.4 子仓提交：`feat(homepage-ai-launcher): GREEN - render button from hard-coded data`

### 1c. REFACTOR
- [x] 1c.1 浏览代码，确认无冗余
- [x] 1c.2 `npm test` 仍全绿
- [x] 1c.3 子仓提交（无调整可跳过）

## 2. 子仓 — TDD R2（aria-label placeholder 移除 + 占位 button 不绑业务逻辑）

### 2a. RED
- [x] 2a.1 在 `AiLauncherSlot.test.tsx` 追加用例：
  - `container does not carry aria-label="ai-launcher placeholder"`
  - `button has no onClick handler invoking business logic`（可通过断言 `<button>` 上无 `onClick` prop 或仅 noop 实现）
- [x] 2a.2 按 TDD 临时让某用例 RED 验证断言有效，再恢复
- [x] 2a.3 子仓提交：`test(homepage-ai-launcher): RED - placeholder semantics removed and no business onClick`

### 2b. GREEN
- [x] 2b.1 1b.2 实现已不绑 onClick 且已删除 aria-label，2a 自然 GREEN
- [x] 2b.2 `npm test` 全绿
- [x] 2b.3 子仓提交：`test(homepage-ai-launcher): aria-label removed + no business onClick`

## 3. 子仓 — layout 集成测试断言强化

### 3a. RED
- [x] 3a.1 修改 `frontend/app/layout.test.tsx`，把"ai-launcher 在 children 之后"用例的断言从查容器存在升级为查容器内含 button：
  ```ts
  // 原：expect(container.querySelector('[data-region="ai-launcher"]')).not.toBeNull();
  // 新：const buttons = container.querySelectorAll('[data-region="ai-launcher"] button');
  //     expect(buttons.length).toBe(1);
  //     expect(buttons[0].textContent?.trim().length).toBeGreaterThan(0);
  ```
- [x] 3a.2 在已完成 §1b 的工作树上 `npm test`，layout 集成用例应 GREEN（因为 §1b 已交付 button）
- [x] 3a.3 临时 revert `AiLauncherSlot.tsx` 到 placeholder 验证 layout 测试 RED，再恢复
- [x] 3a.4 子仓提交：`test(homepage-shell): RED - layout integration assert ai-launcher contains button`

### 3b. GREEN
- [x] 3b.1 §1b 已实现 button，layout 测试自然 GREEN
- [x] 3b.2 `npm test` 全绿
- [x] 3b.3 子仓提交（如有 revert 痕迹清理）

## 4. 子仓 — 构建与回归

- [x] 4.1 `npm run build` 通过
- [x] 4.2 dev server `curl /` 含 `<div data-region="ai-launcher"><button>占位 AI 助手</button></div>`
- [x] 4.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 4.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 4.5 `git diff main..HEAD -- lib/backend.ts package.json` 输出为空
- [x] 4.6 `grep -E "fetchFromBackend|fetch\\(|import.*lib/backend" frontend/app/regions/AiLauncherSlot.tsx` 输出为空
- [x] 4.7 子仓推送 `change/homepage-ai-launcher`

## 5. 父仓追指针 + 治理同步

- [x] 5.1 父仓 `git add frontend` 追指针
- [x] 5.2 子仓更新 `frontend/README.md`：在《首页骨架》小节标注 ai-launcher 已注入（同时标记"骨架阶段"6 个 region 全部完成）
- [x] 5.3 父仓提交：`bump: frontend -> <new-sha> (homepage-ai-launcher)`
- [x] 5.4 父仓推送

## 6. 验证清单

- [x] 6.1 `cd frontend && npm test` 全绿（含 layout.test.tsx 强化后断言）
- [x] 6.2 `cd frontend && npm run build` 通过
- [x] 6.3 `find frontend/app -name 'route.ts' -o -name 'route.tsx'` 输出为空
- [x] 6.4 `head -1 frontend/lib/backend.ts` 输出 `import "server-only";`
- [x] 6.5 `frontend/app/regions/AiLauncherSlot.tsx` 中**未** import `lib/backend` / `fetchFromBackend` / `fetch(`
- [x] 6.6 `frontend/app/regions/aiLauncher.data.ts` 存在且 default-export 单对象
- [x] 6.7 `frontend/package.json` dependencies / devDependencies 字段未变
- [x] 6.8 父仓 `git diff --stat main..HEAD` 仅含 submodule 指针 + 本 change 4 件套

## 7. 归档（archive 时同步主 specs — 收尾操作）

- [x] 7.1 archive 阶段：从主 spec `openspec/specs/homepage-shell/spec.md` 中**整条删除**"所有 Slot 必须为完全空容器" Requirement（不留空骨架）
- [x] 7.2 archive 阶段：把 MODIFIED delta（"Layout 必须挂载 ai-launcher 常驻槽位"的强化版本，含 button 断言场景）应用到主 spec
- [x] 7.3 archive 阶段：把 ADDED 全部写入新主 spec `openspec/specs/homepage-ai-launcher/spec.md`
- [x] 7.4 移动 change 目录到 `openspec/changes/archive/<YYYY-MM-DD>-homepage-ai-launcher/`
- [x] 7.5 父仓提交归档：`chore(openspec): archive homepage-ai-launcher`
- [x] 7.6 archive 后核查：`openspec/specs/homepage-shell/spec.md` 中**无**"完全空容器" Requirement，**无**"FeatureNavSlot is excluded" 等过渡描述

## 8. 后续（不在本变更范围）

- [ ] 接入真实 AI 浮层 / 对话 UI（独立 propose）
- [ ] AI 助手后端集成（独立 propose / 跨子仓变更）
- [ ] AI 助手会话状态管理（独立 propose）
- [ ] 创建 `/ai/*` 业务路由（独立 propose）
- [ ] 视觉 / 交互层（浮层定位、动画、a11y 增强 — 独立 propose）

---

> **里程碑**：本变更归档后，Wanderchina 首页骨架阶段（7+1 份 spec：1 顶层 shell + 6 region capability + 1 http-server 同步）的"区块内容注入"工作流全部完成；此后每个 region 进入下一阶段（接入真实数据源 / 视觉布局 / 交互），按各自独立 propose 推进。
