# 消息通知（Notifications）交互规格

## 1. 页面概览

| 路由 | 组件类型 | 守卫 | 说明 |
|------|---------|------|------|
| `/notifications` | Client Component | 需登录 | 通知列表页（分页 + 已读/未读） |

**共享组件**：

| 组件 | 位置 | 说明 |
|------|------|------|
| `NotificationBell` | 导航栏右侧 | Bell icon + 未读 badge |

---

## 2. `/notifications` — 通知列表页

### 2.1 页面结构

```
<div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
  <div className="mx-auto max-w-3xl px-8 py-16 sm:px-12 lg:px-16">

    <!-- 页面头部 -->
    <div className="flex items-center justify-between mb-10">
      <div>
        <h1 className="text-3xl font-bold text-slate-900 lg:text-4xl">Notifications</h1>
        <p className="mt-2 text-base text-slate-500">Stay updated on interactions with your content</p>
      </div>
      <Button variant="outline" size="sm" disabled={unreadCount === 0}>
        <CheckCheck /> Mark all as read
      </Button>
    </div>

    <!-- 通知列表 -->
    <div className="space-y-1" role="list">
      {notifications.map(n => <NotificationItem />)}
    </div>

    <!-- 加载更多 -->
    {hasMore && <LoadMoreIndicator />}

  </div>
</div>
```

### 2.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | 首次加载通知数据 | 6 行通知骨架：每行 = 圆形头像骨架（32px）+ 2 行文字骨架（宽度随机 60%–90%）+ 右侧短骨架（时间） |
| **Content** | 有通知数据 | 渲染通知条目列表 |
| **Empty** | 通知列表为空（0 条通知） | Card 居中：`BellOff` icon（48px，`text-slate-300`）+ "No notifications yet" (`text-lg font-medium text-slate-900`) + "When someone interacts with your content, you'll see it here." (`text-sm text-slate-500`) |
| **Error** | API 请求失败 | Card 居中：`AlertCircle` icon（48px，`text-destructive`）+ "Unable to load notifications" (`text-lg font-medium text-slate-900`) + "Retry" Button |

### 2.3 Loading 骨架详细规格

```
<div className="flex items-center gap-3 p-4">
  <Skeleton className="h-8 w-8 rounded-full shrink-0" />        ← 触发者头像
  <div className="flex-1 space-y-2">
    <Skeleton className="h-4 w-[80%]" />                         ← 通知文案
    <Skeleton className="h-3 w-[40%]" />                         ← 时间
  </div>
</div>
× 6 条
```

### 2.4 Empty 状态详细规格

```
<Card className="p-12 shadow-sm border border-slate-200 text-center">
  <BellOff className="mx-auto h-12 w-12 text-slate-300" />
  <h2 className="mt-4 text-lg font-medium text-slate-900">No notifications yet</h2>
  <p className="mt-2 text-sm text-slate-500">
    When someone interacts with your content, you'll see it here.
  </p>
</Card>
```

### 2.5 Error 状态详细规格

```
<Card className="p-12 shadow-sm border border-slate-200 text-center">
  <AlertCircle className="mx-auto h-12 w-12 text-destructive" />
  <h2 className="mt-4 text-lg font-medium text-slate-900">Unable to load notifications</h2>
  <p className="mt-2 text-sm text-slate-500">Please check your connection and try again.</p>
  <Button variant="outline" className="mt-4" onClick={retry}>
    <RefreshCw /> Retry
  </Button>
</Card>
```

---

## 3. NotificationItem 组件

### 3.1 组件概述

- 用途：单条通知条目
- 类型：Client Component（需交互：点击标记已读 + 跳转）

### 3.2 Props 定义

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | `string` | ✅ | 通知 ID |
| `actor` | `{ nickname: string; avatar_url: string \| null; username: string }` | ✅ | 触发者信息（deleted 用户 nickname 为 "Deleted user"） |
| `type` | `"post_liked" \| "post_commented" \| "comment_replied" \| "post_bookmarked"` | ✅ | 通知类型 |
| `entity_id` | `string \| null` | ❌ | 关联内容 ID |
| `content_preview` | `string \| null` | ❌ | 内容摘要 |
| `target_title` | `string \| null` | ❌ | 目标内容标题 |
| `read` | `boolean` | ✅ | 是否已读 |
| `created_at` | `string` (ISO 8601) | ✅ | 通知创建时间 |

### 3.3 通知条目布局

