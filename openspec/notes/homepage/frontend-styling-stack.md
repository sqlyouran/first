# frontend-styling-stack Spec

> 路径：`openspec/specs/homepage/frontend-styling-stack.md`
> 实现位置：`frontend/`（npm 依赖 + 配置文件 + `lib/utils.ts` + `components/ui/`）
> 角色：6 个区块单元（hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher）的**共享前置**；与 `homepage-shell` 并列、互不依赖
> 性质：**工具链/能力引入型**变更，不含业务 UI

## 0. 关键前提

本变更**推翻**父仓 `AGENTS.md` 当前「禁止动作」清单中的两条：

> ❌ 引入 Tailwind / shadcn-ui / 任何 CSS 框架（YAGNI，骨架阶段保持 vanilla CSS）

理由触发条件：6 个区块单元的 spec 已写定，组件复杂度（Card / Sheet / Dialog / Input + 响应式 + a11y）已经突破"骨架阶段"边界，继续手写 vanilla CSS 性价比为负。本变更同步把治理文档矫正到位，杜绝后续 spec drift。

---

## 1. 模块边界

### 1.1 In Scope

- **Tailwind CSS 4.x** 引入（Next.js 16 官方支持的版本）
  - 安装 `tailwindcss`、`@tailwindcss/postcss`、`tailwindcss-animate`
  - 配置 `tailwind.config.ts`、`postcss.config.mjs`
  - `app/globals.css` 接入 Tailwind directives 与 shadcn 设计 tokens（CSS 变量）
- **shadcn/ui 初始化**（`npx shadcn@latest init`）
  - 生成 `components.json`、`lib/utils.ts`（`cn` helper）
  - 选用风格 `new-york`、基础色 `slate`、CSS 变量模式（便于未来加暗色）
  - **预装 3 个组件**：`button` / `card` / `input`（覆盖 hero + feature-nav 的最小必需）
- **lucide-react 图标库**（shadcn 默认）
- **TS 路径别名** `@/*` 已存在（Next.js 16 脚手架自带），追加约束 `@/components/ui/*` 引用 shadcn 产物
- **TDD 集成验证**：用 `<Button>` 写一份 RED-GREEN，证明三层（Tailwind class 生效 / shadcn 组件可渲染 / lucide 图标可渲染）端到端通
- **治理文档同步**：
  - 父仓 `AGENTS.md`：禁止动作清单移除 Tailwind/shadcn 两项，禁止动作改为「引入除 Tailwind + shadcn/ui + lucide-react 外的其它 CSS 方案」
  - 父仓 `openspec/project.md`：技术栈段新增样式栈一行
  - 父仓 `openspec/specs/http-server/spec.md`：无需调整（HelloMessage 链路保留）

### 1.2 Out of Scope

- **任何业务 UI**：6 个区块单元各自承担
- **Tailwind 自定义主题 token**：用 shadcn 默认 `slate`；自定义品牌色由后续独立 change（建议 `frontend-design-tokens`）承接
- **暗色模式 / 主题切换**：CSS 变量已为暗色预留，但 `next-themes` 集成留给独立 change
- **shadcn 组件全量预装**：仅装 button / card / input；其它（Sheet / Dialog / Tabs / Form ...）由各区块单元 propose 时**按需追加**，避免本变更范围爆炸
- **CSS-in-JS 方案**：styled-components / emotion / vanilla-extract 等明确不引入
- **Storybook / 组件文档站**：YAGNI
- `backend/` 任何修改

---

## 2. 核心场景

### Scenario 1：Tailwind 实用 class 在浏览器生效（happy path）

- **GIVEN** 配置完成、dev server 已起
- **WHEN** 在 `app/page.tsx` 临时加入 `<div className="bg-red-500 p-4">x</div>` 并访问 `/`
- **THEN** 浏览器中该 div 的计算样式 `background-color` 等于 `rgb(239, 68, 68)`
- **AND** `padding` 等于 `1rem`
- **AND** 验证完移除该临时 div（不污染骨架）

### Scenario 2：shadcn Button 渲染并继承默认样式

