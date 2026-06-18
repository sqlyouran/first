# 站内信（Direct Messages）交互规格

## 1. 页面概览

| 路由 | 组件类型 | 守卫 | 说明 |
|------|---------|------|------|
| `/messages` | Client Component | 需登录 | 会话列表页 |
| `/messages/[conversationId]` | Client Component | 需登录 | 对话详情页 |

**共享组件**：

| 组件 | 位置 | 说明 |
|------|------|------|
| `MessageIcon` | 导航栏右侧 | MessageCircle icon + 未读 badge |

**入口组件**：

| 组件 | 位置 | 说明 |
|------|------|------|
| "Send Message" 按钮 | `/users/[username]` 公开资料页 | 已登录用户可见，跳转会话 |

---

## 2. `/messages` — 会话列表页

### 2.1 页面结构

```
<div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
  <div className="mx-auto max-w-3xl px-8 py-16 sm:px-12 lg:px-16">

    <!-- 页面头部 -->
    <div className="mb-10">
      <h1 className="text-3xl font-bold text-slate-900 lg:text-4xl">Messages</h1>
      <p className="mt-2 text-base text-slate-500">Your private conversations</p>
    </div>

    <!-- 会话列表 -->
    <div className="space-y-2" role="list">
      {conversations.map(c => <ConversationCard />)}
    </div>

  </div>
</div>
```

### 2.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | 首次加载会话列表 | 4 行会话骨架：每行 = 圆形头像骨架（48px）+ 2 行文字骨架（昵称 + 预览）+ 右侧短骨架（时间） |
| **Content** | 有会话数据 | 渲染会话卡片列表 |
| **Empty** | 会话列表为空（0 个会话） | Card 居中引导 |
| **Error** | API 请求失败 | Card 居中错误 + Retry |

### 2.3 Loading 骨架详细规格

```
<div className="flex items-center gap-4 p-4 rounded-xl border border-slate-100">
  <Skeleton className="h-12 w-12 rounded-full shrink-0" />          ← 对方头像
  <div className="flex-1 space-y-2">
    <Skeleton className="h-4 w-[40%]" />                            ← 昵称
    <Skeleton className="h-3 w-[70%]" />                            ← 消息预览
  </div>
  <Skeleton className="h-3 w-8 shrink-0" />                         ← 时间
</div>
× 4 条
```

### 2.4 Empty 状态详细规格

```
<Card className="p-12 shadow-sm border border-slate-200 text-center">
  <MessageCircle className="mx-auto h-12 w-12 text-slate-300" />
  <h2 className="mt-4 text-lg font-medium text-slate-900">No messages yet</h2>
  <p className="mt-2 text-sm text-slate-500">
    Start a conversation by messaging another traveler.
  </p>
  <Link href="/posts" className="mt-6 inline-flex">
    <Button variant="outline">
      <Users className="h-4 w-4 mr-2" /> Browse Travelers
    </Button>
  </Link>
</Card>
```

### 2.5 Error 状态详细规格

```
<Card className="p-12 shadow-sm border border-slate-200 text-center">
  <AlertCircle className="mx-auto h-12 w-12 text-destructive" />
  <h2 className="mt-4 text-lg font-medium text-slate-900">Unable to load messages</h2>
  <p className="mt-2 text-sm text-slate-500">Please check your connection and try again.</p>
  <Button variant="outline" className="mt-4" onClick={retry}>
    <RefreshCw /> Retry
  </Button>
</Card>
```

---

## 3. ConversationCard 组件

### 3.1 组件概述

- 用途：会话列表中的单个会话卡片
- 类型：Client Component（点击跳转）

### 3.2 Props 定义

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `conversation_id` | `string` | ✅ | 会话 ID |
| `other_user` | `{ nickname: string; avatar_url: string \| null; username: string; deleted: boolean }` | ✅ | 对方用户信息 |
| `last_message` | `string` | ✅ | 最后一条消息预览（≤50 字符） |
| `last_message_at` | `string` (ISO 8601) | ✅ | 最后消息时间 |
| `unread_count` | `number` | ✅ | 对方发来的未读消息数 |

### 3.3 卡片布局

