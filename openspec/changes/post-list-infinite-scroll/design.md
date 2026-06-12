## Context

`post-list-stats-and-pagination` 变更已完成后端 cursor 分页基础（仅 `sort=latest`），前端列表页使用 offset 分页 + 排序 Tab。本次变更在此基础上：

1. 后端将 cursor 分页扩展到所有排序模式，首次加载也返回 `next_cursor`
2. 前端从 offset 分页切换为 IntersectionObserver 无限滚动
3. PostCard 互动统计零值隐藏 + 大数字格式化

约束：Spring Boot 3.3.x + JPA + MySQL 8（H2 测试）；Next.js 16 + React 19；不引入新的前端库。

## Goals / Non-Goals

**Goals:**
- 所有排序模式下均支持 cursor 无限滚动，前端不出现跳页/重复
- 首次加载（无 cursor 参数）也返回 `next_cursor`，让无限滚动从第一页就能启动
- PostCard 统计行无噪音：零值隐藏，>999 格式化
- 排序切换时清空列表，避免状态混乱

**Non-Goals:**
- 不引入虚拟滚动（react-window 等），帖子量级不需要
- 不实现"回到顶部"按钮
- 不改变后端 API URL 签名（仅扩展行为）

## Decisions

### D1: 复合 Cursor 编码格式

**决策**：聚合排序使用 `"count:ISO-timestamp"` 编码，latest 使用纯 ISO-timestamp。

```
sort=latest:         cursor = "2026-06-12T08:00:00Z"
sort=most_upvoted:   cursor = "5:2026-06-12T08:00:00Z"
sort=most_commented: cursor = "3:2026-06-12T08:00:00Z"
```

**理由**：前端只需透传字符串，无需理解语义；后端通过 `PostSortBy.decodeCursor()` 解析，`:` 分隔符与 ISO-8601 不冲突。

**替代方案**：Base64 JSON 编码 → 复杂度高，无必要。

### D2: 聚合排序 Keyset WHERE 条件

**决策**：使用 OR 复合条件：

```sql
WHERE (voteCount < :cursorVotes)
   OR (voteCount = :cursorVotes AND createdAt < :cursorTime)
ORDER BY voteCount DESC, createdAt DESC
```

其中 `voteCount` 用子查询表达：`(SELECT COUNT(v) FROM VoteEntity v WHERE v.postId = p.id AND v.voteType = 'UP')`。

**理由**：保证严格不重复（复合 keyset 无歧义），H2 + MySQL 均支持子查询在 WHERE + ORDER BY 中同时使用。

**替代方案**：用 `ROW_NUMBER()` 窗口函数 → H2 支持但 JPQL 不直接支持窗口函数。

### D3: 首次加载（offset）也返回 next_cursor

**决策**：offset 模式下，`PostService` 在构建响应时从最后一条 item 计算 cursor 并填入 `next_cursor`。

```java
// offset 分支末尾
String nextCursor = trimmed.isEmpty() ? null : buildCursor(lastItem, sort, stats);
return new PostListResponse(..., nextCursor, hasMore);
```

`buildCursor` 对 LATEST 取 `createdAt`，对聚合排序取 `stats[postId] + createdAt`。

**理由**：前端无限滚动逻辑统一——首次加载后就有 cursor，后续全走 cursor 分支，无需分支判断。

### D4: 前端状态模型

**决策**：用 `items: PostListItem[]` + `nextCursor: string | null` + `hasMore: boolean` + `isLoadingMore: boolean` 替代原有 `data: PostListData | null` + `page: number`。

```
┌─ 排序切换 ────────────────────────┐
│ items = [], nextCursor = null     │
│ fetchPosts({ sort, size })        │
│ items = [第一页...], nextCursor=X │
└───────────────────────────────────┘

┌─ 触底加载 ────────────────────────┐
│ isLoadingMore = true              │
│ fetchPosts({ sort, cursor, size })│
│ items = [...旧, ...新]            │
│ nextCursor = Y, hasMore = ?       │
└───────────────────────────────────┘
```

**理由**：无限滚动必须累积数据，不能像 offset 分页那样整体替换。

### D5: IntersectionObserver sentinel 策略

**决策**：在列表末尾渲染一个 `<div ref={sentinelRef}>` 作为观察目标，不观察最后一张卡片（避免卡片本身可见时误触发）。

```
[Card] [Card] [Card]
[Card] [Card] [Card]
<div ref={sentinelRef} />  ← 观察者目标
{isLoadingMore && <骨架屏×3>}
{!hasMore && <"已经到底啦">}
```

**理由**：sentinel div 高度为 0，不影响布局；只有滚动到底部才进入视口，触发精准。

### D6: formatCount 工具函数

**决策**：

```typescript
function formatCount(n: number): string | null {
  if (n === 0) return null;           // 隐藏
  if (n < 1000) return String(n);     // 原样
  if (n < 10000) return `${(n / 1000).toFixed(1)}k`; // 1.2k
  return `${Math.round(n / 1000)}k`;  // 12k
}
```

放在 `PostCard.tsx` 内（仅此处使用，DRY 原则：第一次不抽）。

### D7: 排序 Tab 文案调整

**决策**：`"最多评论"` → `"最多讨论"`，更口语化。

## Risks / Trade-offs

- **[聚合排序 cursor 性能]** → 子查询在 WHERE 里每次执行都计算，数据量大时可能变慢。Mitigation：帖子数量 <10k 时无感知；超过后考虑 materialized view 或冗余字段。
- **[无限滚动 URL 不保留状态]** → 刷新页面回到第一页。Mitigation：当前不做 URL 同步（非需求范围），后续可用 `history.replaceState` 记录 cursor。
- **[H2 vs MySQL JPQL 差异]** → 子查询在 WHERE + ORDER BY 里同时使用可能 H2 支持但 MySQL 报错。Mitigation：测试环境 H2 + 开发 MySQL 双验证。
