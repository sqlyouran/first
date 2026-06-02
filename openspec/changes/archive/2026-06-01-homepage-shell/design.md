# Design: 首页骨架（homepage-shell）

> 本变更的可读性 brief：`openspec/notes/homepage/homepage-shell.md`

## Context

本变更是首页 6 区块并行落地的**前置骨架**。骨架本身不承担业务，只锁定三个契约：

1. **挂载位契约**：6 个 region 各自的容器位置（5 个在 page.tsx，1 个在 layout.tsx）
2. **命名契约**：每个 Slot 根容器带 `data-region="<name>"`，name 为 kebab-case
3. **结构契约**：5 个页内 region 用 `<section>`，ai-launcher 用 `<div>`；所有 Slot 渲染**单一空容器**

后续 6 个区块 change 不再讨论"挂哪儿"，只讨论"Slot 内部填什么"。

## 核心决策

### D1：严格顺序——前置依赖 `frontend-styling-stack` archive

**决策**：本变更可在 styling-stack 仍是 active proposal 时同步 propose，但 **apply 必须等 styling-stack 完成 archive 之后**。

**Rationale**：
- styling-stack 的 `tasks.md` 2a.1 在 `app/page.tsx` 注入 Tailwind 探针 div，5.4 验收"dev server 起：/ 视觉无破坏（**仍渲染 HelloMessage 链路**）"
- 若 shell 先 apply，page.tsx 重写为 5 Slot，styling-stack 的探针注入位消失、视觉验收语义失效
- 顺序改成 styling-stack 先：探针在 HelloMessage 形态的 page.tsx 上插入与移除，shell 后续重写 page.tsx 时 styling-stack 已 archive，互不干扰

**Alternatives considered**：
- 「真并行（两个 worktree 同改 page.tsx）」：merge 必冲突，否决
- 「shell 先 apply、回头改 styling-stack 的 2a.1 + 5.4」：styling-stack 已 validate 通过，回头改增加返工面，否决

**强制 trigger**：apply 启动前必须验证 `openspec/changes/archive/<date>-frontend-styling-stack/` 目录已存在（即 styling-stack 已归档）。

---

### D2：Slot 占位 = 完全空容器（不放任何文本/灰底/min-height）

**决策**：所有 Slot 渲染**唯一一个**带 `data-region` + `aria-label` 的空元素，无任何子节点、无任何 inline style。

```tsx
export default function HeroSlot(): JSX.Element {
  return <section data-region="hero" aria-label="hero placeholder" />;
}
```

**Rationale**：
1. shell 的 Out of Scope 第 2 条明确"不引入 CSS 框架"，B3 灰底骨架方案直接违规
2. 完全空白的页面**比假灰块更诚实**——人类一眼能识别"骨架阶段未完成"，不会误以为产品形态
3. Scenario "Slot 独立渲染产物为空" 的强语义守护：未来若有人在某个 Slot 偷加内容，独立单测立刻报错
4. 回滚成本：B1 → B3 是单向 commit；B3 → B1 是删占位代码 + 改测试，反而更累

**Alternatives considered**：
- 「文本占位 `[hero placeholder]`」：测试需断言文本，hero 等区块实施时要先删占位，反向阻塞
- 「Tailwind 灰底 + min-height」：违反 Out of Scope；且需要 styling-stack 已 archive 才能用 Tailwind class
- 「dev-only banner 提示骨架阶段」：违反 YAGNI，README/PR description 已足够

---

### D3：HelloMessage + lib/backend.ts 保留，page.tsx 不再 import

**决策**：
- `app/HelloMessage.tsx` 与 `app/HelloMessage.test.tsx` 保留不动
- `lib/backend.ts` 保留不动，首行仍 `import "server-only";`
- `app/page.tsx` 重写后**不再 import** HelloMessage 与 fetchFromBackend

**Rationale**：
1. **lib/backend.ts 是项目级 BFF 边界守护点**：「首行必须 `import 'server-only'`」被 styling-stack、shell 自己以及未来 6 区块的 acceptance 反复引用。删了护栏失效
2. **HelloMessage.test.tsx 是 client component 渲染契约样本**：保留 1 份活体测试参考，未来 hero 实施时可作为模板
3. **不强制 HelloMessage 引用 lib/backend**：lib/backend 的存在性由文件系统保证，不要求被某个组件 import；hero 接入真实数据时再形成新的活体引用