- **WHEN** 在测试中 `render(<Button>Click</Button>)`
- **THEN** 输出 `<button>` 标签
- **AND** `className` 包含 shadcn 默认 token：`inline-flex` / `items-center` / `justify-center` / `rounded-md`
- **AND** 默认 variant 为 `default`，颜色用 CSS 变量 `bg-primary text-primary-foreground`

### Scenario 3：lucide 图标渲染

- **WHEN** `render(<Sparkles className="h-4 w-4" data-testid="ic" />)`
- **THEN** 输出 `<svg>` 元素
- **AND** svg 上 `aria-hidden="true"`
- **AND** 视觉尺寸 `1rem × 1rem`

### Scenario 4：路径别名 import 通过

- **WHEN** 在某文件写 `import { Button } from '@/components/ui/button'`
- **THEN** `npm run build` 与 `tsc --noEmit` 均通过
- **AND** 测试中该 import 也工作

### Scenario 5：构建产物体积合理（防 Tailwind 全量泄漏）

- **WHEN** `npm run build`
- **THEN** `/` 路由 First Load JS 增量 ≤ 50KB（相对引入前的 baseline）
- **AND** 构建产物 CSS 仅含实际使用过的 Tailwind class（Tailwind 4 自动 tree-shake 验证）
- **AND** 构建无 warning 关于"未识别 directive"

### Scenario 6：现有测试不被打断（回归）

- **WHEN** `cd frontend && npm test`
- **THEN** `HelloMessage.test.tsx` 仍 GREEN
- **AND** `app/page.tsx` 渲染产物视觉无破坏（仍渲染 hello 链路或骨架占位，取决于 `homepage-shell` 是否已 archive）

### Scenario 7：BFF 边界守护

- **WHEN** 在 `frontend/app/` 下执行 `find . -name 'route.ts' -o -name 'route.tsx'`
- **THEN** 输出为空（本变更不引入任何 Route Handler）

### Scenario 8：governance 文档同步（spec drift 矫正）

- **WHEN** 在父仓 `grep -n 'Tailwind' AGENTS.md`
- **THEN** 命中行不再出现「❌ 引入 Tailwind」
- **AND** 「锁定栈」表格新增样式栈行：`样式 | Tailwind CSS 4 + shadcn/ui + lucide-react | shadcn 提供 a11y / 设计 token / Radix 实现`

### Scenario 9：异常路径——npm 安装失败回滚

- **GIVEN** 运行 `npm install` 时网络超时
- **WHEN** 任一依赖 install 失败
- **THEN** 终止本变更实施
- **AND** 子仓 `git checkout -- package.json package-lock.json` 回滚
- **AND** 不进入 GREEN 阶段（守护 RED→GREEN 链路完整性）

### Scenario 10：异常路径——shadcn init 与项目结构冲突

- **GIVEN** `npx shadcn@latest init` 提示是否覆盖 `app/globals.css`
- **WHEN** 用户/agent 选择"覆盖"
- **THEN** 覆盖前必须先 `git diff` 备查
- **AND** 覆盖后人工对比，确保未删除现有 globals.css 中已有的非 Tailwind 自定义规则（当前为空，但建立流程）

---

## 3. 依赖与配置结构

### 3.1 npm 依赖清单

```jsonc
// frontend/package.json 增量
{
  "dependencies": {
    "class-variance-authority": "^0.7.x",
    "clsx": "^2.x",
    "lucide-react": "^0.x",   // 取最新 LTS
    "tailwind-merge": "^2.x"
  },
  "devDependencies": {
    "tailwindcss": "^4.x",
    "@tailwindcss/postcss": "^4.x",
    "tailwindcss-animate": "^1.x"
  }
}
```

> 不含 `shadcn` 自身；shadcn 是 CLI（`npx shadcn`），组件源码直接下载到 `components/ui/`，不作为运行时 npm 依赖。

### 3.2 新增/修改的配置文件

