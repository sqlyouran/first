# Design: 首页视觉层 v1（homepage-visual-v1）

## Context

- **产品定位**：Wanderchina 是面向境外用户的入境中国旅游目的地探索平台（详见 `openspec/project.md`）
- **设计参照系**：Visit Japan / Tourism New Zealand / Discover Vietnam 等国际目的地营销站
- **现状**：首页 6 个 region 结构契约 + 内容注入已落地（7 个 capability spec 全部 archive），但页面仍为裸骨架
- **样式栈**：Tailwind 4 + shadcn/ui (new-york/slate) + lucide-react（由 `frontend-styling-stack` 提供）
- **BFF 边界**：本变更不允许引入 Route Handler / Server Action，不动 `lib/backend.ts`

## Goals

1. 一次性完成 6 个 region 的视觉契约升级（布局/配色/响应式），让首页具备"能给人看"的产品形态
2. 所有视觉决策集中到 1 个 change，避免 6 个 region 各自 propose 导致的视觉割裂
3. Mock 数据扩充到合理量级（城市 8 / 攻略 6 / 景点 8），支撑视觉展示
4. AI Launcher 从占位按钮升级为可交互入口（Dialog / Sheet 双形态）
5. 同步治理文档（README / 7 份 MODIFIED spec），避免 spec drift

## Non-Goals

- 真实数据接入（后端 API）
- 暗色模式切换 UI（next-themes 集成）
- 真实图片素材（unsplash 或自研）
- 微交互 / 动效（fade / slide / scroll reveal）
- SEO meta / OG 图 / 性能预算
- 移动端 App / CMS 后台 / OTA 交易

---

## Decisions

### D1: 主色系选择

**决策**：采用 **靛青主色**（Tailwind `blue-700` / `#1d4ed8`）+ slate 灰阶。

**Rationale**：
- 靛青是国际目的地营销站的常见主色（Visit Japan 用红+白，但 Tourism New Zealand 用蓝绿系），传递"可信赖 + 探索感"
- 靛青与后续可能的品牌色（蓝绿系）更易调和，不会冲突
- slate 灰阶作为辅助色，提供层次感而不喧宾夺主
- shadcn/ui 默认 `slate` baseColor 已预装，零成本扩展

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| 山水墨色（`slate-700` / `#334155`） | 过于克制，缺乏"探索感"；与灰阶辅助色区分度低 |
| 暖橙（`orange-600` / `#ea580c`） | 传递"促销 / 紧迫感"，与目的地营销的"慢旅行"调性冲突 |
| 蓝绿系（`cyan-600` / `#0891b2`） | 备选方案，若靛青在视觉测试中显得"过冷"可切换 |

**回滚路径**：若靛青在实际页面中显得"过冷"或"不够旅行感"，可在 `app/globals.css` 的 `:root` CSS 变量中切换为蓝绿系，业务组件 class 无需改动。

---

### D2: Hero 背景形态

**决策**：采用 **静态图 + 渐变叠层**（picsum.photos 占位，后续切真实图）。

**Rationale**：
- 静态图性能最优（无轮播 JS 开销、无视频解码负担）
- 渐变叠层（`bg-gradient-to-r from-black/60 to-transparent`）保证文字可读性，不依赖图片明暗
- 占位期用 picsum.photos（如 `https://picsum.photos/1920/1080?random=1`），后续切真实图只需改 URL，不改组件结构
- YAGNI：轮播 / 视频是"酷炫加分项"，但增加复杂度（轮播需状态管理、视频需 CDN + 压缩），留给后续独立 change

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| 轮播（3 张图自动切换） | 增加状态管理（currentSlide / timer），YAGNI；轮播 UX 争议大（用户可能错过内容） |
| 视频背景 | 视频文件大（>5MB），拖慢首屏加载；需要 CDN + 压缩流水线；移动端浏览器限制 autoplay |
| 纯渐变（无图） | 视觉单薄，不符合"目的地营销站"调性；无法传递"中国风景"的第一印象 |

**回滚路径**：若静态图在实际页面中显得"过平"，可在后续 change `homepage-animations` 中加入 fade-in 动效（opacity 从 0 → 1，时长 1s），不改组件结构。

---

### D3: 图片来源

**决策**：采用 **picsum.photos** 占位，后续切真实图。