```
<Link href={`/messages/${conversation_id}`}
      className="flex items-center gap-4 p-4 rounded-xl
                 border border-slate-200 bg-white
                 transition-shadow hover:shadow-md
                 cursor-pointer">

  <!-- 对方头像 -->
  <Avatar className="h-12 w-12 rounded-full shrink-0" />

  <!-- 中间内容区 -->
  <div className="flex-1 min-w-0">
    <div className="flex items-center justify-between">
      <p className={`text-sm truncate ${unread > 0 ? 'font-semibold text-slate-900' : 'font-medium text-slate-700'}`}>
        {other_user.deleted ? 'Deleted user' : other_user.nickname}
      </p>
      <span className="text-xs text-slate-400 shrink-0 ml-2">{relativeTime}</span>
    </div>
    <div className="flex items-center justify-between mt-0.5">
      <p className={`text-sm truncate ${unread > 0 ? 'font-medium text-slate-700' : 'text-slate-500'}`}>
        {last_message}
      </p>
      {unread > 0 && (
        <span className="ml-2 flex items-center justify-center min-w-[20px] h-5 rounded-full
                         bg-blue-700 text-white text-xs font-bold px-1.5 shrink-0">
          {unread}
        </span>
      )}
    </div>
  </div>
</Link>
```

### 3.4 组件状态详表

| 状态 | 视觉差异 |
|------|---------|
| **有未读** (`unread_count > 0`) | 昵称 `font-semibold text-slate-900`，预览 `font-medium text-slate-700`，右侧蓝色 badge |
| **无未读** (`unread_count = 0`) | 昵称 `font-medium text-slate-700`，预览 `text-slate-500`，无 badge |
| **hover** | `hover:shadow-md`，卡片浮起感 |
| **对方已删除** (`deleted = true`) | 头像默认占位图，昵称 "Deleted user"（`text-slate-400 italic`），仍可点击进入查看历史 |
| **头像加载失败** | `onError` → 默认占位头像 |

### 3.5 相对时间显示规则

| 时间差 | 显示 |
|--------|------|
| < 1 分钟 | "just now" |
| 1–59 分钟 | "{n}m" |
| 1–23 小时 | "{n}h" |
| 1–6 天 | "{n}d" |
| ≥ 7 天 | 短日期 "Jun 18" |

---

## 4. `/messages/[conversationId]` — 对话详情页

### 4.1 页面结构

```
<div className="flex flex-col h-screen bg-white">

  <!-- 顶部栏 -->
  <header className="sticky top-0 z-10 flex items-center gap-3 px-6 py-4
                     border-b border-slate-200 bg-white/95 backdrop-blur-sm">
    <Link href="/messages"><ArrowLeft /></Link>
    <Avatar className="h-8 w-8 rounded-full" />
    <div>
      <p className="text-sm font-semibold text-slate-900">{nickname}</p>
      <p className="text-xs text-slate-500">@{username}</p>
    </div>
  </header>

  <!-- 消息区域（可滚动） -->
  <main className="flex-1 overflow-y-auto px-6 py-4" role="log" aria-live="polite">

    <!-- 加载更多（顶部） -->
    {hasMore && <LoadMoreIndicator />}

    <!-- 消息列表 -->
    {messages.map(m => <MessageBubble />)}

  </main>

  <!-- 底部输入区 -->
  <footer className="sticky bottom-0 border-t border-slate-200 bg-white px-6 py-3">
    <MessageInput />
  </footer>

</div>
```

### 4.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | 首次加载消息历史 | 顶部栏骨架（头像 + 名字）+ 消息区 5 条气泡骨架（交替左右） + 底部输入框正常显示（disabled） |
| **Content** | 有消息数据 | 渲染消息气泡 + 可用输入框 |
| **Empty** | 会话存在但无消息（理论上不应出现，会话创建伴随第一条消息） | 居中提示 "Send the first message to start the conversation" + 可用输入框 |
| **Error** | 加载消息失败 | 消息区居中错误 + Retry + 输入框 disabled |

### 4.3 Loading 骨架详细规格

