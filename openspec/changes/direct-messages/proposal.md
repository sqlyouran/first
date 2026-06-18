## Why

用户间缺乏私密沟通渠道，只能通过公开评论区交流。旅行场景中用户常需就攻略细节、路线建议进行一对一咨询，站内信填补这一空白。

## What Changes

- 新增 `ConversationEntity` + `MessageEntity` 实体
- 新增后端 API：查找/创建会话、消息列表分页、发送消息、标记已读、未读计数
- 会话唯一性由 Service 层查询保证（非数据库复合唯一约束）
- 新增前端页面：`/messages`（会话列表）、`/messages/[conversationId]`（对话详情）
- 他人资料页 `/users/[username]` 新增 "Send Message" 按钮
- 导航栏新增 MessageCircle icon + 未读 badge
- `middleware.ts` 新增 `/messages` 路由守卫

## Capabilities

### New Capabilities
- `direct-messages`: 用户间一对一私信——会话管理、消息收发、已读标记、未读计数、频率限制

### Modified Capabilities
- `user-profile`: 他人公开资料页 `/users/[username]` 新增 "Send Message" 入口（仅已登录用户可见）

## Impact

- **Backend**: 新增 `ConversationEntity` + `MessageEntity` + 对应 Repository / Service / Controller
- **Frontend**: 新增 `/messages` 列表页 + `/messages/[conversationId]` 对话页 + `MessageIcon` 导航栏组件 + `messages` Zustand store
- **Database**: 新增 `conversations` 表 + `messages` 表 + 索引
- **Middleware**: `PROTECTED_PAGES` 新增 `/messages`
- **依赖**: 依赖 `user-profile` change 的 nickname + avatar_url + username