**Rationale**：
- picsum.photos 是免费随机图片服务，URL 简单（`https://picsum.photos/800/600?random=1`），零配置
- 图片质量稳定（来自 unsplash 子集），不会返回低质量 / 版权争议图片
- 占位期无需关心"图片内容是否匹配城市"，后续切真实图时只需改 data.ts 中的 URL 字段
- 不引入新 npm 依赖（直接 `<img src="https://picsum.photos/..." />`）

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| unsplash.com 直链 | 需要 API key（免费但有 rate limit），URL 较长（含 photo ID + 参数）；占位期无需真实城市图 |
| 内置 SVG 占位图 | 需要自己画 / 下载 SVG，工作量大；SVG 无法传递"风景摄影"的视觉冲击 |
| 真实图片（立即采购 / 拍摄） | 超出本变更范围（真实图片需要版权 / CDN / CMS 配套），留给后续独立 change |

**回滚路径**：若 picsum.photos 在某些地区被墙（如中国大陆），可在 `next.config.ts` 中配置 `images.remotePatterns` 切换到备用服务（如 `https://loremflickr.com/`），不改组件结构。

---

### D4: Mock 数据量

**决策**：扩充到 **城市 8 / 攻略 6 / 景点 8**。

**Rationale**：
- 城市 8：北京 / 上海 / 成都 / 西安 / 杭州 / 桂林 / 丽江 / 厦门，覆盖中国主要旅游城市类型（古都 / 现代 / 自然 / 海滨）
- 攻略 6：足够支撑"左大右小 storytelling 布局"（1 篇精选大图 + 2 篇小卡片 × 2 行）
- 景点 8：足够支撑横向 carousel（desktop 可见 4 张，滚动 1 页）
- 所有 mock 数据硬编码在 `*.data.ts` 文件中，后续切真实 API 只需改 data source，不改组件

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| 最少化（各 1 项） | 当前状态，无法支撑视觉展示（1 张卡片看不出 grid 效果） |
| 最大化（各 20+ 项） | 超出"能给人看"的需求，增加 data.ts 维护成本；后续切真实 API 时这些数据会废弃 |

**回滚路径**：无需回滚，mock 数据量不影响组件结构。

---

### D5: 响应式断点

**决策**：采用 **3 断点**（mobile < 768 / tablet 768-1023 / desktop ≥ 1024）。

**Rationale**：
- 3 断点是业界主流（Bootstrap 5 / Tailwind 默认 / shadcn/ui 均使用此分段）
- mobile / tablet / desktop 的布局差异明确：
  - mobile：单列、横向滚动、Sheet（底部弹出）
  - tablet：2 列 grid、Dialog（居中弹出）
  - desktop：4 列 grid、Dialog（居中弹出）
- Tailwind 默认断点（`sm:640` / `md:768` / `lg:1024` / `xl:1280` / `2xl:1536`）中，只用 `md` 和 `lg` 即可覆盖需求

**Alternatives considered**：

| 方案 | 否决理由 |
|---|---|
| 2 断点（mobile / desktop） | 平板用户（iPad）体验差，768-1024 区间的布局尴尬 |
| 4+ 断点（含 xl / 2xl） | 过度设计，1280+ 的布局与 1024 差异不大，YAGNI |

**回滚路径**：若 3 断点在实际测试中某区间布局尴尬，可在 `tailwind.config.ts` 中追加自定义断点（如 `tablet: 900px`），不改组件结构。

---

## Architecture

### 视觉契约分层

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: 页面级视觉契约（homepage-shell spec）             │
│  ├─ 字体 stack：Inter / Plus Jakarta Sans / system-ui       │
│  ├─ 主色：靛青（blue-700）                                  │
│  ├─ 辅助色：slate 灰阶                                      │
│  ├─ 大留白：section 间距 96px (desktop) / 64px (mobile)     │
│  └─ 响应式 3 断点：mobile < 768 / tablet 768-1023 / desktop│
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Region 级视觉契约（6 份 capability spec）         │
│  ├─ hero：全幅摄影 + 渐变叠层 + 大标题 + 搜索框             │
│  ├─ feature-nav：横向 4 chip + lucide 图标                  │
│  ├─ city-grid：4 列卡片 + 季节 tag                          │
│  ├─ hot-posts：左大右小 storytelling                          │
│  ├─ hot-spots：横向 carousel + 标签                         │
│  └─ ai-launcher：浮按钮 + Dialog / Sheet 双形态             │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: 组件级实现（6 个 Slot.tsx + shadcn 组件）         │
│  ├─ HeroSlot.tsx：全幅 section + h1 + Input + Button        │
│  ├─ FeatureNavSlot.tsx：4 × Card + lucide icon              │
│  ├─ CityGridSlot.tsx：8 × Card + Badge                      │
│  ├─ HotPostsSlot.tsx：1 × Card (大) + 2 × Card (小)        │
│  ├─ HotSpotsSlot.tsx：Carousel + Card + Badge               │
│  └─ AiLauncherSlot.tsx：Button + Dialog + Sheet             │
└─────────────────────────────────────────────────────────────┘
```

### shadcn 组件按需追加

| 组件 | 用途 | 安装命令 |
|---|---|---|
| `dialog` | AI Launcher desktop 形态 | `npx shadcn@latest add dialog` |
| `sheet` | AI Launcher mobile 形态 | `npx shadcn@latest add sheet` |
| `carousel` | hot-spots 横向滚动 | `npx shadcn@latest add carousel` |
| `badge` | city-grid 季节 tag / hot-spots 标签 | `npx shadcn@latest add badge` |

> 已装组件：`button` / `card` / `input`（由 `frontend-styling-stack` 提供）

### 字体引入

```tsx
// app/layout.tsx
import { Inter, Plus_Jakarta_Sans } from 'next/font/google';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' });
const plusJakarta = Plus_Jakarta_Sans({ subsets: ['latin'], variable: '--font-plus-jakarta' });

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${inter.variable} ${plusJakarta.variable}`}>
      <body>{children}</body>
    </html>
  );
}
```

