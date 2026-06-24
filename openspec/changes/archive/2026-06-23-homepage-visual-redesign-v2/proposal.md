## Why

当前首页各 Region Slot 在视觉完成度上存在多项规约违反（侧边距错误、背景层次缺失、AI 入口未挂载），整体调性与产品愿景（对标 Visit Japan / Tourism New Zealand 的"大留白、全幅摄影、克制配色、探索感"）仍有明显差距。需通过系统性视觉提升，使首页真正达到国际目的地营销站水准。

## What Changes

- **修复全局侧边距**：所有 Region 内容容器从 `px-6` 改为 `px-8 sm:px-12 lg:px-16`，对齐 `styling-conventions` 规约
- **挂载 AiLauncherSlot**：在 `app/page.tsx` 中补充导入和使用 `AiLauncherSlot`，恢复跨页面 AI 入口功能
- **HeroSlot 品牌感提升**：增加双 CTA（搜索框 + "Start Exploring" 品牌按钮），补充 `text-white/70` 渐变副标题层次，移动端高度改为 `min-h-[520px] h-[70vh]` 自适应
- **FeatureNavSlot 探索感强化**：每个 Feature 卡片增加副标题描述文字（来自 data 文件），hover 状态增加品牌色左边框（`border-l-4 border-l-blue-700`）
- **CityGridSlot 背景层次补充**：section 加 `bg-gradient-to-b from-slate-50 to-white`；城市图片上增加 `bestSeason` overlay Badge，从文字区移出
- **HotPostsSlot 摄影感提升**：大卡片图片区加 `bg-gradient-to-b from-transparent to-black/50` 渐变 overlay，标题/位置信息浮于图片上；小卡片图片容器改为 `aspect-square` 控制比例
- **HotSpotsSlot 标题优化**：区块标题从"Off-the-Beaten-Path Spots"更新为"Hidden Gems"，更简洁有探索感

## Capabilities

### New Capabilities
- `homepage-visual-v2`: 首页视觉提升第二版，系统性修复规约违反并强化各 Region Slot 的视觉调性与品牌一致性

### Modified Capabilities
- `homepage-shell`: `page.tsx` 新增 AiLauncherSlot 挂载（现有行为变更：AI 入口从缺失到存在）

## Impact

**前端文件**：
- `frontend/app/page.tsx` — 新增 AiLauncherSlot 导入与使用
- `frontend/app/regions/HeroSlot.tsx` — 双 CTA、自适应高度
- `frontend/app/regions/featureNav.data.ts` — 新增 `description` 字段
- `frontend/app/regions/FeatureNavSlot.tsx` — 副标题、hover 左边框
- `frontend/app/regions/CityGridSlot.tsx` — 背景渐变、图片 overlay Badge
- `frontend/app/regions/HotPostsSlot.tsx` — 大卡片图片 overlay、小卡片 aspect-ratio
- `frontend/app/regions/HotSpotsSlot.tsx` — 标题文案更新、背景声明

**测试文件**（同步更新）：
- `frontend/app/regions/HeroSlot.test.tsx`
- `frontend/app/regions/FeatureNavSlot.test.tsx`
- `frontend/app/regions/CityGridSlot.test.tsx`
- `frontend/app/regions/HotPostsSlot.test.tsx`
- `frontend/app/regions/HotSpotsSlot.test.tsx`

**无 API / 依赖变更**，无 Breaking Change。
