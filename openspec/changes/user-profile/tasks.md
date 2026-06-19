## 1. 后端 — UserEntity 扩展

- [ ] 1.1 `UserEntity` 新增 `username`(VARCHAR 20, UNIQUE)、`nickname`(VARCHAR 30)、`avatar_url`(VARCHAR 2048)、`bio`(VARCHAR 500)、`interest_tags`(TEXT, JSON) 字段 + getter/setter
- [ ] 1.2 `UserRepository` 新增 `findByUsername(String)` + `existsByUsername(String)` 方法
- [ ] 1.3 创建 `InterestTag` 枚举/常量类，定义 24 个预定义旅行标签（含 category）

## 2. 后端 — GET /api/auth/me 端点

- [ ] 2.1 编写 `GET /api/auth/me` 的失败测试（未认证返回 401）
- [ ] 2.2 编写 `GET /api/auth/me` 的成功测试（返回 id + email + state + created_at + nickname + avatar_url + username）
- [ ] 2.3 `AuthController` 实现 `GET /me` 端点 + `MeResponse` DTO
- [x] 2.4 前端 `MeData` interface 扩展 nickname/avatar_url/username 字段 + auth store 适配

## 3. 后端 — 资料 CRUD API

- [ ] 3.1 创建 `ProfileController` + `ProfileService` + Request/Response DTO
- [ ] 3.2 编写 `GET /api/users/me/profile` 测试（成功 + 未认证）
- [ ] 3.3 实现 `GET /api/users/me/profile` 端点
- [ ] 3.4 编写 `PUT /api/users/me/profile` 测试（首次设置成功 + username 占用 409 + 格式无效 422 + nickname 校验 + bio 超长 + tags 校验 + 可选字段清空 + 修改已有 username 被忽略）
- [ ] 3.5 实现 `PUT /api/users/me/profile` 端点（含 username 唯一性双层校验）
- [ ] 3.6 编写 `GET /api/users/{username}` 测试（存在 + 不存在 404 + 已删除 404）
- [ ] 3.7 实现 `GET /api/users/{username}` 端点（公开访问，不含 email）
- [ ] 3.8 编写 `GET /api/users/interest-tags` 测试
- [ ] 3.9 实现 `GET /api/users/interest-tags` 端点

## 4. 前端 — API 封装层

- [x] 4.1 创建 `lib/api/profile.ts`：`fetchMyProfile()`、`updateProfile()`、`fetchPublicProfile(username)`、`fetchInterestTags()`
- [x] 4.2 定义 TypeScript 类型：`ProfileData`、`UpdateProfileRequest`、`PublicProfileData`、`InterestTag`

## 5. 前端 — 我的资料页 /profile

- [x] 5.1 创建 `app/profile/page.tsx`（Client Component，authFetch 认证数据获取）
- [x] 5.2 实现四态覆盖：Loading 骨架 / Content / Empty 引导 / Error 重试
- [x] 5.3 编写 `/profile` 页面测试

## 6. 前端 — 编辑资料页 /profile/edit

- [x] 6.1 创建 `app/profile/edit/page.tsx`（Client Component 表单，含 ProfileForm 逻辑内联）
- [x] 6.2 创建 `app/profile/_components/TagSelector.tsx`（兴趣标签选择器，含 unselected/selected/disabled 三态）
- [x] 6.3 创建 `app/profile/edit/page.tsx`（Client Component，含表单校验 + 提交）
- [x] 6.4 实现 username 首次设置/只读切换 + 实时校验
- [x] 6.5 实现表单提交状态（idle/submitting/success/server_error）+ 服务端错误映射
- [x] 6.6 编写 `/profile/edit` 页面测试

## 7. 前端 — 他人公开资料页 /users/[username]

- [x] 7.1 创建 `app/users/[username]/page.tsx`（Client Component，SSR 兼容）
- [x] 7.2 实现四态覆盖 + notFound() 处理
- [x] 7.3 编写 `/users/[username]` 页面测试

## 8. 前端 — 导航栏 + 路由守卫

- [x] 8.1 创建 `app/_components/UserDropdown.tsx`（头像 + 下拉菜单：My Profile / Sign Out）
- [x] 8.2 导航栏集成 UserDropdown（SiteHeader 组件 + 根布局集成）
- [x] 8.3 `middleware.ts` 新增 `/profile` 到 `PROTECTED_PAGES`
- [x] 8.4 编写 UserDropdown 组件测试 + middleware 测试更新