**Alternatives considered**：
- 「删 HelloMessage，仅留 lib/backend」：丢掉 1 个 SSR 链路覆盖测试，BFF 探针变得抽象
- 「移到 `__examples__/` 不入 build」：违反 YAGNI，"为了文档目的留代码"
- 「等 hero 实施时一并清理」：决策推迟，期间是脏状态。本期保留更明确

**衍生约束**：本变更**不**新增"lib/backend.ts 必须有人 import"的护栏。

---

### D4：AI 入口直挂 root layout（C1），未来按 trigger 提到路由组

**决策**：本期 `<AiLauncherSlot />` 直接挂在 `app/layout.tsx` 的 `{children}` 之后。**不**预先创建 `app/(public)/` 路由组。

**Rationale**：
- 当前路由仅 `/`，**只有 1 条业务路由**
- 为"未来可能有 `/admin`"提前划路由组是教科书级 YAGNI 违规
- 未来真要加 `/admin`，迁移成本极低：`git mv app/page.tsx app/(public)/page.tsx`、把 launcher 从 root layout 提到 `(public)/layout.tsx`，3 行变更

**未来 trigger（写入 Open Questions）**：当出现**第 2 条非 `/` 业务路由**且该路由**不希望渲染 AI 助手**时，需 propose 把 launcher 从 root layout 提到路由组 layout。

**Alternatives considered**：
- 「现在就划路由组」：YAGNI 违规
- 「root layout 内 `usePathname()` 运行时判断」：layout 变 client component，丧失 SSR 优势；且判断逻辑会随路由增加变臭

**衍生约束**：ai-launcher brief 第 5 节"feature-nav 卡片 href=`#ai-launcher` 触发面板打开"是 ai-launcher 自己的 Out of Scope/可选项，**shell 阶段不在 layout 留 hash hook**。

---

### D5：Capability 命名为 `homepage-shell`，与项目级约定对齐

**决策**：本变更的 capability delta 路径为 `openspec/changes/homepage-shell/specs/homepage-shell/spec.md`；archive 后落于 `openspec/specs/homepage-shell/spec.md`。

**Rationale**：遵循项目级 OpenSpec 约定（见 `openspec/project.md` 「OpenSpec Conventions」段）：每个 change 一个独立 capability，命名与 change 名一致。该约定确保 6+ 个 homepage change 可并行 apply 而不在 archive merge 时打架。

**对照 brief**：人类可读的中文工程 brief 在 `openspec/notes/homepage/homepage-shell.md`（不入 OpenSpec CLI 工作流），与 capability spec 严格分工。

## Risks & Mitigations

| 风险 | 触发条件 | 处置 |
|---|---|---|
| 早于 styling-stack archive 启动 apply | 误读 D1 / 急于推进 | tasks 0.0 强制检查 `openspec/changes/archive/<date>-frontend-styling-stack/` 存在 |
| 区块单元偷加 Slot 内部内容 | 6 区块 propose 时跳过 spec 直接写代码 | spec R6 + 各 Slot 独立单测断言"无任何子节点"；code review 时强制走 OpenSpec 流程 |
| HelloMessage 测试在 shell apply 后偶然失败 | 重写 page.tsx 时误改 HelloMessage 文件 | tasks 5.x 验收明确"HelloMessage.test.tsx 不动且仍 GREEN" |
| layout.tsx 挂 launcher 引发未来非 `/` 路由意外渲染 | 未来加 `/admin` 时忘了 D4 trigger | Open Questions 显式声明 trigger；`AGENTS.md` 同步追加路由扩展时的 propose 触发条件 |
| Slot 命名 kebab-case 与文件名 PascalCase 错配 | 区块实施时手抖把 `data-region="HeroSlot"` 之类写错 | spec R1 严格断言 `data-region` 字符串列表；Slot 独立单测兜底 |
