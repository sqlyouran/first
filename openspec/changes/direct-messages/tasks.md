## 1. 后端 — 实体 + 基础设施

- [ ] 1.1 创建 `ConversationEntity` 继承 `BaseEntity`：`user_a_id`(UUID)、`user_b_id`(UUID)、`last_message_at`(Instant)
- [ ] 1.2 创建 `MessageEntity` 继承 `BaseEntity`：`conversation_id`(UUID, FK)、`sender_id`(UUID)、`content`(TEXT, max 2000)、`read`(BOOLEAN, default false)；索引 `(conversation_id, created_at DESC)`
- [ ] 1.3 创建 `ConversationRepository`：`findByUserAIdAndUserBIdOrUserAIdAndUserBId(UUID, UUID, UUID, UUID)`、`findByUserAIdOrUserBIdOrderByLastMessageAtDesc(UUID, UUID, Pageable)`
- [ ] 1.4 创建 `MessageRepository`：`findByConversationIdOrderByCreatedAtDesc(UUID, Pageable)`、`countByConversationIdAndSenderIdAndReadFalse(UUID, UUID)`
- [ ] 1.5 创建 `ConversationService`（构造器注入 `ConversationRepository` + `UserRepository`）
- [ ] 1.6 创建 `MessageService`（构造器注入 `MessageRepository` + `ConversationRepository` + `UserRepository`）

## 2. 后端 — 会话 API

- [ ] 2.1 创建 `ConversationController` + Request/Response DTO（`CreateConversationRequest`、`ConversationListResponse`、`ConversationItemResponse`）
- [ ] 2.2 编写 `POST /api/conversations` 测试：新会话（201 + conversation_id）+ 已有会话复用 + 给自己发 422 + 对方已删除 422 + content 空/超长 422
- [ ] 2.3 实现 `POST /api/conversations` 端点（Service 层 `findOrCreate` + 同一事务创建会话 + 首条消息）
- [ ] 2.4 编写 `GET /api/conversations?page=1&size=20` 测试（正常列表含 other_user/last_message/unread_count + 空列表 + 未认证 401）
- [ ] 2.5 实现 `GET /api/conversations` 端点（JOIN user 表获取对方 nickname/avatar_url/username/deleted + 聚合 unread_count）
- [ ] 2.6 编写 `GET /api/conversations/unread-count` 测试（有未读 + 无未读）
- [ ] 2.7 实现 `GET /api/conversations/unread-count` 端点（聚合查询所有会话对方未读消息总数）

## 3. 后端 — 消息 API

- [ ] 3.1 在 `ConversationController` 增加消息端点 + DTO（`SendMessageRequest`、`MessageListResponse`、`MessageItemResponse`、`MarkReadResponse`）
- [ ] 3.2 编写 `GET /api/conversations/{id}/messages?page=1&size=50` 测试（正常分页 + 无权访问 403 + 不存在 404）
- [ ] 3.3 实现 `GET /api/conversations/{id}/messages` 端点（校验当前用户为会话参与者 + 按 created_at DESC 分页）
- [ ] 3.4 编写 `POST /api/conversations/{id}/messages` 测试（发送成功 201 + 频率限制 429 + 对方已删除 422 + content 空/超长 422 + 非参与者 403）
- [ ] 3.5 实现 `POST /api/conversations/{id}/messages` 端点（频率限制：1 分钟内 20 条/会话 + 更新 conversation.last_message_at）
- [ ] 3.6 编写 `POST /api/conversations/{id}/mark-read` 测试（批量标记对方消息已读 + 非参与者 403）
- [ ] 3.7 实现 `POST /api/conversations/{id}/mark-read` 端点

## 4. 前端 — API 封装层

- [ ] 4.1 创建 `lib/api/messages.ts`：`createConversation(recipientUsername, content)`、`fetchConversations(page, size)`、`fetchMessages(conversationId, page, size)`、`sendMessage(conversationId, content)`、`markConversationRead(conversationId)`、`fetchUnreadCount()`
- [ ] 4.2 定义 TypeScript 类型：`ConversationData`、`ConversationItem`、`MessageData`、`MessageItem`、`UnreadCountData`

## 5. 前端 — messages Zustand store

- [ ] 5.1 创建 `lib/stores/messages.ts`：`totalUnread`、`setTotalUnread`、`decrementUnread(conversationId, count)`、`fetchTotalUnread`
- [ ] 5.2 编写 messages store 测试

