## Context

Wanderchina 首页由 6 个 Region Slot 组成（HeroSlot / FeatureNavSlot / CityGridSlot / HotPostsSlot / HotSpotsSlot / AiLauncherSlot），遵循 Region-Slot 模式：每个 Slot 组件从配对的 `.data.ts` 读取静态数据，不调用 fetch，不 import `lib/backend`。

当前代码状态（v1）在如下维度存在缺口：
1. 侧边距全部使用 `px-6`，违反 `styling-conventions` 的 `px-8 sm:px-12 lg:px-16` 规约
2. `AiLauncherSlot` 已实现但未在 `page.tsx` 中挂载
3. `CityGridSlot`、`HotSpotsSlot` 缺少 section 背景色（纯白，无层次感）
4. `HeroSlot` 双 CTA 字段（`ctaLabel` / `ctaHref`）已定义在 `hero.data.ts` 但组件未使用
5. `FeatureNavSlot` 仅有 icon + 标签，无副标题，探索感不足
6. `HotPostsSlot` 大卡片图片裸露、小卡片图片容器用固定尺寸

## Goals / Non-Goals

**Goals:**
- 修复所有违反 `styling-conventions` 的侧边距问题
- 恢复 AiLauncherSlot 挂载，确保 AI 入口可见
- 为 CityGridSlot / HotSpotsSlot section 补充背景渐变层次
- 提升 HeroSlot 视觉冲击力（双 CTA + 移动端自适应高度）
- FeatureNavSlot 增加 description 副标题 + hover 品牌色强化
- HotPostsSlot 大卡片增加摄影感渐变 overlay，小卡片改 aspect-ratio 容器
- 确保所有修改的 Slot 测试随同更新，测试全绿

**Non-Goals:**
- 不新增 Region，不删除 Region，不改变 page.tsx 中 Region 排列顺序（仅新增 AiLauncherSlot）
- 不修改 data 文件的既有类型字段（仅新增 `description` 字段到 `featureNav.data.ts`）
- 不修改 shadcn/ui 组件源码
- 不引入任何新 npm 依赖
- 不涉及后端 API 改动
- 不做首页数据动态化（仍用静态 data 文件）

## Decisions

### D1：侧边距修复策略 — 逐文件修改 vs CSS 全局覆盖

**决定**：逐文件修改每个 Slot 的 `px-6` 为 `px-8 sm:px-12 lg:px-16`。

**理由**：全局 CSS 覆盖（如 `.mx-auto.max-w-*` 的通用 padding）会影响非首页区域的同名容器，风险高。逐文件修改更精确，符合 YAGNI 原则。

**排除方案**：在 `globals.css` 中为 `section[data-region] > div` 添加全局 padding 规则 —— 会打破现有测试中对 className 的精确匹配。

---

### D2：FeatureNavSlot description 字段 — data 层新增 vs 组件 hardcode

**决定**：在 `featureNav.data.ts` 的 `FeatureNavItem` 类型中新增 `description: string` 字段，并为 4 个 item 各填写一句描述。

**理由**：Region-Slot 模式要求组件不 hardcode 内容，所有展示内容来自 `.data.ts`。新增字段不破坏现有类型使用（无调用方依赖此类型的外部代码）。

---

### D3：CityGridSlot bestSeason Badge 位置 — 移至图片 overlay vs 保留文字区

**决定**：将 `bestSeason` Badge 从文字区（与城市名同行）移至图片右上角 overlay（绝对定位）。

**理由**：视觉层次更清晰，城市名行不再有竞争元素；图片 overlay Badge 是国际旅游站（Visit Japan）的常见模式，强化探索感。Badge 使用 `absolute top-3 right-3 bg-white/90 text-slate-700`，确保对比度 ≥ 4.5:1。

---

### D4：HotPostsSlot 大卡片 — 图片内文字 vs 图片下文字

**决定**：保留图片下文字区域（`p-6`），但在图片底部增加一层浅渐变 overlay（`bg-gradient-to-b from-transparent to-black/40`）强化摄影感，文字仍在 Card 白色区域内。

**理由**：图片内文字层（完全覆盖）需要确保所有 picsum 随机图片都有足够对比度，不可控。保留文字在白色区的可读性底线，仅用渐变增强图片质感，风险低。

---

### D5：HotSpotsSlot 标题文案

**决定**：标题从 `"Off-the-Beaten-Path Spots"` 改为 `"Hidden Gems"`。

**理由**：原标题 15 字，在移动端换行；"Hidden Gems" 6 字，简洁，国际通用旅游用语，且已有对应 Feature Nav 的"Hidden Spots"概念呼应，一致性更高。

---

### D6：Hero 双 CTA 布局

**决定**：搜索框 + 搜索按钮保持在一行，下方新增一个独立的 `<a>` 按钮 "Start Exploring"（`bg-blue-700 hover:bg-blue-800 text-white`），两者间距 `mt-4`。

**理由**：`hero.data.ts` 已预留 `ctaLabel` / `ctaHref` 字段（注释说明"Reserved for future CTA button"），直接启用，无需修改类型定义。

## Risks / Trade-offs

- **[测试脆弱性]** 修改 Slot 组件的 className 后，现有测试若有 className 精确匹配会失败 → 需逐一检查测试文件，仅更新必要的断言，不过度约束样式实现细节
- **[图片 overlay 对比度]** picsum 随机图片颜色不可控，overlay Badge 在纯白图片上可能对比度不足 → Badge 使用 `bg-white/90 text-slate-700`，背景始终是白色系，对比度可保障
- **[featureNav.data.ts 类型新增]** 若其他代码或测试依赖 `FeatureNavItem` 类型，新增字段可能需要补充测试 mock → 检查 `FeatureNavSlot.test.tsx` 是否 import data 文件，如有则同步更新 mock 数据

## Migration Plan

纯前端静态改动，无数据库迁移，无 API 版本变更。

部署步骤：
1. 测试全绿（`npm test` 在 `frontend/` 通过）
2. 前端构建验证（`npm run build` 无报错）
3. Vercel 自动部署（push 到 main 分支触发）
4. Rollback：git revert 本次 commit 即可恢复 v1

## Open Questions

- 无阻塞性开放问题。`hero.data.ts` 的 `ctaHref` 当前为 `"#"`，后续可链接到城市列表页（`/spots` 或 `/regions`），但不在本 change 范围内。