```
<div className="flex items-start gap-3 p-4 rounded-lg cursor-pointer transition-colors
                hover:bg-slate-50
                {unread ? 'bg-blue-50/40' : 'bg-transparent'}">

  <!-- 未读指示条 -->
  {unread && <div className="absolute left-0 top-2 bottom-2 w-0.5 rounded-full bg-blue-700" />}

  <!-- 触发者头像 -->
  <Avatar className="h-8 w-8 rounded-full shrink-0" />

  <!-- 通知内容 -->
  <div className="flex-1 min-w-0">
    <p className={`text-sm ${unread ? 'font-semibold text-slate-900' : 'font-normal text-slate-700'}`}>
      <span className="font-medium">{actor.nickname}</span>
      {" "}{actionText}{" "}
      <span className="font-medium">{target_title}</span>
    </p>

    <!-- 内容预览（评论/回复时展示） -->
    {content_preview && (
      <p className="mt-0.5 text-xs text-slate-500 truncate">{content_preview}</p>
    )}

    <!-- 时间 -->
    <p className="mt-1 text-xs text-slate-400">{relativeTime}</p>
  </div>

  <!-- 通知类型图标（可选） -->
  <NotificationTypeIcon type={type} />
</div>
```

### 3.4 通知文案映射

| type | actionText | 完整示例 |
|------|-----------|---------|
| `post_liked` | "liked your post" | "Alice liked your post Chengdu Food Guide" |
| `post_commented` | "commented on your post" | "Bob commented on your post Chengdu Food Guide" |
| `comment_replied` | "replied to your comment on" | "Carol replied to your comment on Chengdu Food Guide" |
| `post_bookmarked` | "bookmarked your post" | "Dave bookmarked your post Chengdu Food Guide" |

### 3.5 通知类型图标

| type | icon (lucide-react) | 颜色 |
|------|-------------------|------|
| `post_liked` | `Heart` | `text-rose-400` |
| `post_commented` | `MessageCircle` | `text-blue-400` |
| `comment_replied` | `Reply` | `text-blue-400` |
| `post_bookmarked` | `Bookmark` | `text-amber-400` |

图标尺寸：`h-4 w-4`，放在通知条目右侧。

### 3.6 相对时间显示规则

| 时间差 | 显示 |
|--------|------|
| < 1 分钟 | "just now" |
| 1–59 分钟 | "{n}m ago" |
| 1–23 小时 | "{n}h ago" |
| 1–6 天 | "{n}d ago" |
| 7–29 天 | "{n}w ago" |
| ≥ 30 天 | 显示日期 "Jun 18" |

### 3.7 组件状态详表

| 状态 | 视觉差异 |
|------|---------|
| **unread** | 背景 `bg-blue-50/40`，左侧蓝色竖线（`w-0.5 bg-blue-700`），文案 `font-semibold text-slate-900` |
| **read** | 背景 `bg-transparent`，无左侧竖线，文案 `font-normal text-slate-700` |
| **hover** | `hover:bg-slate-50`（read 态）/ `hover:bg-blue-50/60`（unread 态） |
| **active** (点击中) | `active:bg-slate-100` |
| **actor deleted** | 头像显示默认占位（`User` icon），昵称显示 "Deleted user"（`text-slate-400 italic`） |
| **target deleted** | target_title 显示 "Deleted content"（`text-slate-400 line-through`），点击不跳转 |
| **content_preview 存在** | 通知文案下方额外展示一行截断预览文本 |
| **content_preview 不存在** | 仅展示主文案 + 时间 |

### 3.8 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击 **unread** 通知条目 | ① 调用 `markAsRead(id)` API ② 该条目立即切换为 read 视觉态（乐观更新）③ 导航栏 badge 计数 -1（乐观更新）④ `router.push(targetUrl)` |
| 点击 **read** 通知条目 | ① 直接 `router.push(targetUrl)` |
| 点击 **target 已删除**的通知 | ① 标记已读 ② toast 提示 "This content has been removed" ③ 不跳转 |
| 键盘 `Enter` / `Space` 聚焦条目 | 同点击行为 |
| 通知条目获得焦点 | `focus-visible:ring-2 focus-visible:ring-ring` |

### 3.9 跳转目标 URL 映射

| type | entity_id 含义 | targetUrl |
|------|---------------|-----------|
| `post_liked` | 帖子 ID | `/posts/{entity_id}` |
| `post_commented` | 帖子 ID | `/posts/{entity_id}#comments` |
| `comment_replied` | 评论所属帖子 ID | `/posts/{entity_id}#comments` |
| `post_bookmarked` | 帖子 ID | `/posts/{entity_id}` |

---

## 4. "Mark all as read" 操作

### 4.1 按钮状态

| 状态 | 视觉表现 |
|------|---------|
| **enabled**（有未读通知） | `variant="outline"` + 文案 "Mark all as read" + `CheckCheck` icon |
| **disabled**（无未读通知） | 按钮 `disabled` 态（`opacity-50 cursor-not-allowed`） |
| **submitting** | 按钮 `disabled` + `<Loader2 />` 旋转 + "Marking..." |
| **success** | 所有条目切换为 read 态 + toast "All notifications marked as read" + badge 归零 |
| **error** | toast 错误提示 "Failed to mark all as read" + 按钮恢复可用 |

