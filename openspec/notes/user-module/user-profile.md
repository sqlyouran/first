# 个人中心（User Profile）PRD

## 1. 背景与目标

当前 WanderChina 的用户实体（`UserEntity`）仅包含认证相关字段（email、password_hash、state），没有任何个人资料信息。用户在平台上发布帖子、评论、收藏后，无法展示个人身份，其他用户也无法识别内容创作者。

**目标**：让用户拥有可自定义的个人资料页，支持查看和编辑头像、昵称、个人简介、兴趣标签，同时为他人提供公开资料页。

## 2. 目标用户与场景

| 用户角色 | 场景 |
|---------|------|
| 已登录用户 | 注册后首次完善个人资料；随时修改头像/昵称/简介/标签 |
| 已登录用户 | 浏览他人帖子/评论时，点击头像查看对方公开资料 |
| 未登录访客 | 浏览公开资料页（只读，无编辑入口） |

## 3. 用户故事

### US-1: 查看自己的个人资料

```
As a logged-in user,
I want to view my profile page with my avatar, nickname, bio, and interest tags,
So that I can see how others perceive my identity on the platform.

Acceptance Criteria:
- Given I am logged in, When I navigate to /profile, Then I see my avatar, nickname, bio, interest tags, and member-since date
- Given I have not set any profile info, When I view my profile, Then I see default avatar placeholder and empty fields with "Edit" prompts
```

### US-2: 编辑个人资料

```
As a logged-in user,
I want to edit my avatar, nickname, bio, and interest tags,
So that I can express my travel identity and preferences.

Acceptance Criteria:
- Given I am on /profile/edit, When I update my nickname and save, Then my profile page reflects the new nickname
- Given I upload a new avatar image, When I save, Then my avatar updates across the platform (profile, comments, posts)
- Given I add interest tags (e.g., "Hiking", "Street Food"), When I save, Then the tags display on my profile
- Given I clear all optional fields and save, When I view my profile, Then only my nickname (required) is shown
```

### US-3: 查看他人公开资料

```
As any visitor (logged in or not),
I want to view another user's public profile,
So that I can learn about the author of a post or comment.

Acceptance Criteria:
- Given I click on a user's avatar/name in a post or comment, When the profile page loads, Then I see their public info: avatar, nickname, bio, interest tags, and member-since date
- Given I am viewing another user's profile, When I look at the page, Then I do NOT see their email or any private information
- Given the user does not exist, When I navigate to /users/{username}, Then I see a 404 "User not found" page
```

### US-4: 导航栏头像入口

```
As a logged-in user,
I want to access my profile from the navigation bar,
So that I can quickly view or edit my profile.

Acceptance Criteria:
- Given I am logged in, When I look at the top navigation bar, Then I see my avatar (or default placeholder) as a clickable element
- Given I click my avatar in the nav bar, When the dropdown opens, Then I see a "My Profile" link that navigates to /profile
```

### US-5: 设置用户名（username）

```
As a logged-in user who has not set a username,
I want to be prompted to set a unique username when I first edit my profile,
So that I have a stable public URL for my profile.

Acceptance Criteria:
- Given I have not set a username, When I navigate to /profile/edit, Then I see a username field marked as required with a note that it cannot be changed later
- Given I submit a valid username, When I save, Then my public profile URL becomes /users/{username}
- Given I have already set a username, When I visit /profile/edit, Then the username field is shown as read-only (non-editable)
```

## 4. 功能规格

### 4.1 核心流程

**首次完善资料流程**：
1. 用户注册后点击导航栏头像 → 进入 `/profile`
2. 页面显示空状态引导 → 点击 "Edit Profile" → 进入 `/profile/edit`
3. 设置 username（首次必填，设置后不可更改）
4. 填写昵称、头像 URL、简介、选择兴趣标签
5. 点击 "Save" → 表单校验 → 提交后端 → 成功提示 → 返回 `/profile`

**日常编辑流程**：
1. 进入 `/profile/edit` → username 字段为只读状态
2. 修改昵称/头像/简介/标签
3. 点击 "Save" → 提交 → 返回 `/profile`

### 4.2 字段规格

| 字段 | 必填 | 约束 | 公开可见 | 可修改 |
|------|------|------|---------|--------|
| 用户名 (username) | 首次编辑必填 | 3-20 字符，仅允许 `a-zA-Z0-9_-`，全局唯一 | 是 | ❌ 设置后不可更改 |
| 昵称 (nickname) | 是 | 2-30 字符，不允许纯空格，不允许 `<>"` | 是 | ✅ |
| 头像 (avatar_url) | 否 | URL 格式，最长 2048 字符；为空时显示默认占位图 | 是 | ✅ |
| 个人简介 (bio) | 否 | 最长 500 字符，纯文本 | 是 | ✅ |
| 兴趣标签 (interest_tags) | 否 | 从预定义列表中选择，最多选 10 个 | 是 | ✅ |
| 邮箱 (email) | — | 注册时已有，不可在资料页修改 | 否 | — |

### 4.3 预定义兴趣标签列表

旅行主题标签（后端维护，前端展示为可点击 chip 选择器）：