## 6. 前端 — 会话列表页 /messages

- [ ] 6.1 创建 `app/messages/page.tsx`（Client Component，含加载 + 空状态 + 错误处理）
- [ ] 6.2 创建 `app/messages/_components/ConversationCard.tsx`（会话卡片，含有未读/无未读/hover/对方已删除/头像加载失败 5 种状态）
- [ ] 6.3 实现四态覆盖：Loading 骨架（4 条）/ Content / Empty（MessageCircle 引导 + Browse Travelers CTA）/ Error（AlertCircle + Retry）
- [ ] 6.4 实现相对时间显示（just now / Xm / Xh / Xd / 短日期）
- [ ] 6.5 实现响应式布局（Mobile 紧凑 / Tablet+ 完整）
- [ ] 6.6 编写 `/messages` 页面测试

## 7. 前端 — 对话详情页 /messages/[conversationId]

- [ ] 7.1 创建 `app/messages/[conversationId]/page.tsx`（Client Component，含消息列表 + 分页加载 + 发送消息）
- [ ] 7.2 创建 `app/messages/_components/MessageBubble.tsx`（消息气泡，含我的/对方/已读/未读/长消息/短消息 6 种状态）
- [ ] 7.3 创建 `app/messages/_components/MessageInput.tsx`（底部输入框，含 idle/typing/sending/send_success/send_error/rate_limited/partner_deleted/char_warning/char_limit 9 种状态）
- [ ] 7.4 创建 `app/messages/_components/DateSeparator.tsx`（日期分隔线：Today / Yesterday / 周几 / 完整日期）
- [ ] 7.5 实现四态覆盖：Loading（顶部栏骨架 + 气泡骨架 5 组）/ Content / Empty（首条引导）/ Error（重试 + 输入框 disabled）
- [ ] 7.6 实现顶部栏（返回箭头 + 对方头像 + 昵称 + @username）
- [ ] 7.7 实现消息气泡布局（自己靠右蓝色 / 对方靠左灰色 + 时间 + 已读 CheckCheck）
- [ ] 7.8 实现加载更多历史消息（顶部 Intersection Observer + 滚动位置保持）
- [ ] 7.9 实现 MessageInput 交互（Enter 发送 / Shift+Enter 换行 / Textarea 自动增高 / 字符计数 > 1800 显示）
- [ ] 7.10 实现发送消息乐观更新（追加气泡 + 清空输入 + 失败回滚 + toast）
- [ ] 7.11 实现进入对话自动标记已读（调用 mark-read API + 乐观更新 store）
- [ ] 7.12 实现频率限制处理（429 → 黄色提示 + 按钮 disabled + 30s 恢复）
- [ ] 7.13 实现对方已删除处理（输入框 placeholder 变为 "Cannot send" + disabled + 不渲染 Send 按钮）
- [ ] 7.14 实现响应式布局（Mobile 气泡 max-w-[85%] / Tablet+ max-w-[75%]）
- [ ] 7.15 编写 `/messages/[conversationId]` 页面测试

## 8. 前端 — MessageIcon 导航栏组件

- [ ] 8.1 创建 `app/_components/MessageIcon.tsx`（Client Component，MessageCircle icon + 未读 badge）
- [ ] 8.2 实现 7 种状态：未登录不渲染 / 0 未读无 badge / 1-99 / 100+（99+）/ hover / loading / fetch 失败静默
- [ ] 8.3 实现未读数刷新策略（挂载 + visibilitychange + 乐观更新 + 60s 轮询）
- [ ] 8.4 导航栏集成 MessageIcon（位于 NotificationBell 和用户头像之间）
- [ ] 8.5 编写 MessageIcon 组件测试

## 9. 前端 — 他人资料页 Send Message 入口

- [ ] 9.1 在 `app/users/[username]/page.tsx` 添加 "Send Message" 按钮（已登录 + 非自己时可见）
- [ ] 9.2 实现点击行为（调用 POST /api/conversations/find-or-create → 跳转 /messages/{id} + 错误 toast）
- [ ] 9.3 实现按钮状态（visible / hidden / loading / 对方已删除不渲染）
- [ ] 9.4 编写 Send Message 按钮测试

## 10. 前端 — 路由守卫

- [ ] 10.1 `middleware.ts` 的 `PROTECTED_PAGES` 新增 `/messages`
- [ ] 10.2 编写 middleware 测试更新
