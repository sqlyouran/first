# Design: 前端样式栈引入

## Context

- **现状**：`frontend/` 是 Next.js 16 + React 19 + TypeScript，无任何 CSS 框架；样式仅靠 `app/globals.css` 默认骨架样式与 `app/page.module.css`。
- **触发**：首页 6 个区块 spec 已落盘，组件复杂度（响应式栅格、Dialog/Sheet 双形态、焦点陷阱、设计 token 一致性）已突破"骨架阶段保持 vanilla CSS"的初始约束。
- **约束**：
  - 父仓 `AGENTS.md` 「技术选型约束」长期场景下决策维度优先级：可持续迭代能力 > 生态成熟度 > 框架约定强度 > 学习成本 > AI 生成质量 > 部署敏捷度。
  - 团队基线：前端 React 经验充足。
  - BFF 边界：本变更不允许引入任何 Route Handler / Server Action（无业务后端逻辑下沉）。

## Goals

1. 引入业界主流且与 Next.js 16 / React 19 兼容良好的样式栈，覆盖 6 个区块单元的全部视觉与交互需求。
2. 引入即可用：装完跑一份 TDD 集成测试证明端到端通，杜绝"装了但不知道是否生效"的悬空状态。
3. 同步矫正治理文档，避免后续 spec 与 AGENTS.md 出现漂移。
4. 范围最小化：仅装最小必需的 3 个 shadcn 组件，其余由具体使用方区块按需追加。

## Non-Goals

- 自定义品牌色 / 字体 / 自定义阴影 token（`frontend-design-tokens` 独立承担）。
- 暗色模式切换 UI 与 `next-themes` 集成（`dark-mode-support` 独立承担）。
- 任何业务区块的实现（各 homepage-* change 独立承担）。
- 组件文档站（Storybook 等）。
- 后端样式相关改动（不存在）。

## Decisions

### D1：选择 Tailwind CSS + shadcn/ui + lucide-react 作为样式栈

**决策**：采用 Tailwind 4 + shadcn/ui (new-york / slate / CSS 变量) + lucide-react 三件套。

**Rationale**：
- **Tailwind**：utility-first、与 Next.js 16 官方深度兼容、tree-shake 默认开启、社区生态最大、AI 生成质量在 CSS 类工具里居首。
- **shadcn/ui**：不是 npm 组件库而是 CLI scaffold——把 Radix + Tailwind 的成品代码下载到本仓，**完全可控可改可读**，避免黑盒依赖。提供 a11y、键盘导航、焦点陷阱等开箱即用，覆盖 ai-launcher Dialog/Sheet 的全部 a11y 验收要求。
- **lucide-react**：shadcn 官方默认图标库；tree-shake 友好（按图标 import）；图标命名稳定（不像 heroicons 改过 v1→v2 命名）。

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| 继续 vanilla CSS | 焦点陷阱与 Dialog a11y 手写工作量过大；6 区块视觉一致性无锚点 |
| CSS Modules + 自研组件 | 解决一致性但 a11y / Dialog / Sheet 仍需手写，工作量倒灌区块单元 |
| MUI / Chakra UI / Ant Design | 黑盒组件库，定制成本高；样式重写难度大；包体积显著大于 shadcn 增量 |
| styled-components / emotion | CSS-in-JS 与 RSC 兼容性历史问题（hydration mismatch 风险）；Tailwind 在 React 19 + RSC 场景生态更稳 |
| panda-css / vanilla-extract | 团队零经验；学习成本不符合优先级 4「学习成本归零原则」 |
| Bootstrap 5 | 与 Tailwind 哲学冲突；与 React 生态适配度低 |

### D2：Tailwind 选 v4 而非 v3.x

**决策**：使用 `tailwindcss@^4` + `@tailwindcss/postcss`。

**Rationale**：
- Next.js 16 官方文档示例已切到 Tailwind 4。
- shadcn 官方文档同步支持 v4，CLI `init` 自动生成 v4 配置。
- v4 配置更简单（直接 `@import 'tailwindcss';`，无需手写 `@tailwind base/components/utilities`）。
- 生态新但已稳定 6+ 月，主流 SaaS 已迁移完成。

**回滚路径**：若 Tailwind 4 在本仓出现编译问题，回滚到 `tailwindcss@^3.4` + 经典 `tailwind.config.js` 即可，shadcn 同时支持两版配置；改动面控制在 `tailwind.config.ts` / `postcss.config.mjs` / `globals.css` 三个文件。

### D3：shadcn 风格选 `new-york`，基础色选 `slate`

**决策**：`style: new-york`、`baseColor: slate`、`cssVariables: true`。

**Rationale**：
- `new-york` vs `default`：`new-york` 卡片更紧凑、阴影更克制，与旅行内容图片为主的视觉调性更搭。`default` 风格更柔和但留白偏大，对密集图文卡片不利。
- `slate` vs `zinc/neutral/gray`：`slate` 带轻微冷色，配合后续可能的品牌色（蓝绿系大概率）更易调和。`gray` 偏中性但与图片层叠时层次感弱。
- `cssVariables: true`：把颜色 token 落到 CSS 变量，**为后续 `frontend-design-tokens` 与 `dark-mode-support` 留出零成本扩展点**——届时只改 CSS 变量值，不动业务组件 class。

### D4：仅预装 button / card / input 三件，其余按需追加

**决策**：本变更只 `npx shadcn@latest add button card input`。Sheet、Dialog、Tabs、Form、Sonner 等由具体使用方的 change 按需追加。

**Rationale**：
- **YAGNI 直接命中**：装一堆但不用，等于把死代码塞进 git 历史。
- **变更范围可控**：本变更聚焦"工具链引入"，每多一个组件预装就多一份 acceptance 检查。
- **冲突收敛**：6 个区块 PR 各自 `shadcn add` 自己用到的组件，conflict 仅落在 `package.json` / `components.json`，按 PR 顺序 rebase 即可化解，比一次预装等所有区块来吃要灵活。

