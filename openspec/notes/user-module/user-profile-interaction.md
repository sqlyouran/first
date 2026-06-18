# 个人中心（User Profile）交互规格

## 1. 页面概览

| 路由 | 组件类型 | 守卫 | 说明 |
|------|---------|------|------|
| `/profile` | Server Component (SSR) | 需登录 | 当前用户资料展示 |
| `/profile/edit` | Client Component | 需登录 | 资料编辑表单 |
| `/users/[username]` | Server Component (SSR) | 公开 | 他人公开资料页 |

---

## 2. `/profile` — 我的资料页

### 2.1 页面结构

```
<div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
  <div className="mx-auto max-w-3xl px-8 py-16 sm:px-12 lg:px-16">

    <!-- 返回导航（可选） -->

    <!-- 头像区 -->
    <div className="flex flex-col items-center text-center">
      <Avatar />              ← 96px 圆形头像
      <h1 />                  ← 昵称
      <p />                   ← @username
      <p />                   ← 个人简介
      <div />                 ← 兴趣标签 Badge 列表
      <p />                   ← Member since（注册时间）
    </div>

    <!-- 操作区 -->
    <div className="mt-8 flex justify-center">
      <Button>Edit Profile</Button>  → 跳转 /profile/edit
    </div>

  </div>
</div>
```

### 2.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | SSR 请求用户数据中 | Card 内 Skeleton 组合：圆形头像骨架 + 3 行文字骨架 + 标签骨架 |
| **Content** | 用户已有资料 | 完整渲染头像、昵称、@username、简介、标签列表、注册时间 |
| **Empty** | 用户首次注册，资料未填写 | 默认占位头像（`User` icon）+ 提示文案 "Complete your profile to let others know you" + CTA 按钮 "Edit Profile" |
| **Error** | API 请求失败（网络/服务端） | Card 内居中错误图标 + "Unable to load profile" + "Retry" 按钮 |

### 2.3 组件状态详表

#### 头像区

| 场景 | 头像来源 | fallback |
|------|---------|----------|
| 已设置 avatar_url | `<img src={avatar_url}>` | img `onError` → 默认占位 |
| 未设置 avatar_url | 默认占位：`bg-gradient-to-br from-blue-50 via-slate-50 to-blue-100` + 居中 `User` icon (lucide) | — |

头像尺寸：`h-24 w-24`（96px），圆形 `rounded-full`，带 `ring-2 ring-white shadow-md`

#### 昵称显示

| 场景 | 显示 |
|------|------|
| 已设置 nickname | 昵称文本，`text-2xl font-bold text-slate-900` |
| 未设置 nickname | "Set your nickname" 灰色斜体占位，`text-xl text-slate-400 italic` |

#### username 显示

始终显示 `@username`，`text-sm text-slate-500`。若未设置 username（首次未编辑资料），显示为 `@—`。

#### 简介显示

| 场景 | 显示 |
|------|------|
| 已设置 bio | 简介文本，`text-sm text-slate-600 max-w-md`，最多显示 500 字符 |
| 未设置 bio | 不显示该区域（不留空白） |

#### 兴趣标签显示

- 使用 `<Badge variant="secondary">` 渲染每个标签
- 标签容器：`flex flex-wrap justify-center gap-2`
- 未设置标签时不显示该区域

#### 注册时间

- 格式：`Member since · {month} {year}`（如 "Member since · June 2026"）
- 样式：`text-xs text-slate-400 mt-2`

### 2.4 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 点击 "Edit Profile" | `router.push('/profile/edit')` |
| 头像加载失败 | `onError` → 替换为默认占位头像 |

---

## 3. `/profile/edit` — 编辑资料页

### 3.1 页面结构

```
<div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
  <div className="mx-auto max-w-3xl px-8 py-16 sm:px-12 lg:px-16">

    <!-- 返回导航 -->
    <Link href="/profile"><ArrowLeft /> Back to Profile</Link>

    <!-- 标题 -->
    <h1>Edit Profile</h1>
    <p>Customize how others see you on WanderChina</p>

    <!-- 单卡片表单 -->
    <Card className="p-8 shadow-sm border border-slate-200">
      <form className="space-y-6">

        <!-- 头像预览 + URL 输入 -->
        <!-- Username 输入（或只读） -->
        <!-- Nickname 输入 -->
        <!-- Bio 文本域 -->
        <!-- Interest Tags 选择器 -->
        <!-- 服务端错误提示 -->
        <!-- 提交按钮 -->

      </form>
    </Card>
  </div>
</div>
```

