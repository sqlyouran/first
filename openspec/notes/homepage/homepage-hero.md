# homepage-hero Spec

> 路径：`openspec/specs/homepage/homepage-hero.md`
> 承接挂载位：`homepage-shell` 在 `app/page.tsx` 第 1 个 region 提供的 `data-region="hero"` 槽位
> 实现位置：`frontend/app/regions/HeroSlot.tsx`（替换 shell 阶段的空 Slot）

## 0. 前置依赖（spec 可写、实现需先 propose）

本 spec 描述用 **Tailwind CSS + shadcn/ui** 构建的 Hero。当前 `frontend/` 工程**尚未引入** Tailwind 与 shadcn/ui（参见父仓 `AGENTS.md` 当前禁止动作清单）。本单元进入实现前，必须先开一个独立 change（建议命名 `frontend-styling-stack`）走 `/opsx:propose`，正式落地 Tailwind + shadcn/ui 的引入并同步更新 `AGENTS.md` 与 `openspec/project.md`。本 spec **不**重复定义那次依赖引入。

---

## 1. 模块边界

### 1.1 In Scope

- 全屏 Hero `<section data-region="hero">`，作为首页首屏视觉
- **品牌主视觉背景图**：`next/image` 的 `fill` 模式渲染，`priority` 优先加载，自带响应式 `sizes`
- **品牌主标语（headline）**：单一 `<h1>`，作为页面唯一一级标题
- **副标题（subheadline）**：紧随 `<h1>` 的 `<p>`，最多 2 行
- **装饰性搜索框**：shadcn `<Input />` + 装饰性 search icon，**仅 UI 占位**，不绑 onSubmit、不发请求、不路由
- **响应式（mobile-first）**：`< 640px` 单列 / `≥ 768px` 文案靠左 / `≥ 1024px` 大字号；以 Tailwind `sm/md/lg` 断点为准
- **无障碍**：`<h1>` 唯一、背景图 alt 必填、搜索框关联 `<label>`、焦点态可见

### 1.2 Out of Scope

- 任何**搜索行为**（输入处理、提交、跳转、自动补全、最近搜索）
- 视频背景、Banner 轮播、动效（Framer Motion 等）
- CTA 按钮、注册/登录入口
- 国际化（i18n）/ 多语言切换（本期文案为中文常量）
- 用户登录态相关展示
- Theming / 暗色模式切换（沿用项目默认）
- SEO meta 标签（属于 `app/layout.tsx` 或独立 spec 范畴）

---

## 2. 核心场景

### Scenario 1：桌面端首次访问（happy path）

- **WHEN** 用户在桌面浏览器（视口 `≥ 1024px`）首次发起 `GET /`
- **THEN** Next.js 服务端 SSR 返回 HTTP `200`
- **AND** 响应 HTML 中包含 `<section data-region="hero">`
- **AND** section 内含 1 个 `<h1>` 元素，文本为 props 注入的 `headline`
- **AND** section 内含 1 个 `<p>` 元素，文本为 props 注入的 `subheadline`
- **AND** section 内含 1 个 `<input type="search">`，`placeholder` 为 props 注入的 `searchPlaceholder`
- **AND** 背景图通过 `next/image` 输出（HTML 含 `<img srcset>` 或 Next 优化后的 `<img>`）

### Scenario 2：移动端首次访问

- **WHEN** 用户在移动设备（视口 `< 640px`）首次发起 `GET /`
- **THEN** Hero section 高度落在 `min-h-[70vh]` 与 `max-h-screen` 之间
- **AND** `<h1>` 字号使用 `text-3xl`（移动档）
- **AND** 副标题字号使用 `text-base`
- **AND** 搜索框宽度 `w-full`、单行展示、与文案左对齐
- **AND** 背景图 `next/image` 的 `sizes` 命中 `100vw` 分支（避免下发桌面尺寸大图）

### Scenario 3：搜索框被交互（装饰性守护）

- **WHEN** 用户在搜索框输入文本并按下回车
- **THEN** 不发起任何网络请求（`fetch`/`XHR` 计数为 0）
- **AND** 不发生页面导航（`window.location` 与 `next/router` 历史均无变化）
- **AND** 搜索框未被任何 `<form>` 包裹，或包裹的 `<form>` 显式 `onSubmit={(e) => e.preventDefault()}`

### Scenario 4：背景图加载失败（异常路径）

