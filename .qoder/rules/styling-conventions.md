---
trigger: always_on
alwaysApply: true
---
# 样式规约

样式栈锁定为 Tailwind CSS 4 + shadcn/ui (base-nova / neutral) + lucide-react。以下为 SHOULD 级约定。

## 视觉设计原则

### 品牌视觉定位

对标国际目的地营销站（Visit Japan / Tourism New Zealand）。整体调性：**大留白、全幅摄影、克制配色、探索感**。不追求"酷炫"或"促销感"，追求"可信赖 + 值得探索"。

### 图片处理

- 全幅摄影场景（Hero）用渐变叠层保证文字可读：`bg-gradient-to-r from-black/60 to-transparent`
- 卡片内图片用固定 aspect-ratio：风景 `aspect-[16/9]`，卡片 `aspect-[4/3]`
- 图片填充：`bg-cover bg-center`，不拉伸不裁切主体
- 占位期用 picsum.photos，后续切真实图只改 URL 不改组件结构

### 排版节奏

文字层级递进，每一层有明确的视觉落差：

| 层级 | 字号 | 字重 | 色彩 |
|------|------|------|------|
| 大标题（Hero） | `text-5xl lg:text-6xl` | bold | white |
| 区块标题 | `text-3xl lg:text-4xl` | bold | slate-900 |
| 卡片标题 | `text-lg` ~ `text-2xl` | semibold / bold | slate-900 |
| 正文 | `text-sm` | normal | slate-600 |
| 辅助信息 | `text-sm` | normal | slate-500 |

### 交互反馈

- 卡片悬浮：`transition-shadow hover:shadow-lg`（浮起感）
- 按钮/链接色变：`hover:bg-blue-800` / `hover:text-blue-800`
- 过渡时长：依赖 Tailwind 默认（150ms–300ms），不自定义 duration
- 不加花哨动效（fade / slide / parallax），留给独立 change

### 无障碍底线

- 文字对比度 ≥ 4.5:1（WCAG AA），白字需叠层渐变兜底
- 可聚焦元素保留 `focus-visible` ring（shadcn 默认提供）
- 图标按钮需搭配 `aria-label` 或可见文字
- 图片容器用 `aria-hidden="true"`（装饰性）或提供 alt text（内容性）

## 页面完成度

> **MUST 级约束**：每个页面在交付时必须满足以下标准。不接受"功能能跑但视觉裸奔"的 MVP 状态上线——页面必须同时具备专业的视觉美观度与完整的可用性，这是交付底线而非锦上添花。

### 页面结构骨架

所有内容页面（非首页 Region）SHOULD 遵循统一结构：

```
<div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
  <div className="mx-auto max-w-{N}xl px-8 py-16 sm:px-12 lg:px-16">
    <!-- 返回导航（可选） -->
    <!-- 页面标题 + 副标题 -->
    <!-- 主内容区 -->
  </div>
</div>
```

- **背景层次**：`bg-gradient-to-b from-slate-50 to-white`（微渐变，避免纯白单调）
- **响应式侧边距**：`px-8 sm:px-12 lg:px-16`（32/48/64px 递进，禁止 `px-4` 以下的贴边感）
- **内容最大宽度**：列表页 `max-w-5xl`，表单/详情页 `max-w-3xl`
- **垂直节奏**：页面顶部 `py-16`，内容块间 `space-y-8`

### 页面头部

- **返回导航**：`<Link>` + `<ArrowLeft>` 图标 + `text-blue-700 hover:text-blue-800`
- **页面标题**：`text-3xl font-bold text-slate-900 lg:text-4xl`
- **副标题**（可选）：`mt-3 text-base text-slate-500`
- 标题与内容间距：`mb-10`

### Card 使用规范

