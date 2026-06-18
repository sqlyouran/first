## Why

用户注册后没有任何个人资料展示能力，平台上的帖子、评论、收藏缺乏身份归属。内容创作者无法被识别，用户间无法通过资料页建立信任，后续的通知系统和站内信也依赖用户资料（头像、昵称、username）作为展示元素。

## What Changes

- 扩展 `UserEntity` 新增 `username`（全局唯一 URL slug，设置后不可更改）、`nickname`、`avatar_url`、`bio`、`interest_tags` 字段
- 新增后端 API：`GET /api/users/me/profile`（查看自己资料）、`PUT /api/users/me/profile`（编辑资料）、`GET /api/users/{username}`（查看公开资料）
- 新增预定义兴趣标签数据源（后端配置或枚举）
- 新增前端页面：`/profile`（我的资料）、`/profile/edit`（编辑资料）、`/users/[username]`（公开资料）
- 导航栏新增用户头像入口与下拉菜单
- `middleware.ts` 新增 `/profile` 路由守卫

## Capabilities

### New Capabilities
- `user-profile`: 用户资料 CRUD API（查看/编辑自己的资料 + 查看他人公开资料），含 username 唯一性校验与兴趣标签预定义列表

### Modified Capabilities
- `auth`: `GET /api/auth/me` 响应需扩展返回 profile 字段（nickname, avatar_url, username）

## Impact

- **Backend**: `UserEntity` 新增 5 个字段、新增 `ProfileController` + `ProfileService`、`UserRepository` 新增 `findByUsername` 方法
- **Frontend**: 新增 3 个页面路由、`UserDropdown` 导航栏组件、`TagSelector` 组件、`auth store` 扩展 profile 字段
- **Database**: `users` 表新增列（`username`, `nickname`, `avatar_url`, `bio`, `interest_tags`）
- **Middleware**: `PROTECTED_PAGES` 新增 `/profile`
- **依赖**: 无新外部依赖
