## 1. Phase 1: 修复 AI 聊天直连后端（高优）

- [x] 1.1 写失败测试：验证 `createConversation` 调用 `authFetch`（而非裸 `fetch`），URL 为相对路径 `/api/ai/conversations`（不含 `NEXT_PUBLIC_BACKEND_URL`）
- [x] 1.2 写失败测试：验证 `streamChat` 调用 `authFetch`（而非裸 `fetch`），URL 为相对路径 `/api/ai/chat`，且不引用 `NEXT_PUBLIC_BACKEND_URL`
- [x] 1.3 写失败测试：验证 `createConversation` 有错误处理——网络错误时返回 `{ id: "" }` 或抛出可控异常，不裸抛 `TypeError`
- [x] 1.4 实现：改造 `lib/api/aiChat.ts`——移除 `NEXT_PUBLIC_BACKEND_URL` 常量，`createConversation` 和 `streamChat` 改用 `authFetch` + 相对路径，`createConversation` 补充 try/catch 错误处理
- [x] 1.5 适配 `lib/stores/aiChat.test.ts`：mock `authFetch` 替代 mock `fetch`，确保测试全绿
- [x] 1.6 验证：`npm test` 全绿

## 2. Phase 2: 添加安全响应头

- [x] 2.1 写失败测试：验证 `next.config.ts` 导出的配置包含 `headers()` 函数，且返回值包含 `Content-Security-Policy`、`X-Frame-Options`、`X-Content-Type-Options`、`Referrer-Policy`、`Strict-Transport-Security` 五个头
- [x] 2.2 实现：在 `next.config.ts` 中添加 `headers()` 配置，按 design.md D2 中的头清单配置
- [x] 2.3 验证：`npm run build` 成功，无 CSP 相关报错
- [x] 2.4 验证：`npm test` 全绿

## 3. Phase 3: 加固 `cover_image` URL 校验

- [x] 3.1 写失败测试：调用 `createPost({ cover_image: "javascript:alert(1)", ... })` 时，返回 `error.error_code === "validation_error"`，不发出网络请求
- [x] 3.2 写失败测试：调用 `createPost({ cover_image: "data:text/html,<script>alert(1)</script>", ... })` 时，返回 `error.error_code === "validation_error"`
- [x] 3.3 写失败测试：调用 `createPost({ cover_image: "https://example.com/img.jpg", ... })` 时，正常发出请求（不拦截合法 URL）
- [x] 3.4 实现：在 `lib/api/posts.ts` 的 `createPost` 函数中添加 `cover_image` URL 协议白名单校验，拒绝非 `http/https` 协议
- [x] 3.5 验证：`npm test` 全绿

## 4. Phase 4: 文档化中间件限制

- [x] 4.1 在 `middleware.ts` 中添加注释：说明中间件仅检查 cookie 存在性（不验证有效性）、原因是 Edge Runtime 限制、安全兜底由 `authFetch` 的 401 自动重定向保证
- [x] 4.2 验证：`npm test` 全绿（注释改动不影响行为）

## 5. 验证与收尾

- [x] 5.1 全量运行前端测试 `cd frontend && npm test`，确保全绿
- [x] 5.2 手动验证：启动前端 + 后端，测试 AI 聊天功能正常（创建会话、发消息、流式回复）
- [x] 5.3 手动验证：浏览器开发者工具 Network 面板中 AI 聊天请求走 `/api/ai/...` 而非直连后端
- [x] 5.4 手动验证：浏览器开发者工具 Response Headers 中包含 CSP 等安全头
- [ ] 5.5 请求 Code Review
