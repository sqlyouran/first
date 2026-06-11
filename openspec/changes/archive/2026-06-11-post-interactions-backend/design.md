## Context

后端当前有 2 个业务实体（UserEntity + PostEntity）继承 BaseEntity，运行在 MySQL 8 上（ddl-auto: update）。PostController 已实现帖子 CRUD 的 6 个端点，其中写操作通过 `requireUserId(HttpServletRequest)` 私有方法做 JWT 认证。AuthController 有类似的 `extractBearerToken` 方法。本次新增三个互动模块，认证模式完全相同，触发 DRY 第三次提炼。

现有分层：controller → service → repository，依赖方向不可反向。异常通过 GlobalExceptionHandler 统一处理（AuthException / PostException 各自路由）。

## Goals / Non-Goals

**Goals:**

- 提炼 `requireUserId` / `getRequestId` 到公共工具类，消除跨 Controller 重复
- 新增 Comment / Vote / Bookmark 三个完整模块（Entity + Repository + Service + Controller + DTO）
- 评论支持无限嵌套回复，软删除后显示 [已删除] 但子回复可见
- 投票 unique constraint 保证一人一票，POST 创建/切换 + DELETE 取消
- 收藏 unique constraint 防重复，toggle 语义
- 投票统计端点支持可选认证（未登录 user_vote=null）
- @WebMvcTest 切片测试覆盖所有端点场景
- 分页响应遵循 api-conventions：`{ items, total, page, size, request_id }`

**Non-Goals:**

- 不做前端页面（留给后续 change）
- 不做评论内容审核/敏感词过滤
- 不做投票数缓存/异步计算
- 不做通知系统（评论被回复时的通知）
- 不重构 AuthController 的 extractBearerToken（仅提炼写操作认证模式）

## Decisions

### D1: 认证提炼方式 — 静态工具类 AuthUtil

**选择**：新增 `util/AuthUtil.java`，提供 `requireUserId(HttpServletRequest, JwtService)` 和 `getRequestId(HttpServletRequest)` 两个静态方法。

**替代方案**：
- BaseController 抽象基类 → 强制继承链，不灵活
- Spring Interceptor 全局拦截 → 改动面大，需标注哪些路径需要认证

**理由**：静态方法无继承耦合，调用处一行代码，PostController / 新 Controller 均可直接调用。

### D2: 三模块各自独立 Controller

**选择**：CommentController / VoteController / BookmarkController 各自独立。

**理由**：URL 路径天然分离，职责单一，未来独立扩展不互相影响。

### D3: 复用 PostException

**选择**：三个模块共用 PostException，不新建异常类。

**替代方案**：新建 InteractionException → 增加类但行为完全相同。

**理由**：PostException 结构通用（status + errorCode + message），GlobalExceptionHandler 已注册处理，零成本复用。如未来语义分化再拆分。

### D4: Vote toggle 语义 — Service 层三态判断

```
vote(postId, userId, voteType):
  existing = findByPostIdAndUserId(postId, userId)
  if !existing       → 创建新投票
  if existing.type == voteType → 删除（取消）
  if existing.type != voteType → 更新（切换）
```

API 分离：POST 创建/切换，DELETE 明确取消。

### D5: Comment 软删除展示策略

**选择**：查询时包含 deleted=true 的评论，Service 层将其 content 替换为 "[已删除]"，子回复正常展示。

**替代方案**：物理删除或级联隐藏 → 破坏对话上下文。

**理由**：保留对话上下文，用户可看到"有人回复过已删除的内容"。

### D6: vote-stats 可选认证

**选择**：GET `/api/posts/{postId}/vote-stats` 不强制 JWT。Controller 尝试解析 token，失败则 user_vote=null。

**实现**：`optionalUserId(HttpServletRequest, JwtService)` → `Optional<UUID>`。

### D7: Bookmark toggle 单端点

**选择**：POST `/api/posts/{postId}/bookmark` 作为 toggle——不存在则收藏，已存在则取消。返回 `{ bookmarked: true/false }`。

**理由**：前端只需一个按钮一个请求，状态由响应驱动。

### D8: 分页查询排序

- 评论列表：`created_at ASC`（时间正序，符合对话阅读习惯）
- 收藏列表：`created_at DESC`（最近收藏在前）

## Risks / Trade-offs

- **[风险] 评论无限嵌套的查询性能** → 当前仅按 parentCommentId 查一层回复（不递归），前端决定加载深度。如未来嵌套过深可加 depth 字段限制。
- **[风险] Vote unique constraint 并发冲突** → MySQL unique index 保证数据一致性，Service 层捕获 DataIntegrityViolationException 转业务异常。
- **[风险] Bookmark toggle 幂等性** → 基于 unique constraint 查询后操作，无并发问题（同一用户串行请求）。
- **[权衡] 复用 PostException 命名不完美** → 可接受，避免过早抽象。命名上 "PostException" 覆盖 "post 相关操作" 的语义边界。
- **[权衡] AuthUtil 静态方法不可 mock** → 测试中通过 MockMvc + 真实 JwtService 端到端验证，无需单独 mock 工具类。
