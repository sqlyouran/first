## 1. 基础设施

- [x] 1.1 安装依赖：`npm install @uiw/react-md-editor react-markdown remark-gfm`
- [x] 1.2 提取 `lib/api/client.ts`：从 `auth.ts` 搬出 `ApiError` / `ApiResponse<T>` / `parseResponse` / `networkError` / `serverError`
- [x] 1.3 更新 `lib/api/auth.ts`：改为从 `client.ts` 导入，删除重复定义
- [x] 1.4 更新 `middleware.ts`：反转逻辑为 `PROTECTED_PAGES` 白名单保护

## 2. API 封装层

- [x] 2.1 新增 `lib/api/posts.ts`：定义 `PostData` / `PostListItem` / `PostListData` 类型
- [x] 2.2 实现 `createPost()`：使用 `authFetch` + `parseResponse`
- [x] 2.3 实现 `fetchPost(id)`：普通 `fetch` + `parseResponse`
- [x] 2.4 实现 `fetchPosts(page, size)` 和 `fetchUserPosts(userId, page, size)`

## 3. 共享组件

- [x] 3.1 新增 `app/posts/_components/PostCard.tsx`：帖子摘要卡片（title / cover_image / tags / created_at）
- [x] 3.2 新增 `app/posts/_components/TagInput.tsx`：标签输入（回车添加 / X 删除 / 最多 10 个 / 每个最多 30 字符）
- [x] 3.3 新增 `app/posts/_components/PostForm.tsx`：发帖表单（title Input / Markdown 编辑器 / cover_image Input / TagInput / status 选择 / 提交按钮）

## 4. 页面

- [x] 4.1 新增 `app/posts/page.tsx`（Client Component）：列表页，默认 page=1 size=20，分页交互，空状态提示
- [x] 4.2 新增 `app/posts/[id]/page.tsx`（Server Component）：详情页，`fetchFromBackend` SSR，Markdown 渲染，404 处理
- [x] 4.3 新增 `app/posts/create/page.tsx`（Client Component）：发帖页，表单校验，提交 + 导航

## 5. 测试（TDD — RED → GREEN → REFACTOR）

- [x] 5.1 `client.test.ts`：验证 `parseResponse` / `networkError` / `serverError` 行为
- [x] 5.2 `posts.test.ts`：验证 `createPost` / `fetchPost` / `fetchPosts` / `fetchUserPosts` 调用正确
- [x] 5.3 `PostCard.test.tsx`：验证卡片渲染（title / cover_image / tags / created_at）
- [x] 5.4 `TagInput.test.tsx`：验证添加 / 删除 / 上限
- [x] 5.5 `PostForm.test.tsx`：验证表单字段 / 校验 / 提交
- [x] 5.6 `posts/page.test.tsx`：验证列表加载 / 分页 / 空状态
- [x] 5.7 `posts/[id]/page.test.tsx`：验证详情渲染 / 404
- [x] 5.8 `posts/create/page.test.tsx`：验证表单 / 提交成功导航 / 错误处理
- [x] 5.9 `middleware.test.ts`：更新验证白名单保护逻辑

## 6. 验收

- [x] 6.1 `npm test` 全绿（29 文件 / 181 测试）
- [ ] 6.2 手动验证：`/posts` 列表加载 + 分页
- [ ] 6.3 手动验证：`/posts/{id}` 详情渲染 Markdown
- [ ] 6.4 手动验证：`/posts/create` 表单提交 + 未登录重定向