```css
/* app/globals.css */
:root {
  --font-sans: var(--font-inter), system-ui, sans-serif;
  --font-display: var(--font-plus-jakarta), var(--font-inter), system-ui, sans-serif;
}

body {
  font-family: var(--font-sans);
}

h1, h2, h3 {
  font-family: var(--font-display);
  font-weight: 700;
}
```

---

## Risks & Mitigations

### R1: 视觉契约与现有测试冲突

**风险**：现有 6 份 capability spec 均写"无 className"，单测断言 `container has no className`。本变更加 className 会导致所有 Slot 测试 RED。

**Mitigation**：
- 每个 Slot 的 TDD 循环中，先改 spec（MODIFIED delta），再改测试（追加 className 断言），最后改组件
- RED 演练：临时改回"无 className"验证测试有效，再恢复
- 预期：6 个 Slot 各 1 次 RED + 1 次 GREEN，共 12 次提交

### R2: shadcn 组件安装冲突

**风险**：4 个新组件（dialog / sheet / carousel / badge）各自 `npx shadcn add` 可能冲突（package.json / components.json）。

**Mitigation**：
- 按依赖顺序安装：dialog → sheet → carousel → badge（dialog / sheet 共享 Radix 底层）
- 每次安装后立即 `git add + commit`，避免 untracked 文件累积
- 若冲突，手动 merge `components.json` 的 `$schema` 字段

### R3: picsum.photos 在某些地区被墙

**风险**：中国大陆用户访问首页时图片加载失败。

**Mitigation**：
- 占位期不关心（目标用户在境外，不在中国大陆）
- 后续切真实图时配置 `next.config.ts` 的 `images.remotePatterns`，使用 CDN（如 Cloudflare / Vercel Image Optimization）

### R4: Mock 数据量增加导致 data.ts 文件过大

**风险**：8 城市 / 6 攻略 / 8 景点的 data.ts 文件可能超过 100 行，难以维护。

**Mitigation**：
- 每个 data.ts 文件控制在 150 行以内（8 项 × 15 行/项 = 120 行）
- 使用 TypeScript 类型约束（如 `CityCard` / `Story` / `HiddenSpot`），避免字段漂移
- 后续切真实 API 时，data.ts 整体废弃，不影响组件

### R5: AI Launcher Dialog / Sheet 双形态的响应式切换

**风险**：Dialog（desktop）和 Sheet（mobile）的切换逻辑复杂（需监听窗口尺寸 + 状态管理）。

**Mitigation**：
- 使用 Tailwind 的 `md:hidden` / `hidden md:block` 控制显隐，不引入 React state
- Dialog 和 Sheet 各自独立渲染，通过 CSS 媒体查询切换
- 若实际测试中发现切换卡顿，可改用 `useMediaQuery` hook（来自 `usehooks-ts`），但需评估是否引入新依赖

---

## Success Criteria

1. 首页 6 个 region 全部具备视觉契约（className / 布局 / 配色 / 响应式）
2. Mock 数据扩充到 8 城市 / 6 攻略 / 8 景点
3. AI Launcher 点击可打开 Dialog（desktop）或 Sheet（mobile）
4. 所有测试 GREEN（含视觉契约断言）
5. `npm run build` 通过，无 TypeScript / ESLint 错误
6. 页面在 3 断点（mobile / tablet / desktop）下布局正确
7. 7 份 MODIFIED spec 同步更新，archive 后主 spec 一致