| 类别 | 标签示例 |
|------|---------|
| 户外活动 | Hiking, Cycling, Diving, Rock Climbing, Skiing |
| 文化体验 | Temples, Museums, Festivals, Traditional Arts |
| 美食 | Street Food, Tea Culture, Local Cuisine, Night Markets |
| 旅行风格 | Budget Travel, Luxury, Solo Travel, Family Travel |
| 自然 | Mountains, Beaches, Deserts, Forests, Lakes |
| 城市 | Nightlife, Shopping, Architecture, Photography |

> 共 24 个预定义标签，用户最多选择 10 个。标签列表后续可通过配置调整，无需代码变更。

### 4.4 业务规则

- **username 唯一性**：全局唯一，设置后不可更改，用于公开资料页 URL `/users/{username}`
- **昵称不要求唯一**：允许重名，显示时附带 `@username` 辅助区分
- **头像仅 URL 输入**：本期不做文件上传，用户粘贴图片 URL 即可
- **资料修改无审核**：保存后立即生效
- **注册时不强制填写资料**：资料完善不影响核心功能使用
- **兴趣标签预定义**：用户只能从系统提供的标签列表中选择

### 4.5 页面/交互说明

| 路由 | 组件类型 | 说明 |
|------|---------|------|
| `/profile` | Server Component (SSR) | 当前用户资料展示页 |
| `/profile/edit` | Client Component | 资料编辑表单页 |
| `/users/{username}` | Server Component (SSR) | 他人公开资料页 |

**编辑页表单**：
- 使用 shadcn/ui 的 Input / Textarea / Button 组件
- 兴趣标签使用 chip/tag 选择器 UI（点击选中/取消）
- username 字段：首次设置时可编辑，设置后显示为只读 + 灰色背景
- 表单校验：前端即时校验 + 后端兜底校验

**导航栏**：
- 已登录用户右上角显示头像（或默认占位图）
- 点击展开下拉菜单，包含 "My Profile" 链接

## 5. 数据需求

需在 `UserEntity` 新增字段：

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| `username` | VARCHAR(20) | UNIQUE, NULLABLE | 用户自定义 URL slug，设置后不可更改 |
| `nickname` | VARCHAR(30) | NULLABLE | 显示昵称 |
| `avatar_url` | VARCHAR(2048) | NULLABLE | 头像图片 URL |
| `bio` | VARCHAR(500) | NULLABLE | 个人简介 |
| `interest_tags` | TEXT | NULLABLE | JSON array of strings，预定义标签子集 |

## 6. 非功能需求

- **SEO**：公开资料页 `/users/{username}` 支持 SSR，包含 `<title>` 和 `<meta description>`
- **无障碍**：表单字段有 `<label>` 关联，头像有 `alt` 文本
- **性能**：资料页 SSR 首屏加载 < 2s
- **安全**：所有用户输入做 XSS 过滤（HTML 转义），前端不使用 `dangerouslySetInnerHTML`

## 7. 验收标准

- [ ] 已登录用户可访问 `/profile` 查看自己的资料
- [ ] 已登录用户可访问 `/profile/edit` 编辑头像、昵称、简介、兴趣标签
- [ ] 首次编辑时必须设置 username，设置后 username 字段只读
- [ ] username 3-20 字符，仅允许字母/数字/下划线/连字符，全局唯一
- [ ] 昵称为必填，2-30 字符，保存时校验
- [ ] 兴趣标签从预定义列表选择，最多 10 个
- [ ] 他人资料页 `/users/{username}` 公开可访问，不展示邮箱等私密信息
- [ ] 不存在的 username 返回 404
- [ ] 导航栏显示当前用户头像，点击可进入个人中心
- [ ] 未登录访客无法访问 `/profile` 和 `/profile/edit`（重定向到登录页）

## 8. 边界清单

| 边界场景 | 处理方式 |
|---------|---------|
| 昵称为空或纯空格 | 前端校验 + 后端 422 `validation_error` |
| 昵称包含 `<script>` 等 XSS | 后端 HTML 转义，前端纯文本渲染 |
| 头像 URL 无效（404 图片） | 前端 `onError` fallback 到默认占位图 |
| 兴趣标签超出 10 个 | 前端禁用添加按钮，后端 422 |
| username 已被占用 | 后端 409 `username_taken` |
| username 包含非法字符 | 前端正则校验 + 后端 422 |
| 尝试修改已设置的 username | 前端字段只读，后端忽略该字段 |
| 并发编辑（多设备同时修改） | Last Write Wins，本期不做冲突检测 |
| 已删除用户的资料页 | 返回 404（deleted 用户对外不可见） |

## 9. 优先级与排期建议

| 优先级 | 功能项 |
|--------|-------|
| 🔴 P0 | 查看/编辑个人资料（username + 昵称 + 头像 + 简介 + 标签）|
| 🔴 P0 | 他人公开资料页 `/users/{username}` |
| 🟠 P1 | 导航栏头像入口与下拉菜单 |
| 🟡 P2 | 资料完善度提示（注册后引导填写） |

## 10. 依赖关系

- 依赖已有认证系统（JWT token 识别当前用户）
- username 和头像/昵称数据将被消息通知和站内信模块引用