### 4.2 交互流

```
用户点击 "Mark all as read"
  → 按钮进入 submitting 态
  → 调用 POST /api/notifications/mark-all-read
  → 成功：
      ① 所有条目乐观更新为 read 态（移除蓝色竖线、取消加粗、背景变透明）
      ② 导航栏 badge 归零
      ③ toast 成功提示
      ④ 按钮 disabled（因为已无未读）
  → 失败：
      ① toast 错误提示
      ② 按钮恢复 enabled
```

---

## 5. 分页加载

### 5.1 加载机制

- 每页 20 条
- 滚动到列表底部时自动加载下一页（Intersection Observer）
- 使用 `page` 参数分页：`GET /api/notifications?page=1&size=20`

### 5.2 加载更多状态

| 状态 | 视觉表现 |
|------|---------|
| **hasMore = true，未触发加载** | 列表底部不显示任何内容（等待滚动触发） |
| **loading more** | 列表底部居中 `<Loader2 />` 旋转 + "Loading more..." (`text-sm text-slate-400`) |
| **hasMore = false**（最后一页） | 列表底部无额外内容 |
| **load more error** | 列表底部居中 "Failed to load more" + "Retry" 链接按钮 (`text-sm text-blue-700 hover:text-blue-800`) |

### 5.3 加载更多规格

```
{/* 列表末尾 */}
{isLoadingMore && (
  <div className="flex items-center justify-center gap-2 py-6">
    <Loader2 className="h-4 w-4 animate-spin text-slate-400" />
    <span className="text-sm text-slate-400">Loading more...</span>
  </div>
)}

{loadMoreError && (
  <div className="flex items-center justify-center gap-2 py-6">
    <span className="text-sm text-slate-500">Failed to load more.</span>
    <button onClick={retryLoadMore} className="text-sm font-medium text-blue-700 hover:text-blue-800">
      Retry
    </button>
  </div>
)}
```

---

## 6. NotificationBell — 导航栏通知入口

### 6.1 组件概述

- 用途：导航栏右上角通知铃铛，展示未读计数
- 类型：Client Component（需轮询未读数 + 点击跳转）

### 6.2 位置

导航栏右侧，位于用户头像下拉菜单**左侧**（如果个人中心模块已实现 UserDropdown）。

### 6.3 状态详表

| 状态 | 视觉表现 |
|------|---------|
| **未登录** | 不渲染 |
| **已登录，0 未读** | Bell icon（`h-5 w-5 text-slate-500`），无 badge |
| **已登录，1–9 未读** | Bell icon + 右上角红色圆形 badge（`min-w-[18px] h-[18px]`），显示数字 |
| **已登录，10–99 未读** | Bell icon + badge，数字正常显示 |
| **已登录，100+ 未读** | Bell icon + badge，显示 "99+" |
| **hover** | icon 变为 `text-slate-700`，`transition-colors` |
| **loading 未读数** | Bell icon 正常显示（不阻塞渲染），badge 不显示直到数据返回 |
| **fetch 失败** | Bell icon 正常显示，badge 不显示（静默失败，不影响用户体验） |

### 6.4 Badge 样式

```
<span className="absolute -top-1 -right-1 flex items-center justify-center
                 min-w-[18px] h-[18px] rounded-full
                 bg-red-500 text-white text-[10px] font-bold
                 px-1">
  {count > 99 ? '99+' : count}
</span>
```

Bell 容器需 `relative` 定位。

### 6.5 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击 bell icon | `router.push('/notifications')` |
| 已在 `/notifications` 页面 | 不重复跳转（可通过 `pathname` 判断） |

### 6.6 未读数刷新策略

| 事件 | 动作 |
|------|------|
| 组件挂载 | 调用 `GET /api/notifications/unread-count` |
| 页面可见性变化（`visibilitychange`） | 重新获取未读数 |
| `markAsRead` / `markAllRead` 操作后 | 乐观更新计数（不发请求） |
| 定时轮询 | 每 60 秒轮询一次（`setInterval`） |

---

## 7. 路由守卫（middleware.ts 变更）

`/notifications` 需加入 `PROTECTED_PAGES`：

```ts
const PROTECTED_PAGES = ["/posts/create", "/profile", "/notifications"];
```

未登录用户访问 → 重定向到 `/login`。

---

## 8. 响应式规则