### 3.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | 页面初始加载，获取当前资料 | Card 内 Skeleton：头像骨架 + 5 行表单骨架 + 按钮骨架 |
| **Content** | 资料加载成功 | 渲染完整表单，预填已有数据 |
| **Empty** | — | 不适用（表单本身即"空"状态，字段为空时显示 placeholder） |
| **Error** | 加载资料失败 | Card 内错误提示 + "Retry" 按钮 |

### 3.3 表单字段详表

#### 3.3.1 头像预览区

```
<div className="flex flex-col items-center gap-4">
  <AvatarPreview />         ← 80px 圆形实时预览
  <div className="w-full">
    <label>Avatar URL</label>
    <Input placeholder="https://example.com/photo.jpg" />
    <p className="text-xs text-slate-400 mt-1">Paste an image URL. Leave empty for default avatar.</p>
  </div>
</div>
```

| 状态 | 头像预览表现 |
|------|-------------|
| URL 为空 | 默认占位头像（同 `/profile`） |
| URL 有效 | 渲染 `<img>` 实时预览 |
| URL 无效/加载失败 | `onError` → 回退默认占位头像 |

#### 3.3.2 Username 字段

| 状态 | 表现 |
|------|------|
| **首次设置**（username 为 null） | 可编辑 Input + 黄色提示 "This will be your permanent profile URL and cannot be changed" + 实时校验指示 |
| **已设置** | Input 显示为 `disabled` + `bg-slate-50`，下方灰色提示 "Your username cannot be changed" |

**实时校验规则**（首次设置时）：

| 条件 | 提示 |
|------|------|
| 空 | 红色 "Username is required" |
| < 3 字符 | 红色 "Must be at least 3 characters" |
| > 20 字符 | 红色 "Must be at most 20 characters" |
| 含非法字符 | 红色 "Only letters, numbers, hyphens and underscores" |
| 合法 | 绿色勾号 + "Looks good!" |

正则：`/^[a-zA-Z0-9_-]+$/`

#### 3.3.3 Nickname 字段

```
<label className="text-sm font-medium text-slate-700">
  Nickname <span className="text-red-500">*</span>
</label>
<Input placeholder="Your display name" maxLength={30} />
```

| 状态 | 提示 |
|------|------|
| 空 | 红色 "Nickname is required" |
| 纯空格 | 红色 "Nickname cannot be blank" |
| < 2 字符 | 红色 "Must be at least 2 characters" |
| > 30 字符 | Input maxLength 限制，下方计数器 "30/30" |
| 合法 | 无额外提示 |

字符计数：右下角 `text-xs text-slate-400`，格式 `{current}/30`

#### 3.3.4 Bio 文本域

```
<label>Bio</label>
<Textarea placeholder="Tell others about your travel interests..." maxLength={500} rows={4} />
<p className="text-xs text-slate-400">{current}/500</p>
```

| 状态 | 提示 |
|------|------|
| 空 | 无提示（选填字段） |
| 接近上限（> 450） | 计数器变为 `text-amber-500` |
| 达到上限 | 计数器 `text-red-500`，禁止继续输入 |

#### 3.3.5 Interest Tags 选择器

```
<label>Interest Tags</label>
<p className="text-sm text-slate-500">Select up to 10 tags that match your interests</p>

<!-- 按类别分组展示 -->
<div className="space-y-4">
  {categories.map(cat => (
    <div>
      <p className="text-xs font-medium text-slate-500 uppercase">{cat.name}</p>
      <div className="flex flex-wrap gap-2 mt-1">
        {cat.tags.map(tag => <TagChip />)}
      </div>
    </div>
  ))}
</div>
<p className="text-xs text-slate-400">{selectedCount}/10 selected</p>
```

**TagChip 组件状态**：