```
frontend/
├── components.json              新增（shadcn CLI 配置）
├── tailwind.config.ts           新增
├── postcss.config.mjs           新增
├── app/
│   └── globals.css              修改（追加 Tailwind directives + shadcn CSS 变量）
├── components/                  新增目录
│   └── ui/
│       ├── button.tsx           shadcn add button
│       ├── card.tsx             shadcn add card
│       └── input.tsx            shadcn add input
├── lib/
│   ├── backend.ts               不动
│   └── utils.ts                 新增（cn helper，shadcn init 自动生成）
├── tsconfig.json                不动（@/* 别名已存在）
└── package.json                 修改（依赖 + scripts 不变）
```

### 3.3 关键配置内容约束

#### `components.json`（shadcn 生成）
```jsonc
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "app/globals.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui"
  }
}
```

#### `tailwind.config.ts`
```ts
import type { Config } from 'tailwindcss';

export default {
  darkMode: ['class'],
  content: [
    './app/**/*.{ts,tsx}',
    './components/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {}, // 默认 token，自定义留给 frontend-design-tokens
  },
  plugins: [require('tailwindcss-animate')],
} satisfies Config;
```

#### `app/globals.css`（追加段，已有内容保留）
```css
@import 'tailwindcss';

@layer base {
  :root {
    /* shadcn slate base color CSS vars，由 shadcn init 写入 */
  }
  .dark {
    /* dark variant 预留（暗色模式留给独立 change 启用） */
  }
}
```

