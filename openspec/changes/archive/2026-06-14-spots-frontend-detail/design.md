## Context

景点后端 API（`spots-backend-api`）已提供 `GET /api/spots/{id}` 详情接口，返回完整数据（gallery 图片数组、tags、cityName、rating、viewCount、bookmarkCount）。前置 change `polymorphic-interactions-backend` 完成后，景点将拥有独立的收藏和评论端点。

前端现有帖子详情页（`app/posts/[id]/page.tsx`）采用 SSR 预取 + Client 互动组件模式，是景点详情页的良好参考。互动组件（BookmarkButton / CommentSection）当前硬绑 `postId`，需泛化。

shadcn/ui Carousel 组件（基于 embla-carousel）已安装，支持 `setApi` 暴露 API 实例，可用于双 Carousel 联动。

## Goals / Non-Goals

**Goals:**

- 景点详情页完整实现：Gallery（含缩略图条）、基本信息两列布局、收藏按钮、评论区、相关攻略预留
- BookmarkButton / CommentSection / interactions.ts 泛化为 `entityId + entityType`
- 帖子详情页调用适配新签名（传入 `entityType="post"`）
- Gallery 缩略图条：主图 + 底部小图预览，点击缩略图跳转主图，当前选中高亮
- Server Component SSR 预取景点详情 + 收藏状态
- 所有新组件 Vitest + RTL 测试覆盖

**Non-Goals:**

- 不实现景点投票功能（后端暂无景点投票端点）
- 不实现 Lightbox 全屏查看（Phase 1 只做 Carousel + 缩略图条）
- 不实现 slug 路由（当前用 UUID，slug 路由后续优化）
- 不对接相关攻略数据（预留 placeholder，等 SpotPostEntity 就绪）
- 不修改景点列表页

## Decisions

### D1: Gallery 缩略图条 — 双 Carousel 联动

**选择**：主图 Carousel + 底部缩略图 Carousel，通过 `CarouselApi` 的 `onSelect` 事件双向同步滚动位置。当前选中缩略图显示 `ring-2 ring-blue-700` 高亮。

**替代方案**：
- 纯 dot indicators → 无法预览缩略图，图片多时体验差
- 第三方 Lightbox 库 → 不在锁定栈内，YAGNI

**理由**：shadcn Carousel 已暴露 `setApi`，双 Carousel 联动只需 ~30 行同步代码，无需引入新依赖。

### D2: 互动组件泛化 — props 接口变更

**选择**：BookmarkButton / CommentSection 的 props 从 `{ postId }` 改为 `{ entityId: string, entityType: "post" | "spot" }`。

**替代方案**：
- 保留 postId + 新增 spotId → 组件接口冗余，每加一种实体类型加一个 prop
- 泛化为泛型组件 `<BookmarkButton<T>>` → 过度抽象

**理由**：`entityId + entityType` 是最小参数集，URL 拼接规则清晰（`/api/{type}s/{id}/bookmark`），新增实体类型无需改组件签名。

### D3: API 层 URL 拼接策略

**选择**：`interactions.ts` 中的 URL 根据 `entityType` 动态拼接：
- `entityType="post"` → `/api/posts/{id}/bookmark`
- `entityType="spot"` → `/api/spots/{id}/bookmark`

内部辅助函数 `entityPath(entityType)` 返回 `posts` 或 `spots`。

**替代方案**：
- 为每种实体类型写独立的 API 文件 → 代码重复
- 后端统一入口 `/api/entities/{type}/{id}/bookmark` → 后端选择了方案 B（直觉路径）

**理由**：前端 URL 拼接逻辑集中在一处，配合后端方案 B 的路径设计，保持前后端路径一致。

### D4: 景点详情页路由与文件结构

**选择**：`app/spots/[id]/page.tsx`，内部组件放 `app/spots/[id]/_components/`。

```
app/spots/[id]/
├── page.tsx                    ← Server Component
├── _components/
│   ├── SpotGallery.tsx         ← Client Component（双 Carousel）
│   ├── SpotInfo.tsx            ← Server Component（纯展示）
│   └── RelatedPosts.tsx        ← Server Component（placeholder）
```

**理由**：符合 frontend-conventions 的目录约定，`_components/` 为路由组内部组件目录。

### D5: 页面布局风格

**选择**：遵循 styling-conventions 的页面结构骨架：

```
min-h-screen bg-gradient-to-b from-slate-50 to-white
└── mx-auto max-w-5xl px-8 py-16 sm:px-12 lg:px-16
    ├── 返回导航（← 景点列表）
    ├── Gallery（全宽，aspect-[16/9]）
    ├── 标题区（名称 + 城市 + 标签 + 统计）
    ├── 收藏按钮
    ├── 基本信息（两列 grid）
    ├── 描述区块
    ├── 评论区
    └── 相关攻略（placeholder）
```

**理由**：与 styling-conventions 的页面完成度规范完全对齐，max-w-5xl 适合图文混排场景。

### D6: 相关攻略区块 — 静态预留

**选择**：渲染一个 Card 区块，标题"相关攻略"，内容为居中图标 + "即将上线" 文案 + 可选 CTA 按钮。不调用任何 API。

**替代方案**：
- 不预留 → 后续加区块时需改页面布局
- 硬编码假数据 → 误导用户

**理由**：预留区块保持页面结构完整，SpotPostEntity 就绪后只需替换数据源，不改布局。

## Risks / Trade-offs

- **[风险] 双 Carousel 联动兼容性**：embla-carousel 的 `scrollTo` API 在某些边界情况下可能不同步 → 缓解：`onSelect` 回调中判断 `canScrollPrev/Next` 后再同步
- **[风险] 互动组件泛化的回归风险**：BookmarkButton / CommentSection props 变更会影响帖子详情页 → 缓解：帖子详情页同步适配 + 全量测试验证
- **[权衡] Gallery 无 Lightbox**：Phase 1 用户无法点击放大查看 → 接受，后续迭代
- **[权衡] 相关攻略无数据**：预留 placeholder 暂无实际内容 → 接受，等后端关联表就绪