- **GIVEN** `backgroundSrc` 指向的资源返回 `404` 或网络中断
- **WHEN** 浏览器渲染 Hero
- **THEN** 文案区域（headline + subheadline + 搜索框）**仍然可读**
- **AND** Hero 容器存在 fallback 背景色 `bg-slate-900`（或 token 等价）作为兜底
- **AND** `<img>` 的 `alt` 属性回退为 `backgroundAlt`，被屏幕阅读器朗读

### Scenario 5：键盘可达性（无障碍）

- **WHEN** 用户使用 `Tab` 键依次聚焦
- **THEN** 焦点首个落在搜索框
- **AND** 搜索框出现可见 focus ring（shadcn 默认 `focus-visible:ring-2 focus-visible:ring-ring`）
- **AND** 屏幕阅读器按 DOM 顺序朗读：`<h1>` → `<p>` → 搜索框 label

### Scenario 6：SSR 首屏内容真实存在（非客户端水合产物）

- **WHEN** 在终端执行 `curl http://localhost:<port>/`
- **THEN** 输出的 HTML 字符串中**直接出现** `headline` 与 `subheadline` 文本
- **AND** 输出的 HTML 不含任何 `"use client"` 在 Hero 链路上的运行期标记（`HeroSlot` 是 Server Component）

### Scenario 7：违反 region 挂载契约（守护）

- **WHEN** 实现意外把 Hero 挂到 `data-region="hero"` 之外的位置
- **THEN** `app/page.test.tsx` 中"5 个 region 按文档顺序"的护栏测试 RED
- **AND** PR 被拦截（保护 `homepage-shell` spec 的挂载契约）

---

## 3. 数据结构

### 3.1 组件 Props

```ts
// frontend/app/regions/HeroSlot.tsx
import { type StaticImageData } from 'next/image';

export type HeroSlotProps = {
  /**
   * 主视觉背景图。可传 next/image 的 StaticImageData（推荐：编译期尺寸已知）
   * 或 public/ 下的 string 路径（回退方案）。
   */
  backgroundSrc?: StaticImageData | string;

  /**
   * 背景图无障碍替代文本。屏幕阅读器朗读，必填以满足 a11y。
   * 约束：1 ≤ length ≤ 120
   */
  backgroundAlt?: string;

  /**
   * 品牌主标语，渲染为页面唯一 <h1>。
   * 约束：1 ≤ length ≤ 30（CJK）/ ≤ 60（拉丁字符）；不允许换行符
   */
  headline?: string;

  /**
   * 副标题，渲染为 <p>。
   * 约束：1 ≤ length ≤ 80；最多 2 行（由 line-clamp 控制视觉）
   */
  subheadline?: string;

  /**
   * 装饰性搜索框 placeholder。
   * 约束：1 ≤ length ≤ 40
   */
  searchPlaceholder?: string;
};
```

### 3.2 默认值常量

```ts
// frontend/app/regions/hero.constants.ts
export const HERO_DEFAULTS = {
  backgroundSrc: '/images/hero-bg.jpg',     // public/images/hero-bg.jpg
  backgroundAlt: 'Wanderchina 主视觉：俯瞰中国山水城市',
  headline: '发现真正的中国，一次说走就走的旅行',
  subheadline: '从北京胡同到云南雪山，由本地玩家与 AI 助手共同为你导航',
  searchPlaceholder: '想去哪？输入城市、景点或攻略关键词…',
} as const satisfies Required<HeroSlotProps>;
```

### 3.3 约束摘要

| 字段 | 类型 | 必填 | 长度 | 备注 |
|---|---|---|---|---|
| `backgroundSrc` | `StaticImageData \| string` | 否（有默认） | — | 资源必须位于 `public/images/` 或 `import` 的静态资源 |
| `backgroundAlt` | `string` | 否（有默认） | 1–120 | 必须非空字符串，不允许仅空白 |
| `headline` | `string` | 否（有默认） | CJK 1–30 / 拉丁 1–60 | 单行，无 `\n` |
| `subheadline` | `string` | 否（有默认） | 1–80 | 视觉至多 2 行 |
| `searchPlaceholder` | `string` | 否（有默认） | 1–40 | 仅占位文本 |

> 所有 props 均可省略；零 prop 调用 `<HeroSlot />` 应渲染 `HERO_DEFAULTS` 对应的内容。

### 3.4 数据来源