#### `lib/utils.ts`（shadcn init 生成）
```ts
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

### 3.4 约束摘要

| 项 | 约束 |
|---|---|
| 风格 | shadcn `new-york`，CSS 变量模式（必须 `cssVariables: true`） |
| 基色 | `slate`（默认）；自定义品牌色不在本变更范围 |
| 预装组件 | 仅 `button` / `card` / `input` 三件 |
| 别名 | `@/components` / `@/lib/utils` / `@/components/ui` 必须与 `components.json` 对齐 |
| 暗色模式 | `darkMode: ['class']` 配置就位，但**不**在 layout 中切换主题 |
| 图标库 | 仅 `lucide-react`；其它（heroicons / phosphor / fontawesome）不引入 |
| 文件位置 | shadcn 组件必须落到 `frontend/components/ui/`，**不**散落到 `app/` |

### 3.5 数据来源

- 无业务数据；本变更引入的是工具链与配置
- 不接 API、不引入 mock、不读 env

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 依赖安装

- [ ] `frontend/package.json` 含上述 4 个 `dependencies` + 3 个 `devDependencies`
- [ ] `frontend/package-lock.json` 已更新并提交（version pinning 走 npm 默认策略）
- [ ] `npm install` 在干净环境一次成功，无 `npm warn` 关于 peer dependency 不满足

### 4.2 配置文件

- [ ] `components.json` 存在且内容与本 spec 第 3.3 节一致
- [ ] `tailwind.config.ts` 存在，`content` 字段含 `app/**` 与 `components/**` 两条
- [ ] `postcss.config.mjs` 存在，含 `@tailwindcss/postcss` plugin
- [ ] `app/globals.css` 含 Tailwind 入口（`@import 'tailwindcss';`）+ shadcn `:root` / `.dark` CSS 变量段
- [ ] `lib/utils.ts` 存在并 export `cn` 函数

### 4.3 shadcn 组件预装

- [ ] `components/ui/button.tsx` 存在并 default-or-named export `Button` + `buttonVariants`
- [ ] `components/ui/card.tsx` 存在
- [ ] `components/ui/input.tsx` 存在
- [ ] 三个组件文件未被人工修改（保持 shadcn 原版，便于未来 `npx shadcn@latest diff` 升级）

### 4.4 集成 TDD

- [ ] 新增 `frontend/components/ui/__tests__/button.test.tsx`：
  - [ ] **RED**：实现前直接 import `Button` 失败 → 期望 RED
  - [ ] **GREEN**：shadcn add button 后用例通过
  - [ ] 用例 1：`render(<Button>x</Button>)` 输出 `<button>` 含 `inline-flex` class
  - [ ] 用例 2：`render(<Button variant="outline">x</Button>)` 输出 class 含 `border`
  - [ ] 用例 3：`render(<Sparkles data-testid="ic" />)` 输出 `<svg>` 且 `aria-hidden="true"`
  - [ ] 用例 4：`import { cn } from '@/lib/utils'` 后 `cn('a', 'b')` 返回 `'a b'`，`cn('p-2', 'p-4')` 返回 `'p-4'`（验证 tailwind-merge 工作）
- [ ] 现有 `HelloMessage.test.tsx` 仍 GREEN

### 4.5 端到端

- [ ] `cd frontend && npm run build` 通过，无 warning
- [ ] `cd frontend && npm test` 全绿
- [ ] dev server 起后访问 `/`，临时验证 div `bg-red-500` 渲染为红色（验证完移除）
- [ ] First Load JS 增量 ≤ 50KB（与基线对比）

### 4.6 治理文档同步

- [ ] 父仓 `AGENTS.md` 「禁止动作」清单中：
  - [ ] 移除 `❌ 引入 Tailwind / shadcn-ui / 任何 CSS 框架（YAGNI，骨架阶段保持 vanilla CSS）`
  - [ ] 新增 `❌ 引入 Tailwind + shadcn/ui + lucide-react 之外的 CSS 方案（styled-components / emotion / vanilla-extract 等）`
- [ ] 父仓 `AGENTS.md` 「锁定栈」表格新增样式栈一行
- [ ] 父仓 `openspec/project.md` 「技术栈」段新增：`样式：Tailwind CSS 4 + shadcn/ui (new-york / slate) + lucide-react`
- [ ] 7 份 homepage spec 中第 0 节"前置依赖"语义保持自洽（无需逐份改写）

### 4.7 边界守护

- [ ] `frontend/app/` 下未新增 `route.ts` / `route.tsx`
- [ ] `frontend/lib/backend.ts` 首行仍为 `import "server-only";`
- [ ] `backend/` submodule 指针未变（本变更零后端改动）
- [ ] 未引入除清单内 7 个外的任何 npm 包
- [ ] `components/ui/` 下文件数 = 3（仅预装件）

### 4.8 提交边界

- [ ] 子仓提交（按提交粒度建议）：
  - [ ] `feat(styling): install tailwind + shadcn + lucide and configure`
  - [ ] `feat(styling): add button/card/input shadcn components with TDD`
- [ ] 父仓提交：
  - [ ] `docs(governance): allow tailwind+shadcn stack; sync agents/project`
  - [ ] `bump: frontend -> <new-sha> (frontend-styling-stack)`

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **本单元依赖** | 无 | 与 `homepage-shell` 并列，可并行 propose；archive 顺序不限 |
| **被本单元解锁** | `homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher` | 6 个区块均依赖本单元提供 Tailwind class 与 shadcn 组件可用 |
| **本单元先于** | `frontend-design-tokens`（未来 propose） | 自定义品牌色 / 字体 token 在本变更引入的 CSS 变量基础上扩展 |
| **本单元先于** | `dark-mode-support`（未来 propose） | 暗色模式切换在本变更预留的 `.dark` CSS 变量段基础上启用 `next-themes` |
| **不依赖** | `backend/` 改动、任何 mock 数据、任何后端 API | 纯前端工具链 |

---

## 6. 实施次序建议（不构成 spec 内容，仅备忘）

> 本节不进入 acceptance，仅为 apply 阶段拆 tasks.md 的参考。

1. 子仓建工作分支 `change/frontend-styling-stack`
2. 安装 Tailwind 依赖 → 配置 `tailwind.config.ts` / `postcss.config.mjs` / `globals.css`
3. 验证 Tailwind class 在浏览器生效（Scenario 1）
4. `npx shadcn@latest init` → 选 `new-york` / `slate` / CSS 变量
5. `npx shadcn@latest add button card input`
6. 写 `button.test.tsx` 集成测试（RED → GREEN）
7. `npm run build` + `npm test` 全绿
8. 父仓 governance 文档同步（AGENTS.md / openspec/project.md）
9. 子仓推送 + 父仓追指针 + 父仓 push
