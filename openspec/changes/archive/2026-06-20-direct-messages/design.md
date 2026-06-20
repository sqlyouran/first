## Context

用户间缺乏私密沟通渠道。旅行场景中用户需一对一咨询攻略细节。

已有基础设施：
- `UserEntity` 含 UUID id（`user-profile` change 后含 username/nickname/avatar_url）
- JWT 认证 + `BaseEntity`
- Next.js rewrites 代理 `/api/*` → 后端 8080
- 前端 Zustand store 模式 + `sonner` toast

依赖：`user-profile` change 的 nickname/avatar_url/username。

## Goals / Non-Goals

**Goals:**
- 用户间一对一私信（纯文本，1-2000 字符）
- 会话列表（按最新消息排序）+ 对话消息历史（分页 50 条）
- 进入对话自动标记已读
- 导航栏 MessageCircle icon + 未读 badge
- 频率限制（20 条/分钟/会话）

**Non-Goals:**
- 不做消息撤回/删除
- 不做消息搜索
- 不做屏蔽/拉黑
- 不做系统消息
- 不做富文本/图片
- 不做群聊

## Decisions

### D1: 会话唯一性——Service 层查询

**决策**：`ConversationService.findOrCreate(userIdA, userIdB)` 先查询是否已有会话（`WHERE (user_a_id = A AND user_b_id = B) OR (user_a_id = B AND user_b_id = A)`），无则创建

**理由**：PRD 要求最简原则，不依赖数据库复合唯一约束。Service 层查询 + 幂等处理并发。

### D2: 会话创建与首条消息原子化

**决策**：`POST /api/conversations` 接收 `{ recipient_username, content }`，在同一事务中创建会话 + 第一条消息

**理由**：避免出现空会话。API 同时返回 conversation_id，前端跳转对话页。

### D3: 消息已读——进入对话时批量标记

**决策**：`POST /api/conversations/{id}/mark-read`，进入对话页时调用，将该会话中对方发送的所有未读消息标记为 read

**理由**：简单直接，无需逐条标记。

### D4: 未读消息总数——聚合查询

**决策**：`GET /api/conversations/unread-count` 返回所有会话中对方发送且 `read=false` 的消息总数

**理由**：导航栏 badge 需要总数，不区分会话。

### D5: 消息分页——游标分页 vs 偏移分页

**决策**：偏移分页 `?page=1&size=50`，按 `created_at DESC` 排序（前端反转显示顺序）

**理由**：与会话列表分页保持一致（项目约定偏移分页），前端拿到后 reverse 渲染。

### D6: 频率限制——Service 层计数

**决策**：`MessageService` 在发送前查询该会话中该用户最近 1 分钟内发送的消息数，超 20 条则拒绝（429 `rate_limited`）

**理由**：简单实现，无需 Redis。本期并发低，数据库 COUNT 足够。

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Service 层查会话唯一性非原子 | 并发创建时第二次查询到已有会话直接复用 |
| 消息量大后分页性能 | 索引 `(conversation_id, created_at DESC)` + 偏移分页 |
| 对方已删除仍可看到历史会话 | 会话列表标注 "Deleted user"，禁止发送新消息 |
| 频率限制 COUNT 查询开销 | 本期低并发可接受，后续可升级 Redis |
