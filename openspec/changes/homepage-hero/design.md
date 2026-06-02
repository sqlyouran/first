## Context

本变更是"区块内容注入"工作流的第二个目标（继 `homepage-feature-nav` 之后）。scope 与 feature-nav 同级最小，复用相同模式但子节点类型不同：feature-nav 是 `<a>` 链接列表，hero 是单个 `<h1>` 标题 + 单个 `<button>` CTA。

业务文案、视觉设计、CTA 真实跳转、背景图均不在本变更范围。本变更只验证"hero region 从空到含可见首屏文字与按钮"这条最小路径。

## Goals / Non-Goals

**Goals:**
- 用最少的代码（≤ 30 行 component + ≤ 10 行 data）让 hero region 从空变为含 1 个 `<h1>` + 1 个 `<button>` 的最小首屏
- 数据来源：硬编码 TS 常量单对象 `{ title, ctaLabel, ctaHref }`；不引入任何依赖、不动 `lib/backend`
- 测试覆盖：HeroSlot 渲染出 `<h1>`、`<button>`、CTA 占位 href 严格 `#`、不引入 fetch / lib/backend
- BFF 边界守护：仍无 `app/api/**/route.ts`、`lib/backend.ts` 与 `package.json` 字节级不变

**Non-Goals:**
- 真实文案 / 视觉设计 / 背景图 / 响应式
- CTA 真实跳转目标（如 `/search`）
- 接入后端或本地 JSON 数据源
- 多语言、A/B、SEO meta 调整

## Decisions

### D1: 数据形态 = 单对象，不是数组

hero 是首屏唯一焦点，按业务直觉是「单条核心信息」而非「列表」。用单对象 `{ title, ctaLabel, ctaHref }` 比 `HeroContent[]` 更贴合语义、用例更清晰。

### D2: 字段最简 — title + ctaLabel + ctaHref

只保留 3 个字段：标题文本、CTA 按钮文本、CTA 占位链接。不预留 subtitle、backgroundImage、analytics 等"将来可能用到"的字段（YAGNI）。后续接入设计稿时再 propose 扩字段。

### D3: CTA 用 `<button>` 而非 `<a>`

hero 的 CTA 在真实业务里通常触发搜索或弹窗，不是简单的页面跳转。当前用 `<button>` 占位，预留语义正确性；占位阶段不绑 `onClick`，CTA 链接只通过 `data-cta-href` 属性表达占位意图。这避免了"改成 button 时再改测试"的二次工作。

> 反向决策：用 `<a href="#">`。简单但语义不准，未来必然要改回 `<button>`，迁移成本大。

### D4: MODIFIED delta 仅解除 HeroSlot 的空容器约束

与 feature-nav 的 MODIFIED delta 同形：把 `homepage-shell` 中"所有 Slot 必须为完全空容器"那条 Requirement 从"6 个 Slot 全空"改为"5 个 Slot 全空 + HeroSlot 例外（其内容契约见 homepage-hero）"。其他 Slot 约束不变。

### D5: 测试策略 — 三个独立用例

- 渲染出 `<section data-region="hero">` 包含 1 个 `<h1>`（用 RTL `getByRole('heading')` 或 `querySelector('h1')`）
- 渲染出 1 个 `<button>`（用 `getByRole('button')`）
- 不存在 `fetchFromBackend` / `fetch(` / `import.*lib/backend` 引用（grep 静态扫）

### D6: data 文件 default-export 单对象（不是 named export）

与 `featureNav.data.ts` 保持文件命名 + default export 的同形约定。`hero.data.ts` 默认导出一个 `HeroContent` 对象。

## Risks / Trade-offs

- **风险**：`<button>` 没绑 `onClick`，被严格 a11y lint 工具会报"useless button"。当前未配置该 lint，可接受。后续若引入 axe-core，须为 hero CTA 添加占位 onClick（即使是 noop）。
- **风险**：`data-cta-href` 这种自定义 data attr 是临时锚点，未来若 CTA 改成 `<a>` 跳转，需删除该属性。已在 spec 中显式约束此为占位，不构成永久契约。
- **Trade-off**：选 `<button>` 而非 `<a href="#">` 多花 5 行代码（不绑 onClick 的占位 button），换语义正确性 + 未来零迁移成本。值。