```
{/* 顶部栏骨架 */}
<div className="flex items-center gap-3">
  <Skeleton className="h-8 w-8 rounded-full" />
  <div className="space-y-1">
    <Skeleton className="h-4 w-24" />
    <Skeleton className="h-3 w-16" />
  </div>
</div>

{/* 消息区骨架 — 交替左右 */}
<div className="space-y-4 py-4">
  {/* 对方消息（左） */}
  <div className="flex flex-col items-start">
    <Skeleton className="h-16 w-[70%] rounded-2xl" />
    <Skeleton className="h-3 w-12 mt-1" />
  </div>
  {/* 自己消息（右） */}
  <div className="flex flex-col items-end">
    <Skeleton className="h-10 w-[50%] rounded-2xl bg-blue-100" />
    <Skeleton className="h-3 w-12 mt-1" />
  </div>
  ... × 5 组
</div>
```

### 4.4 Error 状态详细规格

```
<div className="flex-1 flex items-center justify-center">
  <div className="text-center">
    <AlertCircle className="mx-auto h-10 w-10 text-destructive" />
    <p className="mt-3 text-sm font-medium text-slate-900">Unable to load conversation</p>
    <p className="mt-1 text-xs text-slate-500">Please check your connection and try again.</p>
    <Button variant="outline" size="sm" className="mt-4" onClick={retry}>
      <RefreshCw /> Retry
    </Button>
  </div>
</div>
```

---

## 5. MessageBubble 组件

### 5.1 组件概述

- 用途：单条消息气泡
- 类型：纯展示组件

### 5.2 Props 定义

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | `string` | ✅ | 消息 ID |
| `content` | `string` | ✅ | 消息纯文本内容 |
| `sender_id` | `string` | ✅ | 发送者 ID |
| `is_mine` | `boolean` | ✅ | 是否为当前用户发送 |
| `created_at` | `string` (ISO 8601) | ✅ | 发送时间 |
| `read` | `boolean` | ✅ | 对方是否已读（仅自己发送的消息有意义） |

### 5.3 气泡布局

```
<div className={`flex flex-col ${is_mine ? 'items-end' : 'items-start'} mb-3`}>

  <!-- 气泡 -->
  <div className={`max-w-[75%] px-4 py-2.5 rounded-2xl
    ${is_mine
      ? 'bg-blue-700 text-white rounded-br-md'
      : 'bg-slate-100 text-slate-900 rounded-bl-md'
    }`}>
    <p className="text-sm whitespace-pre-wrap break-words">{content}</p>
  </div>

  <!-- 时间 + 已读标记 -->
  <div className="flex items-center gap-1 mt-1 px-1">
    <span className="text-[11px] text-slate-400">{messageTime}</span>
    {is_mine && read && (
      <CheckCheck className="h-3 w-3 text-blue-500" aria-label="Read" />
    )}
  </div>
</div>
```

### 5.4 组件状态详表

| 状态 | 视觉差异 |
|------|---------|
| **我的消息** (`is_mine = true`) | 靠右对齐，`bg-blue-700 text-white`，右下角 `rounded-br-md`（小圆角） |
| **对方消息** (`is_mine = false`) | 靠左对齐，`bg-slate-100 text-slate-900`，左下角 `rounded-bl-md` |
| **已读** (`is_mine && read`) | 时间旁显示蓝色 `CheckCheck` icon |
| **未读** (`is_mine && !read`) | 仅显示时间，无已读标记 |
| **长消息** | `max-w-[75%]` 限宽，`break-words` 换行，`whitespace-pre-wrap` 保留换行 |
| **短消息** | 气泡自适应宽度 |

### 5.5 消息时间显示

- 格式：`HH:mm`（如 "14:32"）
- 同一天内仅显示时间
- 跨天时显示日期分隔线（见 §6）

---

## 6. 日期分隔线

当消息跨越不同日期时，在两组消息之间插入分隔线：

```
<div className="flex items-center gap-3 my-6">
  <div className="flex-1 h-px bg-slate-200" />
  <span className="text-xs text-slate-400 font-medium">{dateLabel}</span>
  <div className="flex-1 h-px bg-slate-200" />
</div>
```

| 时间范围 | dateLabel |
|---------|-----------|
| 今天 | "Today" |
| 昨天 | "Yesterday" |
| 本周内 | "Monday" / "Tuesday" 等 |
| 更早 | "Jun 18, 2026" |

---

## 7. MessageInput 组件

### 7.1 组件概述

- 用途：底部消息输入框
- 类型：Client Component（交互密集）

### 7.2 布局

