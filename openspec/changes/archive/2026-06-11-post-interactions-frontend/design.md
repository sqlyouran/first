## Context

后端已完成评论/投票/收藏 API（`post-interactions-backend` change），提供以下端点：

- `POST/DELETE /api/posts/{id}/vote`、`GET /api/posts/{id}/vote-stats`（可选认证）
- `POST /api/posts/{id}/bookmark`（toggle）、`GET /api/bookmarks`
- `POST/GET /api/posts/{id}/comments`、`GET /api/comments/{id}/replies`、`DELETE /api/posts/{id}/comments/{commentId}`

前端当前使用 `lib/api/authFetch.ts`（自动附加 Bearer token + 401 refresh）+ `lib/api/client.ts`（`ApiResponse<T>` 泛型）。认证状态通过 `useAuthStore`（Zustand）管理。

缺少 `GET /api/posts/{id}/bookmark-status` 端点（SSR 预取用）。

## Goals / Non-Goals

**Goals:**

- Server Component SSR 预取投票统计 + 收藏状态，客户端零闪烁
- 投票/收藏乐观更新，失败自动回滚 + toast 提示
- 评论区展示 2 层嵌套 + "查看更多"加载更深回复
- 未登录用户点击互动按钮跳 `/login`
- `lib/api/interactions.ts` 封装所有互动 API，复用 `authFetch` + `parseResponse` 模式
- 后端新增 `GET /api/posts/{id}/bookmark-status` 端点
- 所有新组件 Vitest + RTL 测试覆盖

**Non-Goals:**

- 不做帖子列表页的投票/收藏计数展示
- 不做评论 @mention / 富文本 / 图片上传
- 不做评论点赞/回复嵌套超过2层的完整展示
- 不做用户昵称/头像系统（短期用截断 UUID + 默认头像）
- 不做评论实时推送（WebSocket）

## Decisions

### D1: Toast 方案 — sonner

**选择**：`sonner`（shadcn/ui 官方推荐）

**替代方案**：
- `react-hot-toast` → 社区更大但非 shadcn 官方生态
- 自建 toast store → YAGNI，sonner 已满足需求且极小（~3KB）

**理由**：与 shadcn/ui 生态一致，API 简洁（`toast.error("msg")`），零配置开箱即用。

### D2: 初始状态获取策略 — SSR 预取

**选择**：`page.tsx`（Server Component）在 SSR 阶段并行 fetch `vote-stats` 和 `bookmark-status`，作为 props 传给 Client 互动组件。

**替代方案**：
- Client 组件 `useEffect` 自取 → 有 loading 闪烁，UX 差
- 新增聚合接口 `/api/posts/{id}/interactions` → 当前只有两个字段，不值得引入聚合层

**理由**：Next.js SSR 天然支持并行 fetch，无额外客户端请求，零闪烁。

### D3: bookmark-status 独立端点 vs 嵌入帖子详情

**选择**：新增 `GET /api/posts/{id}/bookmark-status`（可选认证）。

**替代方案**：在 `PostResponse` 中嵌入 `bookmarked` 字段 → 帖子详情接口耦合用户维度，需改缓存策略。

**理由**：独立端点不污染帖子详情缓存，且 bookmark-status 可被其他场景复用（如列表页收藏标记）。

### D4: 乐观更新模式 — 手动 state rollback

**选择**：`useState` + 手动 rollback（记住旧状态，失败时 `setState(prev)`）。

**替代方案**：
- SWR `mutate` optimistic → 引入新依赖，当前项目无 SWR
- TanStack Query → 同上，不在锁定栈内

**理由**：投票/收藏状态简单（一个 bool + 计数），手动 rollback 足够清晰，无需引入额外依赖。

### D5: 评论区层级策略

**选择**：展示 2 层 + "查看更多 N 条回复"。点击"查看更多"时调用 `fetchReplies(parentId)` 加载下一层（递归渲染，但视觉最多缩进 2 层）。

**替代方案**：
- 无限缩进 → 移动端体验差，深层嵌套不可读
- 仅展示 1 层 → 讨论上下文丢失

**理由**：2 层是 Reddit/知乎的常见平衡点，"查看更多"保证深度讨论可达但不过度展示。

### D6: 组件文件位置

**选择**：`app/posts/_components/`（posts 路由组共享目录）。

**替代方案**：`app/posts/[id]/_components/`（详情页专属）→ 投票/收藏组件未来可能在列表页复用。

**理由**：`posts/_components/` 是路由组级别的共享目录，符合 frontend-conventions，预留跨页面复用。

### D7: 未登录用户行为

**选择**：点击互动按钮 → `router.push("/login")`，不发请求。

**替代方案**：toast 提示"请先登录"→ 无后续动作，用户体验不完整。

**理由**：跳登录页让用户有明确的下一步，且与现有 middleware 保护策略一致。

### D8: 评论用户信息

**选择**：短期显示 `user_id.slice(0, 8)` + 灰色圆形占位头像。

**替代方案**：扩展 User 表加 nickname/avatar → 超出本次 scope。

**理由**：YAGNI，用户系统完善后再迭代。

## Risks / Trade-offs

- **[风险] SSR 预取增加 TTFB**：并行 fetch vote-stats + bookmark-status 可能增加首屏时间 → 缓解：两个请求都是简单 DB 查询（<50ms），并行执行总耗时接近单次
- **[风险] 乐观更新竞态**：用户快速连点 → 缓解：点击时 `disabled` 按钮，等 API 返回后再启用
- **[权衡] 评论无用户头像**：短期体验不完整 → 接受，用户系统完善后补全
- **[权衡] 手动 rollback vs 框架级方案**：当前手动管理，如未来互动组件增多可考虑引入 SWR → 当前复杂度可控，不过度工程