- **静态常量**：本期所有文案与图片资源都是构建期常量，**不**通过 API 拉取
- **不引入** mock 数据文件（与 `homepage-hot-posts` / `homepage-hot-spots` 不同，Hero 没有"将来切真实 API"的契约面）
- **不依赖** `frontend/lib/backend.ts` 的 BFF helper

---

## 4. 验收标准（ACCEPTANCE Checklist）

> 实施完成后逐项勾选，全部命中方可申请 code review。

### 4.1 结构与挂载契约

- [ ] `frontend/app/regions/HeroSlot.tsx` 是 Server Component（无 `"use client"`）
- [ ] 渲染产物根节点为 `<section data-region="hero" aria-label="hero">`
- [ ] `app/page.tsx` 内 `data-region` NodeList 顺序仍为 `['hero','feature-nav','city-grid','hot-posts','hot-spots']`（`page.test.tsx` 仍 GREEN）
- [ ] `app/layout.tsx` 内 `<AiLauncherSlot />` 位置不变（未触动）

### 4.2 视觉与响应式

- [ ] 背景图通过 `next/image` 渲染，`fill` 模式 + `priority` + 合理的 `sizes`（如 `(max-width: 768px) 100vw, 100vw`）
- [ ] Tailwind 断点：`<h1>` 字号 `text-3xl md:text-5xl lg:text-6xl`
- [ ] 副标题字号 `text-base md:text-lg lg:text-xl`
- [ ] Hero 高度 `min-h-[70vh] md:min-h-[80vh]`
- [ ] 文字与背景图之间存在可读性遮罩（半透明渐变或暗化层），WCAG AA 文字对比度 ≥ 4.5:1

### 4.3 装饰性搜索框

- [ ] 使用 shadcn `<Input type="search" />`
- [ ] 不被 `<form>` 包裹，**或**包裹的 `<form>` 显式阻止默认提交
- [ ] 无 `onSubmit` / `onKeyDown` 处理 `Enter`，键入回车无任何副作用
- [ ] 搜索框关联 `<label htmlFor>`（视觉可隐藏 `sr-only`）

### 4.4 无障碍

- [ ] 全页唯一 `<h1>` 来自本组件
- [ ] 背景图 `alt` 非空且非空白
- [ ] 键盘 `Tab` 焦点可见（`focus-visible:ring`）
- [ ] 颜色对比度通过 axe / Lighthouse a11y 扫描

### 4.5 测试（TDD）

- [ ] 新增 `frontend/app/regions/HeroSlot.test.tsx`：
  - [ ] RED：断言渲染 `headline`、`subheadline`、`role="search"`/`type="search"` 元素 → 实现前失败
  - [ ] GREEN：实现后通过
  - [ ] 用例：默认 props 渲染 `HERO_DEFAULTS` 文案
  - [ ] 用例：自定义 props 覆盖默认值
  - [ ] 用例：搜索框无 `onSubmit`，按 Enter 无副作用（fireEvent.keyDown + 计数 fetch mock 为 0）
- [ ] `app/page.test.tsx` 仍 GREEN（挂载契约护栏未破）
- [ ] `frontend/app/HelloMessage.test.tsx` 仍 GREEN（BFF 链路覆盖未破）

### 4.6 端到端

- [ ] `cd frontend && npm run build` 通过，无 TS/ESLint 错误
- [ ] `cd frontend && npm test` 全绿
- [ ] `curl http://localhost:<port>/` 返回 HTML 中**直接包含** `headline` 与 `subheadline` 文本（验证 SSR）
- [ ] Lighthouse Performance（mobile）`LCP` 元素为 Hero 背景图，分数 ≥ 80
- [ ] Lighthouse Accessibility 分数 ≥ 95

### 4.7 边界守护

- [ ] `frontend/app/` 下未新增任何 `route.ts` / `route.tsx`（薄 BFF 边界）
- [ ] `frontend/lib/backend.ts` 首行仍为 `import "server-only";`
- [ ] `backend/` submodule 指针未变（本单元零后端改动）
- [ ] 父仓 `git diff --stat` 仅含 `openspec/specs/homepage/homepage-hero.md` 更新与 `frontend` submodule 指针 bump

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `data-region="hero"` 挂载位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | 引入 Tailwind + shadcn/ui |
| **与本单元正交** | `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher` | 各自独立 Slot，互不影响 |
| **本单元不依赖** | 任何后端 API、任何 mock 数据 | Hero 全静态 |