| 状态 | 视觉表现 | Tailwind |
|------|---------|----------|
| **unselected** | 白色背景 + 灰色边框，可点击 | `bg-white border border-slate-200 text-slate-700 hover:border-blue-300 hover:bg-blue-50 cursor-pointer transition-colors` |
| **selected** | 蓝色填充，白色文字 | `bg-blue-700 text-white border-blue-700 cursor-pointer transition-colors` |
| **disabled**（已达 10 个上限且未选中） | 灰色背景，不可点击 | `bg-slate-50 text-slate-300 border-slate-100 cursor-not-allowed` |

点击行为：
- unselected → 加入已选（若 < 10）
- selected → 移除选择
- disabled → 无响应

### 3.4 表单提交状态

| 状态 | 提交按钮表现 | 表单行为 |
|------|-------------|---------|
| **idle** | "Save Changes"，`bg-blue-700 hover:bg-blue-800 text-white w-full` | 可提交 |
| **submitting** | `<Loader2 />` 旋转 + "Saving..."，`disabled` | 所有字段 disabled |
| **success** | toast 通知 "Profile updated"（via `sonner`） | 自动跳转 `/profile` |
| **server_error** | 表单顶部显示错误条 `text-sm text-destructive`，按钮恢复可用 | 可重试 |

**服务端错误映射**：

| HTTP Status | error_code | 展示文案 |
|------------|------------|---------|
| 409 | `username_taken` | "This username is already taken" （聚焦到 username 字段） |
| 422 | `validation_error` | 解析 `details` 映射到对应字段下方 |
| 500 | `internal_error` | "Something went wrong. Please try again." |
| — | `network_error` | "Network error. Please check your connection." |

### 3.5 表单校验时机

| 事件 | 校验范围 |
|------|---------|
| `onBlur`（单字段失焦） | 校验当前字段 |
| `onChange`（username 首次设置时） | 实时校验 username 格式 |
| `onSubmit` | 校验全部字段 |

### 3.6 导航行为

| 操作 | 目标 |
|------|------|
| 点击 "← Back to Profile" | `router.push('/profile')` |
| 保存成功 | `router.push('/profile')` |
| 浏览器返回 | 正常返回（不做拦截） |

---

## 4. `/users/[username]` — 他人公开资料页

### 4.1 页面结构

与 `/profile` Content 态结构一致，但有以下区别：
- **无** "Edit Profile" 按钮
- **新增** "Send Message" 按钮（仅已登录用户可见）→ 跳转站内信（后续模块）
- 页面 `<title>` 为 `{nickname} (@{username}) | WanderChina`
- `<meta name="description">` 为 bio 内容（截断至 155 字符）

### 4.2 四态覆盖

| 状态 | 触发条件 | 视觉表现 |
|------|---------|---------|
| **Loading** | SSR 请求用户数据中 | 同 `/profile` Loading 骨架 |
| **Content** | 用户存在且有资料 | 完整渲染（无编辑入口） |
| **Empty** | 用户存在但资料为空 | 默认占位头像 + "This traveler hasn't set up their profile yet" |
| **Error / 404** | username 不存在 / 用户已删除 | `notFound()` → Next.js 404 页面 |

### 4.3 交互行为

| 用户操作 | 系统响应 |
|---------|---------|
| 已登录用户点击 "Send Message" | `router.push('/messages/new?to={username}')` 或跳转已有会话 |
| 未登录用户看到 "Send Message" | 按钮不可见 |
| 头像加载失败 | `onError` → 默认占位头像 |

---

## 5. 导航栏头像入口

### 5.1 组件概述

在根布局的导航栏右侧，已登录用户显示头像入口。

### 5.2 状态

| 状态 | 表现 |
|------|------|
| **未登录** | 显示 "Sign In" / "Sign Up" 链接（当前行为不变） |
| **已登录，有头像** | 显示 32px 圆形头像（`rounded-full ring-1 ring-slate-200`） |
| **已登录，无头像** | 显示默认占位：蓝色圆形 + 首字母大写（取 nickname 或 email 首字符） |

### 5.3 下拉菜单

点击头像后展开下拉菜单（使用 shadcn 的 Dropdown/Popover 或自行实现）：

```
┌─────────────────────┐
│  My Profile          │  → /profile
│  Messages            │  → /messages（后续模块）
│  Notifications       │  → /notifications（后续模块）
├─────────────────────┤
│  Sign Out            │  → 触发 logout
└─────────────────────┘
```