| 断点 | 通知列表页变化 |
|------|-------------|
| **Mobile**（< 768px） | 容器 `px-8`，头像 `h-7 w-7`（28px），通知文案 `text-[13px]`，标题行省略为 "Notifications"（无副标题），"Mark all as read" 缩为 icon-only + `aria-label` |
| **Tablet**（768px–1024px） | 容器 `px-12`，头像 `h-8 w-8`（32px），完整布局 |
| **Desktop**（> 1024px） | 容器 `px-16`，同 Tablet |

### Mobile 头部适配

```
{/* Mobile: 紧凑头部 */}
<div className="flex items-center justify-between mb-6">
  <h1 className="text-2xl font-bold text-slate-900">Notifications</h1>
  <Button variant="ghost" size="icon" disabled={unreadCount === 0} aria-label="Mark all as read">
    <CheckCheck className="h-4 w-4" />
  </Button>
</div>

{/* Tablet+: 完整头部 */}
<div className="hidden md:flex items-center justify-between mb-10">
  <div>
    <h1 className="text-3xl font-bold text-slate-900 lg:text-4xl">Notifications</h1>
    <p className="mt-2 text-base text-slate-500">Stay updated on interactions with your content</p>
  </div>
  <Button variant="outline" size="sm" disabled={unreadCount === 0}>
    <CheckCheck className="h-4 w-4 mr-1" /> Mark all as read
  </Button>
</div>
```

---

## 9. 无障碍规格

| 元素 | 无障碍要求 |
|------|-----------|
| 通知列表容器 | `role="list"` + `aria-label="Notifications"` |
| 单条通知 | `role="listitem"` + `tabIndex={0}` + `aria-label` 包含完整通知文案 |
| 未读通知 | 额外 `aria-label` 前缀 "(unread)" |
| Bell icon 按钮 | `aria-label="Notifications"` + 有未读时 `aria-label="Notifications, {count} unread"` |
| Badge | `aria-hidden="true"`（屏幕阅读器通过 bell 的 aria-label 获取信息） |
| "Mark all as read" 按钮 | `aria-label="Mark all notifications as read"` |
| Loading 骨架 | `aria-busy="true"` + `aria-label="Loading notifications"` |
| Empty 状态 | `role="status"` |
| Error 状态 | `role="alert"` |

---

## 10. 组件清单

| 组件 | 文件路径 | 类型 | 说明 |
|------|---------|------|------|
| `NotificationsPage` | `app/notifications/page.tsx` | Client Component | 通知列表页（含分页 + 状态管理） |
| `NotificationItem` | `app/notifications/_components/NotificationItem.tsx` | Client Component | 单条通知条目 |
| `NotificationBell` | `app/_components/NotificationBell.tsx` | Client Component | 导航栏 bell icon + badge |
| `NotificationTypeIcon` | `app/notifications/_components/NotificationTypeIcon.tsx` | 纯展示 | 通知类型小图标 |

---

## 11. 错误状态全景

| 场景 | 来源 | 前端处理 |
|------|------|---------|
| 获取通知列表网络失败 | API `network_error` | Error 态 Card + Retry 按钮 |
| 获取通知列表服务端失败 | API 500 | Error 态 Card + Retry 按钮 |
| 加载更多失败 | API error | 列表底部 "Failed to load more" + Retry 链接 |
| 标记单条已读失败 | API error | toast "Failed to update notification" + 条目恢复 unread 态（回滚乐观更新） |
| 标记全部已读失败 | API error | toast "Failed to mark all as read" + 按钮恢复 enabled |
| 获取未读计数失败 | API error | Bell badge 不显示（静默失败） |
| 跳转目标已删除 | `router.push` 后页面 404 或 API 返回 content_deleted | toast "This content has been removed"，不跳转 |
| 触发者已删除 | actor 数据标记 deleted | 显示 "Deleted user" + 默认头像 |
| JWT 过期 | API 401 | auth store 清除状态，重定向 `/login` |
| 未登录访问 `/notifications` | middleware 重定向 | 跳转 `/login` |

---

## 12. 数据流与状态管理

### 12.1 Zustand Store 建议

```
stores/notifications.ts
├── unreadCount: number
├── setUnreadCount(count)
├── decrementUnread()          ← 单条标记已读后 -1
├── resetUnread()              ← 全部标记已读后归零
└── fetchUnreadCount()         ← 调用 API 刷新
```

### 12.2 页面级状态

```
NotificationsPage
├── notifications: Notification[]    ← 当前已加载的通知列表
├── page: number                     ← 当前页码
├── hasMore: boolean                 ← 是否还有下一页
├── isLoading: boolean               ← 首次加载
├── isLoadingMore: boolean           ← 加载更多
├── error: string | null             ← 首次加载错误
├── loadMoreError: string | null     ← 加载更多错误
├── isMarkingAll: boolean            ← 标记全部已读中
└── markAsRead(id)                   ← 乐观更新单条 + 调 API
```
