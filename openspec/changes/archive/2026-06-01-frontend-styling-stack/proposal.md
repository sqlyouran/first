# Proposal: 引入前端样式栈（Tailwind CSS 4 + shadcn/ui + lucide-react）

## Why

Wanderchina 首页 6 个区块（hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher）的 spec 已经在 `openspec/specs/homepage/` 落盘。spec 评审过程中暴露出一个硬性事实：**这些区块在视觉、响应式与 a11y 上的复杂度，已经突破"骨架阶段保持 vanilla CSS"的边界**：

1. **组件复杂度跨过门槛**：hero 的全屏背景图 + 居中文案 + 装饰搜索框、ai-launcher 的桌面 Dialog / 移动 Sheet 双形态 + 焦点陷阱、city-grid 的 4→8 列响应式栅格——这些用 vanilla CSS 手写**性价比为负**，光焦点陷阱与 Dialog 的 a11y 实现成本就远高于一次性引入 Radix（shadcn 底层）。
2. **设计系统一致性需要token锚点**：6 个区块各自手写 spacing / radius / color，必然漂移。Tailwind 的 utility token 与 shadcn 的 CSS 变量提供统一的视觉锚。
3. **图标库无可替代**：feature-nav / ai-launcher / hot-posts 的 spec 里直接写了 `lucide-react` 的 `Users` / `MapPin` / `Sparkles` / `Heart` / `Eye` 等图标。继续手写 svg 既臃肿又破坏可读性。
4. **触发治理矫正**：父仓 `AGENTS.md` 当前「禁止动作」明列 `❌ 引入 Tailwind / shadcn-ui / 任何 CSS 框架（YAGNI，骨架阶段保持 vanilla CSS）`。该禁令的前提是"骨架阶段"，**首页 6 个区块的 spec 一旦签字就脱离了骨架阶段**，禁令同步失效。本变更顺势把治理文档矫正到位，杜绝后续 spec drift。

## What Changes

- **依赖引入**（仅 7 个 npm 包）：
  - `tailwindcss@^4` + `@tailwindcss/postcss` + `tailwindcss-animate` （devDependencies）
  - `class-variance-authority` + `clsx` + `tailwind-merge` + `lucide-react` （dependencies）
- **配置生成**：
  - `frontend/tailwind.config.ts`、`frontend/postcss.config.mjs`
  - `frontend/components.json`（shadcn CLI 配置：`new-york` / `slate` / CSS 变量模式）
  - `frontend/lib/utils.ts`（`cn` helper）
  - `frontend/app/globals.css` 追加 Tailwind directives + shadcn `:root` / `.dark` CSS 变量
- **shadcn 组件预装**：`button` / `card` / `input` 三件，落到 `frontend/components/ui/`。其它组件（Sheet / Dialog / Tabs / Form 等）由各区块单元在自己的 change 里**按需追加**，避免本变更范围爆炸。
- **TDD 集成验证**：用 `<Button>` 写一份 RED-GREEN，证明 Tailwind class 生效 / shadcn 组件可渲染 / lucide 图标可渲染 / `cn` 工具工作四件事端到端通。
- **同步治理文档**：
  - 父仓 `AGENTS.md` 「禁止动作」清单：移除「禁止引入 Tailwind / shadcn-ui」，改为「禁止引入 Tailwind + shadcn/ui + lucide-react 之外的其它 CSS 方案」。锁定栈表格新增样式栈一行。
  - 父仓 `openspec/project.md` 「技术栈」段：新增样式栈一行。
- **绝对不动**：`backend/`、任何业务 UI（区块单元自己的事）、暗色模式切换、自定义品牌色 token。

## Out of Scope

- **任何业务 UI**：6 个区块的具体实现由各自 change 承担。
- **Tailwind 自定义主题 token**（品牌色 / 字体）：用 shadcn 默认 `slate`；自定义留给独立 change `frontend-design-tokens`，触发条件为视觉规范定稿。
- **暗色模式切换**：CSS 变量段已为暗色预留 `.dark`，但 `next-themes` 集成留给独立 change `dark-mode-support`。
- **shadcn 组件全量预装**：仅 button / card / input；Sheet / Dialog / Tabs / Form / Sonner 等由具体使用方区块的 change 按需 add，避免装一堆然后没用上的死代码。
- **CSS-in-JS 方案**：styled-components / emotion / vanilla-extract 等明确不引入。
- **Storybook / 组件文档站**：YAGNI，团队规模与组件数量都不到引入门槛。
- **后端任何改动**（`backend/` 子仓 0 改动）。

## Open Questions

- [ ] **shadcn 风格选 `new-york` 还是 `default`？** 建议 `new-york`（卡片更紧凑、阴影更克制，与 wanderchina 的旅行内容调性更搭）。需在 design 阶段确认。
- [ ] **基础色选 `slate`、`zinc`、`neutral` 还是 `gray`？** 建议 `slate`（带轻微冷色调，配合后续可能的品牌主色更易调和）；后续 `frontend-design-tokens` 若覆盖品牌色，本选择不会成为阻塞。
- [ ] **Tailwind 4 vs 3.x？** Next.js 16 官方支持 Tailwind 4，shadcn 官方文档已同步 4.x 用法；建议直接 4。备选方案与回滚路径见 design.md。
- [ ] **预装组件是否要带 `dialog` 与 `sheet`？** 建议**不带**——它们由 ai-launcher 在自己的 change 里 add，本变更只装最小必需 3 件。