- 下拉菜单宽度：`w-48`
- 每项：`flex items-center gap-2 px-3 py-2 text-sm text-slate-700 hover:bg-slate-50 transition-colors rounded-md`
- 分隔线：`border-t border-slate-100`
- 关闭条件：点击菜单外区域 / 点击菜单项 / 按 Escape

---

## 6. 路由守卫（middleware.ts 变更）

`/profile` 和 `/profile/edit` 需加入 `PROTECTED_PAGES`：

```ts
const PROTECTED_PAGES = ["/posts/create", "/profile"];
```

未登录用户访问 `/profile/*` → 重定向到 `/login`。

`/users/[username]` 为公开页面，**不**加入保护列表。

---

## 7. 响应式规则

### 我的资料页 `/profile` & 他人资料页 `/users/[username]`

| 断点 | 布局变化 |
|------|---------|
| **Mobile**（< 768px） | 头像 `h-20 w-20`（80px），标题 `text-xl`，容器 `px-8` |
| **Tablet**（768px–1024px） | 头像 `h-24 w-24`（96px），标题 `text-2xl`，容器 `px-12` |
| **Desktop**（> 1024px） | 同 Tablet，容器 `px-16` |

### 编辑页 `/profile/edit`

| 断点 | 布局变化 |
|------|---------|
| **Mobile**（< 768px） | Card `p-5`，标签分组单列 |
| **Tablet+**（≥ 768px） | Card `p-8`，标签分组可多列 |

---

## 8. 无障碍规格

| 元素 | 无障碍要求 |
|------|-----------|
| 头像 `<img>` | `alt="{nickname}'s avatar"` 或 `alt="Default avatar"` |
| 默认占位头像容器 | `aria-hidden="true"`（装饰性） |
| 表单 `<Input>` / `<Textarea>` | 每个字段关联 `<label htmlFor>`，错误时 `aria-invalid="true"` + `aria-describedby` 指向错误文本 |
| TagChip | `role="checkbox"` + `aria-checked={selected}` + `aria-label` |
| 提交按钮（loading 态） | `aria-busy="true"` + `disabled` |
| 错误提示 | `role="alert"` |

---

## 9. 组件清单

| 组件 | 文件路径 | 类型 | 说明 |
|------|---------|------|------|
| `ProfilePage` | `app/profile/page.tsx` | Server Component | 我的资料页 |
| `ProfileEditPage` | `app/profile/edit/page.tsx` | Client Component | 编辑资料页 |
| `PublicProfilePage` | `app/users/[username]/page.tsx` | Server Component | 他人公开资料页 |
| `AvatarDisplay` | `app/profile/_components/AvatarDisplay.tsx` | Client Component | 头像展示（含 onError fallback） |
| `TagSelector` | `app/profile/_components/TagSelector.tsx` | Client Component | 兴趣标签选择器 |
| `ProfileForm` | `app/profile/_components/ProfileForm.tsx` | Client Component | 编辑表单（含校验逻辑） |
| `UserDropdown` | `app/_components/UserDropdown.tsx` | Client Component | 导航栏头像+下拉菜单 |

---

## 10. 错误状态全景

以下为个人中心模块所有可能出现的错误场景及对应处理：

| 场景 | 来源 | 前端处理 |
|------|------|---------|
| 获取资料网络失败 | API `network_error` | 显示 "Network error" + Retry 按钮 |
| 获取资料服务端失败 | API 500 | 显示 "Service unavailable" + Retry 按钮 |
| username 已被占用 | API 409 `username_taken` | username 字段下方红色提示 |
| 昵称校验不通过 | API 422 `validation_error` | 对应字段下方红色提示 |
| username 格式非法 | API 422 / 前端校验 | username 字段下方红色提示 |
| 标签数超限 | API 422 / 前端限制 | Tag 选择器 disabled 态 + 提示文本 |
| 头像 URL 无效 | 前端 `onError` | fallback 默认占位图 |
| 未登录访问 `/profile` | middleware 重定向 | 跳转 `/login` |
| 用户不存在 (`/users/xxx`) | API 404 | `notFound()` → 404 页面 |
| 用户已删除 | API 404 | 同上 |
| JWT 过期 | API 401 | auth store 清除状态，重定向 `/login` |
