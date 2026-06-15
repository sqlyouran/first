## 1. API 客户端层泛化

- [x] 1.1 `lib/api/interactions.ts` 新增 `entityPath(entityType)` 辅助函数：`"post"` → `"posts"`，`"spot"` → `"spots"`
- [x] 1.2 `fetchBookmarkStatus` / `toggleBookmark` 签名改为 `(entityId, entityType)`，URL 使用 `entityPath` 拼接
- [x] 1.3 `fetchComments` / `createComment` / `deleteComment` 签名改为 `(entityId, entityType, ...)`，URL 使用 `entityPath` 拼接
- [x] 1.4 `fetchReplies` 保持不变（仍用 commentId，与实体类型无关）
- [x] 1.5 `interactions.test.ts` 适配：所有测试用例传入 `entityType`，验证 URL 拼接正确
- [x] 1.6 验证：`cd frontend && npm test -- --run lib/api/interactions` 绿灯

## 2. BookmarkButton 泛化

- [x] 2.1 `BookmarkButton.tsx` props 从 `postId` 改为 `entityId + entityType`（类型 `"post" | "spot"`）
- [x] 2.2 内部 `useEffect` 中 `fetchBookmarkStatus(entityId, entityType)` 适配
- [x] 2.3 内部 `handleClick` 中 `toggleBookmark(entityId, entityType)` 适配
- [x] 2.4 `BookmarkButton.test.tsx` 适配：传入 `entityId + entityType` props
- [x] 2.5 验证：`npm test -- --run BookmarkButton` 绿灯

## 3. CommentSection / CommentInput / CommentItem 泛化

- [x] 3.1 `CommentSection.tsx` props 从 `postId` 改为 `entityId + entityType`
- [x] 3.2 内部 `fetchComments(entityId, entityType, ...)` 调用适配
- [x] 3.3 `CommentInput.tsx` props 从 `postId` 改为 `entityId + entityType`，`createComment` 调用适配
- [x] 3.4 `CommentItem.tsx` 回复按钮触发的 CommentInput 传入 `entityId + entityType`
- [x] 3.5 各组件测试适配新 props
- [x] 3.6 验证：`npm test -- --run CommentSection CommentInput CommentItem` 绿灯

## 4. 帖子详情页适配

- [x] 4.1 `app/posts/[id]/page.tsx`：BookmarkButton 调用改为 `<BookmarkButton entityId={id} entityType="post" .../>`
- [x] 4.2 CommentSection 调用改为 `<CommentSection entityId={id} entityType="post" />`
- [x] 4.3 `page.test.tsx` 适配：验证传入新 props
- [x] 4.4 验证：`npm test -- --run posts/[id]` 绿灯

## 5. SpotGallery 图片轮播组件

- [x] 5.1 新建 `app/spots/[id]/_components/SpotGallery.tsx`（"use client"）：接收 `images: string[]`（gallery + coverImage 合并）
- [x] 5.2 主图 Carousel：`aspect-[16/9]`，每张图 `bg-cover bg-center`，左右箭头导航
- [x] 5.3 缩略图条：底部 Carousel，`aspect-[4/3]` 小图，点击跳转主图
- [x] 5.4 双 Carousel 联动：主图 `onSelect` → 缩略图 `scrollTo(index)`；缩略图点击 → 主图 `scrollTo(index)`
- [x] 5.5 当前选中缩略图高亮：`ring-2 ring-blue-700 rounded-md`
- [x] 5.6 无图片占位：渐变背景 + 居中 MapPin 图标
- [x] 5.7 新建 `SpotGallery.test.tsx`：渲染图片 / 无图片占位 / 缩略图数量正确
- [x] 5.8 验证：`npm test -- --run SpotGallery` 绿灯

## 6. SpotInfo 基本信息组件

- [x] 6.1 新建 `app/spots/[id]/_components/SpotInfo.tsx`：接收景点数据，两列 grid 布局（`grid-cols-1 md:grid-cols-2`）
- [x] 6.2 展示字段：城市、英文名、中文名、状态、评分（Star 图标 + `text-amber-500`）、浏览量、收藏量、创建时间
- [x] 6.3 新建 `SpotInfo.test.tsx`：验证各字段渲染
- [x] 6.4 验证：`npm test -- --run SpotInfo` 绿灯

## 7. RelatedPosts 预留区块

- [x] 7.1 新建 `app/spots/[id]/_components/RelatedPosts.tsx`：Card 容器 + 标题"相关攻略" + 居中 BookOpen 图标 + "即将上线"文案
- [x] 7.2 新建 `RelatedPosts.test.tsx`：验证预留文案渲染
- [x] 7.3 验证：`npm test -- --run RelatedPosts` 绿灯

## 8. 景点详情页集成

- [x] 8.1 新建 `app/spots/[id]/page.tsx`（Server Component）：SSR 并行 fetch 景点详情 + 收藏状态
- [x] 8.2 页面布局：返回导航 → Gallery → 标题区（名称 + 城市 + 标签 + 统计行） → 收藏按钮 → SpotInfo → 描述区块 → 评论区 → RelatedPosts
- [x] 8.3 景点不存在时调用 `notFound()`
- [x] 8.4 标题区：`text-3xl font-bold text-slate-900 lg:text-4xl` + 城市 `text-base text-slate-500` + 标签 Badge 列表
- [x] 8.5 描述区块：`text-sm text-slate-600 leading-relaxed`，优先显示 `description_zh`，fallback 到 `description`
- [x] 8.6 新建 `page.test.tsx`：验证页面渲染 + SSR 预取 + notFound
- [x] 8.7 验证：`npm test -- --run spots/[id]` 绿灯

## 9. 全量验证

- [x] 9.1 `cd frontend && npm test`：全量测试绿灯
- [ ] 9.2 启动 dev server，手动验证景点详情页渲染（Gallery 轮播 + 缩略图联动）
- [ ] 9.3 手动验证帖子详情页互动组件行为不变（收藏 / 评论正常）
