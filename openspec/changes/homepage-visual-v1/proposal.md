# Proposal: 首页视觉层 v1（homepage-visual-v1）

## Why

首页骨架阶段 6 个 region 的结构契约与内容注入已全部落地并归档（homepage-shell / hero / feature-nav / city-grid / hot-posts / hot-spots / ai-launcher），但页面仍呈现"灰底黑字"的裸骨架状态。当前状态无法满足产品定位——**让境外旅行者发现旅行指南之外的中国**。

境外目的地营销网站（Visit Japan / Tourism New Zealand / Discover Vietnam）的视觉语言有一套清晰共识：大留白、全幅摄影、克制配色、Inter/Plus Jakarta Sans 字体、响应式 3 断点。本变更一次性把 6 个 region 的视觉契约升级到这个水平，让首页具备"能给人看"的产品形态。

**触发条件**：
- `openspec/project.md` 已于 commit 23977e8 填写 Wanderchina 产品愿景/范围/非目标/术语
- 6 个 capability spec 当前均写"无 className"，需要统一 MODIFIED 加视觉契约
- 前置依赖（样式栈 / 骨架 / 内容注入）全部 archive

## What Changes

### 一次性 MODIFIED 7 份 capability spec

1. **homepage-shell/spec.md**（MODIFIED）
   - 新增 "页面级视觉契约" Requirement：大留白 / Inter 字体 / 靛青主色 / 响应式 3 断点
   - 所有 region 共享此视觉契约，各 region spec 不再重复

2. **homepage-hero/spec.md**（MODIFIED）
   - 全幅风景摄影（picsum.photos 占位）+ 渐变叠层
   - 大标题（Inter / 48px+）+ 副标题 + 大搜索框（装饰 input）
   - 响应式：mobile 全幅 / desktop 居左 60%

3. **homepage-feature-nav/spec.md**（MODIFIED）
   - 横向 4 chip：Cities / Stories / Hidden Spots / Plan with AI
   - lucide-react 图标 + 英文标签
   - 响应式：mobile 横向滚动 / desktop 等宽 4 列

4. **homepage-city-grid/spec.md**（MODIFIED）
   - 大图卡片 4 列（desktop）/ 2 列（mobile）
   - 英文城市名优先 + 中文地名副标
   - 卡片含 picsum.photos 封面 + 城市名 + 简要描述 + 最佳季节 tag
   - Mock 数据扩充到 8 个城市

5. **homepage-hot-posts/spec.md**（MODIFIED）
   - 左大右小 storytelling 布局（1 篇精选大图 + 2 篇小卡片）
   - 英文标题 storytelling 调性（如 "3-Day Yunnan Hidden Tea Trail"）
   - Mock 数据扩充到 6 篇攻略

6. **homepage-hot-spots/spec.md**（MODIFIED）
   - 横向 carousel + "Off-the-Beaten-Path" 调性
   - 小卡片含 picsum.photos + 景点名 + 标签
   - Mock 数据扩充到 8 个景点

7. **homepage-ai-launcher/spec.md**（MODIFIED）
   - 右下浮按钮 "Plan with AI"
   - 点击打开 Dialog（desktop ≥ 1024px）或 Sheet（mobile < 1024px）
   - Dialog / Sheet 内含占位文本 "AI Trip Planner coming soon"

### 前端代码改动

- **新增 shadcn 组件**（按需 `npx shadcn@latest add`）：
  - `dialog`（AI Launcher desktop 形态）
  - `sheet`（AI Launcher mobile 形态）
  - `carousel`（hot-spots 横向滚动）
  - `input`（hero 搜索框，已装但需强化样式）
  - `badge`（city-grid 季节 tag / hot-spots 标签）
- **新增字体**：`next/font/google` 引入 Inter + Plus Jakarta Sans
- **Mock 数据扩充**：
  - `cityGrid.data.ts`：8 个城市（北京 / 上海 / 成都 / 西安 / 杭州 / 桂林 / 丽江 / 厦门）
  - `hotPosts.data.ts`：6 篇攻略（英文标题 + 中文地名副标）
  - `hotSpots.data.ts`：8 个景点（英文名 + 中文地名副标）
- **全局样式强化**：`app/globals.css` 追加页面级视觉契约（大留白 / 靛青主色 / 字体 stack）
- **6 个 Slot 组件改写**：每个 Slot 加 Tailwind class + shadcn 组件 + lucide 图标
- **单测升级**：每个 Slot 的 `.test.tsx` 追加视觉契约断言（className 含期望 class / shadcn 组件可渲染）

### 治理文档

- `frontend/README.md`：在《首页骨架》小节标注"视觉层 v1 已注入"

## Out of Scope

- **真实数据接入**：后端 API（城市 / 攻略 / 景点的 CRUD）留给后续独立 change
- **暗色模式切换 UI**：`next-themes` 集成留给独立 change `dark-mode-support`（CSS 变量段已预留 `.dark`）
- **真实图片素材**：unsplash 或自研图片留给后续，本变更用 picsum.photos 占位
- **微交互 / 动效**：fade / slide / scroll reveal 留给后续独立 change `homepage-animations`
- **SEO meta / OG 图 / 性能预算**：留给后续独立 change
- **移动端 App**：仅提供响应式 Web 端
- **CMS 后台**：本期内容以硬编码 TS 常量为主
- **OTA 交易**：不做预订 / 支付（产品非目标）

## Open Questions

1. **配色微调**：靛青主色（如 `#1e40af`）vs 山水墨色（如 `#334155`）vs 蓝绿系（如 `#0891b2`）。design.md 会给出 3 个方案 + rationale，由用户在签字阶段拍板。
2. **Hero 文案**：默认 "Wander Beyond the Postcard." + "Discover the China that travel guides miss."，用户可改。
3. **AI Launcher 形态**：默认 Dialog（desktop）/ Sheet（mobile），是否需要额外触发方式（如键盘快捷键 / 右下角 icon）？

## 前置依赖

**强依赖**：本变更必须在以下 change 全部 archive 之后才进入 apply 阶段：
- `homepage-shell`（已 archive，commit c41f2d8）
- `homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher`（全部 archive）
- `frontend-styling-stack`（已 archive）

**弱依赖**：`openspec/project.md` 已填写（commit 23977e8），本变更的视觉契约可引用产品愿景作为锚点。

## 工作量估算

- **propose 阶段**：~2 小时（3 件套 + 7 份 MODIFIED spec）
- **apply 阶段**：~3-4 天（6 个 region 各一个 TDD 循环 + shadcn 组件安装 + mock 数据扩充）
- **archive 阶段**：~1 小时（git mv + 主 spec sync + main fast-forward）
