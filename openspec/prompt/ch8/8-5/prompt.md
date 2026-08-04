```
/opsx:explore

目的：为帖子列表补充互动统计和分页能力

1. PostListResponse 增强
   在现有PostSummary基础上追加：
   - commentCount: Long → 该帖子的评论数（不含软删除）
   - upVoteCount: Long → 点赞数
   - bookmarkCount: Long → 收藏数
   - 这三个字段通过聚合查询获取，不在PostEntity里存冗余字段

2. 分页增强
   - 支持 cursor-based 分页（基于createdAt）
   - 也兼容传统 offset/limit 分页
   - 默认 pageSize=20，最大不超过100
   - 返回 nextCursor + hasMore 字段

3. 排序支持
   - 默认排序：createdAt DESC（最新发布）
   - 可选排序：upVoteCount DESC（最多点赞）
   - 可选排序：commentCount DESC（最多评论）

4. 遵循 api-conventions（分页响应格式）
   + database-conventions（Repository查询规范）
```

```
/opsx:explore

目的：增强帖子列表页——展示互动统计、支持分页加载和排序切换

1. PostCard 增强
   在现有卡片底部添加互动统计行：
   - 👍 upVoteCount  💬 commentCount  🔖 bookmarkCount
   - 数字为0时不显示该项（避免视觉噪音）
   - 数字超过999显示为 "1.2k"

2. 无限滚动加载
   - 使用 IntersectionObserver 监听列表底部
   - 触底时自动加载下一页（用cursor分页）
   - 加载中显示骨架屏（3张卡片placeholder）
   - 没有更多数据时显示"已经到底啦"

3. 排序切换 Tab
   - 列表顶部添加排序Tab：最新 | 最热 | 最多讨论
   - 切换时清空列表重新加载
   - 当前选中项用主色高亮

4. 遵循frontend-conventions + styling-conventions
```