**例外考量**：button / card / input 之所以预装，是因为它们的"被使用频次 ≥ 4 个区块"已经在 spec 里写明（hero 装饰搜索 input、feature-nav/city-grid/hot-posts/hot-spots 都用 card）。

### D5：路径别名沿用 `@/*`，shadcn 组件落 `components/ui/`

**决策**：`tsconfig.json` paths 沿用 `@/*`（Next.js 16 脚手架自带，不改）。`components.json` 的别名设为 `@/components` / `@/lib/utils` / `@/components/ui`。

**Rationale**：
- 与 Next.js 16 默认结构一致，新人 0 学习成本。
- shadcn 组件统一落 `components/ui/`，业务组件按区块落 `components/<region>/`，结构清晰。
- 未来 `npx shadcn@latest diff <component>` 升级时路径稳定。

### D6：TDD 用 `<Button>` 而非自写 demo 组件做集成验证

**决策**：测试文件 `frontend/components/ui/__tests__/button.test.tsx`，用例覆盖：渲染 + variant class + lucide 图标渲染 + `cn` 合并。

**Rationale**：
- 一份测试同时验证 4 件事，性价比最高：Tailwind class 生效（断言 class 字符串）、shadcn Button 可渲染（断言 DOM）、lucide 可渲染（断言 svg + aria-hidden）、`cn` 工具工作（tailwind-merge 冲突合并）。
- 用 shadcn 原生 Button 而非自写 demo：验证目标是"shadcn 真接进来了"，自写 demo 反而绕开真实集成路径。
- RED 阶段：测试文件先写好，import 失败即 RED；shadcn add button 后 GREEN——天然契合 RED→GREEN 节奏。

### D7：治理文档更新粒度

**决策**：本变更同步更新父仓 `AGENTS.md` 与 `openspec/project.md`；不动 `openspec/specs/http-server/spec.md`（HelloMessage 链路不受影响）。

**Rationale**：
- 不矫正 AGENTS.md 等于 6 个区块单元下次 propose 时仍然在违反禁止动作清单——必须本变更同步矫正。
- `openspec/project.md` 是项目级技术栈索引，新增样式栈一行让后续新人 onboarding 一眼能看到。
- `http-server/spec.md` 描述的是 `/api/hello` 与 SSR 链路，与样式栈零交集，不动。

### D8：BFF 边界守护进入 acceptance

**决策**：acceptance 中明列「`frontend/app/` 下不新增 `route.ts` / `route.tsx`」「`lib/backend.ts` 首行仍为 `import 'server-only';`」两条。

**Rationale**：本变更看起来与 BFF 无关，但 shadcn `init` CLI 默认会问是否生成 `app/api/auth/route.ts` 的占位（取决于版本）；明确 acceptance 杜绝意外引入。

### D9：Capability 命名为 `frontend-styling`，与项目级「每 change 一 capability」约定对齐

**决策**：本变更的 capability 主索引落在 `openspec/specs/frontend-styling/spec.md`（archive 后），change 内 delta 文件路径为 `openspec/changes/frontend-styling-stack/specs/frontend-styling/spec.md`。

**Rationale**：
- 这是项目级 OpenSpec 约定（见 `openspec/project.md` 「OpenSpec Conventions」段）：每个 change 一个独立 capability，命名与 change 名一致（去掉 `-stack` 后缀避免冗余）。
- 该约定下 6+ 个 homepage change 可并行 apply 而不在 archive merge 时打架。
- 同步约定：人类可读的中文工程 brief 放 `openspec/notes/homepage/`（不入 OpenSpec CLI 工作流），与 capability spec 严格分工。本 change 对应的 brief 在 `openspec/notes/homepage/frontend-styling-stack.md`。

**Alternatives considered**：
- 「homepage 一个大 capability，所有 7 个 change 都加进去」——否决：archive 时 7 个 change 改同一 `homepage/spec.md`，并行流断裂。
- 「按视觉层次切（skeleton / content / overlay）」——否决：粒度模糊，homepage-hero 该归 content 还是 skeleton 边界不清。

## Risks & Mitigations

| 风险 | 触发条件 | 处置 |
|---|---|---|
| Tailwind 4 与 Next.js 16 编译不兼容 | `npm run build` 报 PostCSS plugin 错 | 回滚到 Tailwind 3.4 + 经典配置（D2 回滚路径） |
| shadcn init 覆盖现有 `globals.css` 中的非 Tailwind 自定义规则 | 当前 globals.css 已有的非默认规则 | init 前 `git diff` 备查，覆盖后人工对比；当前 globals.css 仅含 Next 16 默认骨架样式，风险低 |
| First Load JS 增量超 50KB | Tailwind / shadcn 树摇失效 | 检查 `tailwind.config.ts` 的 `content` 字段；必要时分析 `npm run build` 输出 |
| 6 区块并行 PR 在 `package.json` / `components.json` 大量冲突 | 多个 PR 同时 add shadcn 组件 | 推荐 rebase 而非 merge；约定 PR 顺序：先视觉基建型（hero / feature-nav）再数据驱动型 |
| AGENTS.md 同步遗漏 | 文档同步只是治理性步骤，可能被遗忘 | acceptance 中明列勾选项 + 第 7 节专项 task |

## Open Questions

均在 proposal.md「Open Questions」中提出。design 阶段建议默认结论：
- shadcn 风格 → `new-york`
- 基础色 → `slate`
- Tailwind 版本 → `4.x`
- 预装组件 → `button` / `card` / `input` 三件

如用户在 apply 前不另行指定，按上述默认推进。