```
<div className="flex items-end gap-2">
  <Textarea
    className="flex-1 min-h-[40px] max-h-[160px] resize-none
               rounded-xl border border-slate-200 px-4 py-2.5
               text-sm focus-visible:ring-2 focus-visible:ring-blue-700/20
               disabled:bg-slate-50 disabled:cursor-not-allowed"
    placeholder="Type a message..."
    rows={1}
    maxLength={2000}
  />
  <Button
    className="h-10 w-10 rounded-full shrink-0"
    disabled={!canSend}
    aria-label="Send message"
  >
    <Send className="h-4 w-4" />
  </Button>
</div>

<!-- 字符计数（仅在 > 1800 字符时显示） -->
{charCount > 1800 && (
  <p className={`text-xs mt-1 text-right ${charCount >= 2000 ? 'text-red-500' : 'text-amber-500'}`}>
    {charCount}/2000
  </p>
)}

<!-- 频率限制提示 -->
{rateLimited && (
  <p className="text-xs mt-1 text-amber-600">
    You're sending too fast. Please wait a moment.
  </p>
)}
```

### 7.3 状态详表

| 状态 | 输入框表现 | 发送按钮表现 |
|------|-----------|-------------|
| **idle**（空输入） | placeholder "Type a message..." | `disabled`，`bg-slate-100 text-slate-400` |
| **typing**（有内容） | 显示输入文本，自动增高（max-h 160px） | `enabled`，`bg-blue-700 text-white hover:bg-blue-800` |
| **sending** | `disabled` | `<Loader2 />` 旋转，`disabled` |
| **send_success** | 清空文本，恢复单行高度 | 恢复 idle 态 |
| **send_error** | 保留文本，恢复可用 | toast 错误提示 + 恢复 enabled |
| **rate_limited** | 保留文本，显示频率限制提示 | `disabled`，30 秒后自动恢复 |
| **conversation_partner_deleted** | placeholder "Cannot send — user is no longer available"，`disabled` | `disabled`，不渲染 Send 按钮 |
| **char_count_warning**（> 1800） | 字符计数 `text-amber-500` | 正常可用 |
| **char_count_limit**（= 2000） | 字符计数 `text-red-500`，禁止继续输入 | `disabled` |

### 7.4 键盘交互

| 按键 | 行为 |
|------|------|
| `Enter` | 发送消息（前提：有内容且未 sending） |
| `Shift + Enter` | 插入换行（不发送） |
| `Escape` | 无操作 |

### 7.5 Textarea 自动增高

- 初始 `rows={1}`（`min-h-[40px]`）
- 随输入内容自动增高，最大 `max-h-[160px]`
- 超过 max-h 后内部滚动
- 发送后恢复单行

---

## 8. 加载更多历史消息

### 8.1 触发机制

- 消息区滚动到顶部时触发（Intersection Observer 监听顶部哨兵元素）
- 每页 50 条
- 新加载的消息插入到列表顶部

### 8.2 加载更多状态

| 状态 | 视觉表现 |
|------|---------|
| **hasMore = true，未触发** | 顶部不显示任何内容 |
| **loading more** | 顶部居中 `<Loader2 />` 旋转 + "Loading earlier messages..."（`text-sm text-slate-400`） |
| **hasMore = false** | 顶部显示分隔文案 "This is the beginning of your conversation"（`text-xs text-slate-400 text-center py-4`） |
| **load more error** | 顶部居中 "Failed to load earlier messages" + "Retry" 链接 |

### 8.3 滚动位置保持

加载更多消息后，需保持当前阅读位置不跳动：
- 记录加载前第一条可见消息的 DOM 位置
- 新消息插入后，`scrollIntoView` 回到原位置

---

## 9. 发起新对话流程

### 9.1 从他人资料页触发

用户点击 `/users/{username}` 页面的 "Send Message" 按钮后：

```
点击 "Send Message"
  → 调用 POST /api/conversations/find-or-create { username: "xxx" }
  → 成功：返回 conversation_id
      → router.push(`/messages/${conversation_id}`)
  → 对方已删除 (422)：toast "This user is no longer available"
  → 自己 (422)：前端阻止（按钮不显示）
  → 网络错误：toast "Failed to start conversation"
```

### 9.2 "Send Message" 按钮状态

