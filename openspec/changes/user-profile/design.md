## Context

当前 `UserEntity` 仅含认证字段（email, password_hash, state, failed_attempts, locked_until）。前端 `fetchMe()` 调用 `GET /api/auth/me` 但该端点后端尚未实现。用户注册后无任何个人资料展示能力。

已有基础设施：
- JWT 认证 + `JwtService` 解析 token 获取 userId
- `BaseEntity` 提供 UUID id + createdAt/updatedAt + deleted
- `GlobalExceptionHandler` 统一异常处理
- Next.js rewrites 将 `/api/*` 代理到后端 8080
- `sonner` toast 通知库已集成

## Goals / Non-Goals

**Goals:**
- 用户可查看/编辑个人资料（username、nickname、avatar_url、bio、interest_tags）
- 他人可通过 `/users/{username}` 查看公开资料
- username 全局唯一，首次设置后不可更改
- 兴趣标签从预定义列表选择（后端维护）
- 导航栏新增用户头像入口

**Non-Goals:**
- 不做文件上传（仅 URL 输入头像）
- 不做资料审核
- 不做社交图谱（关注/好友）
- 不做资料完善度引导（P2 后续）

## Decisions

### D1: API 路由设计——独立 `/api/users` 模块 vs 扩展 `/api/auth`

**决策**：独立 `/api/users` 模块

- `GET /api/auth/me` — 返回认证信息 + 基础 profile（nickname, avatar_url, username），供 auth store 使用
- `GET /api/users/me/profile` — 返回完整个人资料（含 bio、interest_tags、email）
- `PUT /api/users/me/profile` — 编辑个人资料
- `GET /api/users/{username}` — 查看他人公开资料

**理由**：`/api/auth` 聚焦认证（登录/注册/刷新/登出），资料管理属于用户领域，独立模块职责更清晰。`/api/auth/me` 扩展少量 profile 字段是务实妥协（避免前端多处调用）。

### D2: username 唯一性校验

**决策**：Service 层先查后写 + 数据库 UNIQUE 约束兜底

- Service 调用 `userRepository.existsByUsername()` 检查
- 数据库列加 `UNIQUE` 约束，并发冲突时捕获 `DataIntegrityViolationException` 转换为 409 `username_taken`

**理由**：双层保护。Service 层提供友好错误信息，DB 约束防止极端并发。

### D3: 兴趣标签存储

**决策**：`UserEntity.interestTags` 为 `List<String>`，复用已有 `StringListConverter` JSON 序列化

- 预定义标签列表以 Java 枚举或常量类维护（`InterestTag` enum），共 24 个
- 前端请求 `GET /api/users/interest-tags` 获取可选标签列表
- 保存时后端校验每个标签是否在预定义列表中

**理由**：复用已有 JSON 序列化方案（PostEntity.tags 已使用），无需新表。标签列表变更只需改枚举 + 重启。

### D4: `/api/auth/me` 端点实现

**决策**：在 `AuthController` 新增 `GET /me` 端点

- 从 JWT token 解析 userId → 查询 UserEntity → 返回 `{ id, email, state, created_at, nickname, avatar_url, username }`
- 前端 `MeData` interface 扩展这三个字段

**理由**：前端 `fetchMe()` 已调用此路径，只需后端补实现。

### D5: 前端页面组件类型

**决策**：
- `/profile` — Server Component（SSR 预取，通过 `fetchFromBackend` 获取数据）
- `/profile/edit` — Client Component（表单交互）
- `/users/[username]` — Server Component（SSR + SEO）

**理由**：遵循 frontend-conventions 的"默认 Server Component，仅在需要交互时加 use client"原则。

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| username 设置后不可更改，用户可能选错 | 编辑页明确提示"This cannot be changed later"，username 字段旁显示警告图标 |
| 头像 URL 可能失效（外部图片 404） | 前端 `onError` fallback 到默认占位图，不阻断页面渲染 |
| `interest_tags` JSON 列查询性能 | 本期仅按 userId 读取整个列表，不做标签维度的查询/索引 |
| `/api/auth/me` 和 `/api/users/me/profile` 数据重叠 | `/me` 返回最小集（导航栏用），`/profile` 返回完整集（编辑页用），分工明确 |
