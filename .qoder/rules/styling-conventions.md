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
