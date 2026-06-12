## 1. 后端 PostSortBy cursor 编解码

- [x] 1.1 `PostSortBy` 新增 `encodeCursor(long count, Instant createdAt)` 方法：LATEST 返回 ISO-timestamp，其他返回 `"count:timestamp"`
- [x] 1.2 `PostSortBy` 新增 `decodeCursor(String cursor)` 方法：解析为 `CursorValue` record（含 `count` + `timestamp`），非法格式抛 `IllegalArgumentException`
- [x] 1.3 `PostSortByTest`：验证 LATEST / MOST_UPVOTED / MOST_COMMENTED 编解码 + 非法格式异常

## 2. 后端 PostRepository keyset 扩展

- [x] 2.1 新增 `findByUpVoteCountCursor(PostStatus status, long cursorVotes, Instant cursorTime, Pageable pageable)` — 复合 keyset WHERE 子查询
- [x] 2.2 新增 `findByCommentCountCursor(PostStatus status, long cursorComments, Instant cursorTime, Pageable pageable)` — 同上（deleted=false 过滤）
- [x] 2.3 新增 `findByAuthorIdAndUpVoteCountCursor` / `findByAuthorIdAndCommentCountCursor` — 用户帖子变体
- [x] 2.4 `PostRepositoryTest`（集成测试）：验证三种排序的 keyset 查询正确性（含边界：cursor 恰好等于最后一条 / 空结果）

## 3. 后端 PostService 统一 keyset 分支

- [x] 3.1 重构 `listPosts`：去掉 `sort == LATEST` 限制，cursor 模式下根据 sort 选择对应 Repository 方法（decodeCursor 解析 count + timestamp）
- [x] 3.2 重构 `listUserPosts`：同上
- [x] 3.3 offset 分支（首次加载）末尾：从最后一条 item 计算 `nextCursor`（`buildCursor(lastItem, sort, stats)`），填入响应
- [x] 3.4 新增私有 `buildCursor(PostEntity lastItem, PostSortBy sort, Map<UUID, long[]> stats)` 方法
- [x] 3.5 更新 `PostControllerTest`：验证 sort=most_upvoted 首次加载返回非 null `next_cursor`
- [x] 3.6 更新 `PostControllerTest`：验证 sort=most_upvoted cursor 分页正确性（items 顺序 + next_cursor 格式）
- [x] 3.7 更新 `PostControllerTest`：验证 sort=most_commented cursor 分页正确性

## 4. 后端验收

- [x] 4.1 `mvn -f backend/pom.xml test` 全绿（新旧测试全部通过）

## 5. 前端 PostCard formatCount + 零值隐藏

- [x] 5.1 `PostCard.tsx` 新增 `formatCount(n: number): string | null` 工具函数（0→null，<1k→原样，<10k→1.2k，≥10k→12k）
- [x] 5.2 重构互动统计行：仅渲染 `formatCount` 返回非 null 的项，全 null 时整行不显示
- [x] 5.3 更新 `PostCard.test.tsx`：验证零值隐藏、部分显示、大数字格式化（1234→1.2k，12345→12k）

## 6. 前端帖子列表页无限滚动

- [x] 6.1 `page.tsx` 状态重构：`data: PostListData | null` → `items: PostListItem[]` + `nextCursor: string | null` + `hasMore: boolean` + `isLoadingMore: boolean`
- [x] 6.2 首次加载逻辑：`useEffect` 触发 `fetchPosts({ sort, size })`，成功后设置 items + nextCursor + hasMore
- [x] 6.3 触底加载逻辑：`useRef` sentinel div + `IntersectionObserver`，sentinel 进入视口时调用 `fetchPosts({ sort, cursor: nextCursor, size })`，新 items 追加
- [x] 6.4 排序切换逻辑：`handleSortChange` 清空 items / 重置 nextCursor / setIsLoadingMore(true)，触发首次加载
- [x] 6.5 底部 UI：`isLoadingMore` 显示 3 张 `PostCardSkeleton`，`!hasMore && items.length > 0` 显示"已经到底啦"
- [x] 6.6 排序 Tab 文案：`"最多评论"` → `"最多讨论"`
- [x] 6.7 移除旧 offset 分页 UI（上一页/下一页按钮 + 页码显示）

## 7. 前端测试与验收

- [x] 7.1 更新 `page.test.tsx`：验证首次加载渲染、排序 Tab 存在（最新/最热/最多讨论）、空列表提示
- [x] 7.2 `cd frontend && npm test` 全绿
- [ ] 7.3 手动验证：帖子列表页无限滚动 + 排序切换 + PostCard 统计零值隐藏