- Card 必须**视觉可见**：`shadow-sm border border-slate-200`（不允许无边框无阴影的隐形 Card）
- 内边距：`p-8`（表单/详情场景），`p-5` ~ `p-6`（列表卡片场景）
- 长表单采用**单卡片布局**，不按功能拆分多卡片
- 卡片内各字段组用 `space-y-6` 分隔

### 四态覆盖

页面必须覆盖 4 种状态，不允许空白或浏览器默认样式：

| 状态 | 实现 |
|------|------|
| Loading | shadcn `<Skeleton>` 组合 + Card 骨架屏 |
| Content | 完整内容渲染 |
| Empty | 居中图标 + 引导文案 + CTA 按钮 |
| Error | 错误描述 + 重试操作 |

### 图片占位与兜底

- 所有 `backgroundImage` 容器 SHOULD 设置兜底背景色：`bg-slate-100`（浅色场景）/ `bg-slate-800`（深色场景）
- 无图时使用**渐变占位**：`bg-gradient-to-br from-blue-50 via-slate-50 to-blue-100` + 居中图标
- 不允许图片加载失败后出现白块

### 表单美化

- 使用 shadcn/ui 组件（Input / Select / Button），不使用原生 `<select>` / `<input>`
- 表单标签：`text-sm font-medium text-slate-700`
- 必填标记：`<span className="text-red-500">*</span>`
- 提交按钮：全宽 `w-full` + 品牌色 `bg-blue-700 hover:bg-blue-800 text-white`
- 提交中状态：`<Loader2>` 旋转图标 + disabled

## 工具链

- **CSS 框架**：Tailwind CSS 4（`@import 'tailwindcss'`）
- **组件库**：shadcn/ui（base-nova 主题 / neutral 灰度）
- **图标**：lucide-react（统一来源，不混用其他图标库）
- **动画**：tailwindcss-animate + tw-animate-css

禁止引入：styled-components / emotion / vanilla-extract / MUI / Chakra / Ant Design。

## 字体体系

- **正文**：Inter（`--font-sans` / `font-sans`）
- **标题**：Plus Jakarta Sans（`--font-heading`），h1–h6 自动应用
- 通过 `next/font/google` 加载，CSS 变量注入

## 色彩

- **品牌色**：`--color-brand: #1d4ed8`（等价 `blue-700`）
- **CTA 按钮**：`bg-blue-700 hover:bg-blue-800 text-white`
- **灰度**：oklch 色值 + shadcn neutral 色板
- **Design Tokens**：通过 CSS 变量（`:root` / `.dark`）管理，不硬编码色值

## 间距与容器

- **Section 间距**：`--spacing-section: 96px`（desktop）/ `--spacing-section-mobile: 64px`
  - 已通过 `section[data-region] { padding-block }` 全局应用
- **内容容器**：`mx-auto max-w-6xl px-6`
- 不自定义 section padding，依赖全局 CSS 变量

## 响应式设计

- **Mobile-first**：默认样式面向手机，通过 `md:` / `lg:` 断点增强
- **常用断点**：
  - `md:` (768px) — 平板横屏 / 小桌面
  - `lg:` (1024px) — 标准桌面
- **网格模式**：`grid-cols-1 md:grid-cols-2 lg:grid-cols-4` 渐进增列
- **隐藏/显示**：`hidden md:block` / `md:hidden` 切换布局变体

## 组件样式模式

- **卡片**：`<Card>` + `overflow-hidden transition-shadow hover:shadow-lg`
- **图片容器**：`aspect-[W/H] bg-cover bg-center` + `style={{ backgroundImage }}`
- **文字层级**：
  - 标题：`text-3xl font-bold text-slate-900 lg:text-4xl`
  - 正文：`text-sm text-slate-600` / `text-slate-500`
- **链接按钮**：`font-medium text-blue-700 hover:text-blue-800`

## 暗色模式

- 通过 `class` 策略启用（`darkMode: "class"`）
- 暗色 token 定义在 `.dark {}` 块中
- 当前未全面启用，后续按需扩展
