# homepage-feature-nav Spec

> 路径：`openspec/specs/homepage/homepage-feature-nav.md`
> 承接挂载位：`homepage-shell` 在 `app/page.tsx` 第 2 个 region 提供的 `data-region="feature-nav"` 槽位
> 实现位置：`frontend/app/regions/FeatureNavSlot.tsx`

## 0. 前置依赖

依赖 `frontend-styling-stack`（待 propose）引入 Tailwind + shadcn/ui，以使用 shadcn `<Card />` 组件构建卡片。

---

## 1. 模块边界

### 1.1 In Scope

- 渲染恰好 **3 张平台入口卡片**：旅游社区 / 景点攻略 / AI 助手
- 每张卡片包含：**图标**（lucide-react，shadcn 默认图标库）+ **标题** + **一句话描述** + **跳转链接**
- 响应式：`< 768px` 单列纵向堆叠 / `≥ 768px` 三列横向并排 / `≥ 1024px` 间距加大
- 卡片可键盘聚焦，整卡可点击（`<a>` 包裹整张 Card）
- a11y：每张 Card 有 `aria-label`，图标 `aria-hidden`

### 1.2 Out of Scope

- 卡片跳转目标页面本身（社区列表 / 景点攻略列表 / AI 对话页路由属其它 spec）
- 卡片悬停动画 / 视差效果
- A/B 测试 / 行为埋点
- 用户自定义卡片排序
- 多于 3 张或少于 3 张的可变数量

---

## 2. 核心场景

### Scenario 1：桌面端三列横排（happy path）

- **WHEN** 视口 `≥ 1024px` 加载首页
- **THEN** `data-region="feature-nav"` 区域内含 3 个 `<a>` 包裹的 `<Card>`
- **AND** 三张卡片在主轴上等宽并排（`grid grid-cols-3 gap-8`）
- **AND** 卡片顺序依次为：旅游社区 → 景点攻略 → AI 助手

### Scenario 2：移动端单列纵排

- **WHEN** 视口 `< 768px`
- **THEN** 三张卡片纵向堆叠（`grid-cols-1`）
- **AND** 每张卡片宽度 100%
- **AND** 卡片间距 `gap-4`

### Scenario 3：链接 href 正确

- **WHEN** 渲染完成
- **THEN** 旅游社区卡片的 `<a href>` 等于 `/community`
- **AND** 景点攻略卡片的 `<a href>` 等于 `/spots`
- **AND** AI 助手卡片的 `<a href>` 等于 `#ai-launcher`（锚点，触发常驻悬浮按钮的展开由 `homepage-ai-launcher` 单元处理）

### Scenario 4：键盘可达

- **WHEN** 用户连续按 `Tab`
- **THEN** 焦点依次落到 3 张卡片的 `<a>` 上
- **AND** 每个 `<a>` 出现可见 focus ring（`focus-visible:ring-2`）
- **AND** 按 `Enter` 触发导航

### Scenario 5：SSR 真实存在

- **WHEN** `curl http://localhost:<port>/`
- **THEN** 响应 HTML 直接包含 3 张卡片的标题文本与描述文本（非 hydrate 后才出现）

### Scenario 6：图标不被屏幕阅读器朗读（异常路径——a11y 守护）

- **WHEN** 屏幕阅读器读取卡片
- **THEN** 仅朗读卡片的 `aria-label`（如"进入旅游社区"）+ 标题 + 描述
- **AND** **不**朗读 lucide 图标（图标的 `<svg>` 必须有 `aria-hidden="true"`）

### Scenario 7：常量数据缺失（异常路径——构建期防护）

- **GIVEN** 卡片配置常量数组长度不等于 `3`
- **WHEN** 构建期 TypeScript 检查
- **THEN** 类型 `readonly [FeatureNavCard, FeatureNavCard, FeatureNavCard]` 强制 tuple 长度
- **AND** 编译失败而非运行期才暴露

---

## 3. 数据结构

### 3.1 类型定义

```ts
// frontend/app/regions/feature-nav.constants.ts
import { type LucideIcon } from 'lucide-react';

export type FeatureNavCard = {
  /** 卡片唯一 key，用于 React list key 与测试定位 */
  key: 'community' | 'spots' | 'ai-assistant';
  /** lucide-react 图标组件 */
  icon: LucideIcon;
  /** 卡片标题，CJK 2-8 字 */
  title: string;
  /** 一句话描述，CJK ≤ 30 字 / 拉丁 ≤ 80 字符 */
  description: string;
  /** 跳转 href；AI 助手用锚点 `#ai-launcher` */
  href: string;
  /** 整卡 aria-label，无障碍朗读用 */
  ariaLabel: string;
};

/** 三张卡片，tuple 强约束长度为 3 */
export type FeatureNavConfig = readonly [FeatureNavCard, FeatureNavCard, FeatureNavCard];
```

### 3.2 默认常量

```ts
import { Users, MapPin, Sparkles } from 'lucide-react';