| 状态 | 视觉表现 |
|------|---------|
| **visible**（已登录 + 非自己） | `variant="outline"` + `MessageCircle` icon + "Send Message" |
| **hidden**（未登录 / 查看自己资料） | 不渲染 |
| **loading**（正在查找/创建会话） | `<Loader2 />` 旋转 + "Starting..."，`disabled` |
| **对方已删除** | 不渲染（或点击后 toast 提示） |

---

## 10. MessageIcon — 导航栏消息入口

### 10.1 组件概述

- 用途：导航栏右上角消息 icon，展示未读消息总数
- 类型：Client Component

### 10.2 位置

导航栏右侧，位于 NotificationBell 和用户头像之间。

### 10.3 状态详表

| 状态 | 视觉表现 |
|------|---------|
| **未登录** | 不渲染 |
| **已登录，0 未读** | `MessageCircle` icon（`h-5 w-5 text-slate-500`），无 badge |
| **已登录，1–99 未读** | icon + 右上角红色圆形 badge，显示数字 |
| **已登录，100+ 未读** | icon + badge 显示 "99+" |
| **hover** | icon `text-slate-700`，`transition-colors` |
| **loading** | icon 正常显示，badge 不显示直到数据返回 |
| **fetch 失败** | icon 正常显示，badge 不显示（静默失败） |

### 10.4 Badge 样式

```
<span className="absolute -top-1 -right-1 flex items-center justify-center
                 min-w-[18px] h-[18px] rounded-full
                 bg-red-500 text-white text-[10px] font-bold
                 px-1">
  {count > 99 ? '99+' : count}
</span>
```

### 10.5 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击 icon | `router.push('/messages')` |
| 已在 `/messages` 页面 | 不重复跳转 |

### 10.6 未读数刷新策略

| 事件 | 动作 |
|------|------|
| 组件挂载 | 调用 `GET /api/conversations/unread-count` |
| 页面可见性变化（`visibilitychange`） | 重新获取 |
| 进入对话页标记已读后 | 乐观更新计数 |
| 定时轮询 | 每 60 秒轮询一次 |

---

## 11. 路由守卫（middleware.ts 变更）

`/messages` 需加入 `PROTECTED_PAGES`：

```ts
const PROTECTED_PAGES = ["/posts/create", "/profile", "/notifications", "/messages"];
```

未登录用户访问 → 重定向到 `/login`。

---

## 12. 响应式规则

### 会话列表页 `/messages`

| 断点 | 布局变化 |
|------|---------|
| **Mobile**（< 768px） | 容器 `px-8`，头像 `h-10 w-10`（40px），标题 `text-2xl`，卡片 `p-3 gap-3` |
| **Tablet**（768px–1024px） | 容器 `px-12`，头像 `h-12 w-12`（48px），完整布局 |
| **Desktop**（> 1024px） | 容器 `px-16`，同 Tablet |

### 对话详情页 `/messages/[conversationId]`

| 断点 | 布局变化 |
|------|---------|
| **Mobile**（< 768px） | 气泡 `max-w-[85%]`，输入区 `px-4`，顶部栏 `px-4` |
| **Tablet+**（≥ 768px） | 气泡 `max-w-[75%]`，输入区 `px-6`，顶部栏 `px-6` |

---

## 13. 无障碍规格

| 元素 | 无障碍要求 |
|------|-----------|
| 消息区域 `<main>` | `role="log"` + `aria-live="polite"` + `aria-label="Conversation with {nickname}"` |
| 单条消息气泡 | 无需额外 role（文本即内容） |
| 已读标记 `CheckCheck` | `aria-label="Read"` |
| 未读标记（无 CheckCheck） | `aria-label="Unread"` 或不标注（视觉差异足够） |
| 发送按钮 | `aria-label="Send message"` |
| 输入框 | `aria-label="Message input"` + `placeholder` |
| 对方头像 | `alt="{nickname}'s avatar"` |
| 默认占位头像 | `aria-hidden="true"` |
| 会话卡片 | `aria-label` 包含对方昵称和未读数 |
| 未读 badge | `aria-hidden="true"`（通过父元素 aria-label 传达） |
| 日期分隔线 | `role="separator"` + `aria-label="{dateLabel}"` |
| "Beginning of conversation" | `role="status"` |
| Loading 骨架 | `aria-busy="true"` |
| Error 状态 | `role="alert"` |
| 频率限制提示 | `role="alert"` |