export const FEATURE_NAV: FeatureNavConfig = [
  {
    key: 'community',
    icon: Users,
    title: '旅游社区',
    description: '看真实玩家的攻略与避坑指南',
    href: '/community',
    ariaLabel: '进入旅游社区',
  },
  {
    key: 'spots',
    icon: MapPin,
    title: '景点攻略',
    description: '按城市与主题精选必去景点',
    href: '/spots',
    ariaLabel: '查看景点攻略',
  },
  {
    key: 'ai-assistant',
    icon: Sparkles,
    title: 'AI 助手',
    description: '随时随地解答你的旅行问题',
    href: '#ai-launcher',
    ariaLabel: '唤起 AI 助手',
  },
] as const;
```

### 3.3 组件 Props

```ts
// frontend/app/regions/FeatureNavSlot.tsx
export type FeatureNavSlotProps = {
  /** 可选注入用于测试；默认使用 FEATURE_NAV 常量 */
  cards?: FeatureNavConfig;
};
```

### 3.4 约束摘要

| 字段 | 类型 | 必填 | 长度 | 备注 |
|---|---|---|---|---|
| `key` | 字面量联合 | 是 | — | 三选一，唯一 |
| `icon` | `LucideIcon` | 是 | — | 必须来自 lucide-react |
| `title` | `string` | 是 | 2–8（CJK） | 单行 |
| `description` | `string` | 是 | ≤ 30（CJK） / ≤ 80（拉丁） | 单行不换行 |
| `href` | `string` | 是 | — | `/community`、`/spots`、`#ai-launcher` 三选一 |
| `ariaLabel` | `string` | 是 | ≤ 30 | 描述性动词起首 |

### 3.5 数据来源

- **静态常量**：`feature-nav.constants.ts` 编译期定值
- **不接 API**、**不引入 mock**、**不依赖 BFF**

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 结构

- [ ] `FeatureNavSlot.tsx` 是 Server Component，根节点 `<section data-region="feature-nav" aria-label="feature-nav">`
- [ ] section 内含 3 个 `<a>` 包裹的 shadcn `<Card>`
- [ ] 卡片顺序与 `FEATURE_NAV` 数组顺序严格一致

### 4.2 视觉与响应式

- [ ] 容器 Tailwind class：`grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6 lg:gap-8`
- [ ] 卡片标题字号 `text-lg md:text-xl`
- [ ] 描述字号 `text-sm md:text-base`，颜色 `text-muted-foreground`
- [ ] 图标尺寸 `h-8 w-8 md:h-10 md:w-10`，`aria-hidden="true"`
- [ ] hover 态有 shadow 提升（`hover:shadow-md`），无 transform 动画

### 4.3 链接与交互

- [ ] 整张 Card 由单个 `<a>` 包裹，`<a>` 上设置 `aria-label`
- [ ] 三个 href 分别为 `/community` / `/spots` / `#ai-launcher`
- [ ] AI 卡片点击仅滚动到锚点 / 触发 launcher，不发起网络请求

### 4.4 无障碍

- [ ] 每个 lucide 图标 svg 有 `aria-hidden="true"`
- [ ] Tab 顺序与 DOM 顺序一致
- [ ] focus-visible ring 可见
- [ ] 颜色对比度 WCAG AA 通过

### 4.5 测试（TDD）

- [ ] `FeatureNavSlot.test.tsx` 新增：
  - [ ] RED → GREEN：渲染恰好 3 张 Card
  - [ ] 用例：三个 href 与常量一致
  - [ ] 用例：传入自定义 `cards` props 时覆盖默认渲染
  - [ ] 用例：图标 svg 含 `aria-hidden="true"`
- [ ] `app/page.test.tsx` 仍 GREEN

### 4.6 端到端

- [ ] `npm run build` 通过
- [ ] `npm test` 全绿
- [ ] `curl /` HTML 包含三张卡片的标题与描述文本
- [ ] Lighthouse a11y 分数 ≥ 95

### 4.7 边界守护

- [ ] 未新增 `route.ts` / `route.tsx`
- [ ] `backend/` submodule 指针未变
- [ ] 未引入除 lucide-react 外的新 npm 依赖（lucide-react 由 `frontend-styling-stack` 引入）

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `data-region="feature-nav"` 挂载位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | Tailwind + shadcn/ui + lucide-react |
| **行为关联但不强依赖** | `homepage-ai-launcher` | AI 卡片 href 为锚点 `#ai-launcher`；本单元仅提供链接，launcher 唤起逻辑由对方实现 |
| **与本单元正交** | `homepage-hero` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` | 各自独立 Slot |
| **本单元不依赖** | 任何后端 API、任何 mock | 全静态 |