---

## 14. 组件清单

| 组件 | 文件路径 | 类型 | 说明 |
|------|---------|------|------|
| `MessagesPage` | `app/messages/page.tsx` | Client Component | 会话列表页 |
| `ConversationPage` | `app/messages/[conversationId]/page.tsx` | Client Component | 对话详情页 |
| `ConversationCard` | `app/messages/_components/ConversationCard.tsx` | Client Component | 会话卡片 |
| `MessageBubble` | `app/messages/_components/MessageBubble.tsx` | 纯展示 | 消息气泡 |
| `MessageInput` | `app/messages/_components/MessageInput.tsx` | Client Component | 底部输入框 |
| `DateSeparator` | `app/messages/_components/DateSeparator.tsx` | 纯展示 | 日期分隔线 |
| `MessageIcon` | `app/_components/MessageIcon.tsx` | Client Component | 导航栏消息 icon + badge |

---

## 15. 错误状态全景

| 场景 | 来源 | 前端处理 |
|------|------|---------|
| 获取会话列表网络失败 | API `network_error` | Error 态 Card + Retry 按钮 |
| 获取会话列表服务端失败 | API 500 | Error 态 Card + Retry 按钮 |
| 获取消息历史失败 | API error | 消息区 Error + Retry + 输入框 disabled |
| 加载更多历史消息失败 | API error | 顶部 "Failed to load" + Retry 链接 |
| 发送消息失败（网络） | API `network_error` | toast "Failed to send. Please try again." + 输入框恢复 |
| 发送消息失败（校验） | API 422 `validation_error` | toast 具体错误 + 输入框恢复 |
| 发送消息频率限制 | API 429 `rate_limited` | 输入框下方黄色提示 + 按钮 disabled + 30s 倒计时恢复 |
| 发送消息时对方已删除 | API 422 | toast "This user is no longer available" + 输入框永久 disabled |
| 发起对话时对方已删除 | API 422 | toast "This user is no longer available" + 不跳转 |
| 发起对话网络失败 | API `network_error` | toast "Failed to start conversation" |
| 会话不存在 / 无权访问 | API 403 / 404 | `notFound()` 或 redirect 到 `/messages` |
| 获取未读消息总数失败 | API error | icon badge 不显示（静默失败） |
| JWT 过期 | API 401 | auth store 清除状态，重定向 `/login` |
| 未登录访问 `/messages` | middleware 重定向 | 跳转 `/login` |
| 消息内容 XSS | 用户输入 | 后端 HTML 转义存储，前端纯文本渲染 |
| 消息超 2000 字符 | 前端限制 | 字符计数 `text-red-500` + 禁止继续输入 + 发送按钮 disabled |

---

## 16. 数据流与状态管理

### 16.1 Zustand Store 建议

```
stores/messages.ts
├── totalUnread: number               ← 所有会话未读消息总数
├── setTotalUnread(count)
├── decrementUnread(conversationId, count)  ← 进入对话后减少
├── fetchTotalUnread()                ← 调用 API 刷新
└── resetUnread()                     ← 全部标记后归零
```

### 16.2 会话列表页状态

```
MessagesPage
├── conversations: Conversation[]      ← 会话列表
├── isLoading: boolean                 ← 首次加载
├── error: string | null               ← 加载错误
└── navigate(conversationId)           ← router.push
```

### 16.3 对话详情页状态

```
ConversationPage
├── messages: Message[]                ← 当前已加载的消息
├── partner: UserInfo                  ← 对方用户信息
├── partnerDeleted: boolean            ← 对方是否已删除
├── hasMore: boolean                   ← 是否有更多历史消息
├── isLoading: boolean                 ← 首次加载
├── isLoadingMore: boolean             ← 加载更多历史
├── error: string | null               ← 首次加载错误
├── loadMoreError: string | null       ← 加载更多错误
├── isSending: boolean                 ← 正在发送消息
├── sendError: string | null           ← 发送错误
├── rateLimited: boolean               ← 是否被频率限制
├── charCount: number                  ← 输入框字符数
├── inputText: string                  ← 输入框文本
├── sendMessage(content)               ← 乐观追加 + 调 API
└── loadMore()                         ← 滚动加载更多
```

