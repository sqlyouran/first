## 1. SSE 消费函数 — TDD RED

- [x] 1.1 新增 `lib/api/aiChat.ts`：定义 `AiMessage` 类型（role: "user" | "assistant", content: string）
- [x] 1.2 新增 `lib/api/aiChat.test.ts`：测试 `streamChat` 函数 — POST 请求格式、onToken 回调、onDone 回调、onError 回调
- [x] 1.3 新增 `lib/api/aiChat.test.ts`：测试 `createConversation` 函数 — POST 请求、返回 id
- [x] 1.4 运行 `npm test` 确认 RED
- [ ] 1.5 提交：`test(ai-chat): RED - SSE consumer + createConversation`

## 2. SSE 消费函数 — TDD GREEN

- [x] 2.1 实现 `createConversation()`：fetch POST `/api/ai/conversations`，返回 `{ id }`
- [x] 2.2 实现 `streamChat(conversationId, message, onToken, onDone, onError)`：fetch POST `/api/ai/chat` + ReadableStream 解析 SSE 事件
- [x] 2.3 实现 SSE 文本解析：按 `event:` / `data:` 行解析，区分 token / done / error 事件
- [x] 2.4 运行测试确认 GREEN
- [ ] 2.5 提交：`feat(ai-chat): GREEN - SSE consumer + createConversation`

## 3. Zustand Store — TDD RED

- [x] 3.1 新增 `lib/stores/aiChat.test.ts`：测试初始状态（conversationId=null, messages=[], isStreaming=false, error=null）
- [x] 3.2 新增测试：`createConversation` action 调用 API 并设置 conversationId
- [x] 3.3 新增测试：`sendMessage` action 追加用户消息 + 设置 isStreaming + 流式追加 assistant 消息
- [x] 3.4 新增测试：`reset` action 清空所有状态
- [x] 3.5 运行测试确认 RED
- [ ] 3.6 提交：`test(ai-chat): RED - Zustand store`

## 4. Zustand Store — TDD GREEN

- [x] 4.1 新增 `lib/stores/aiChat.ts`：`useAiChatStore` = create<AiChatState>()
- [x] 4.2 实现 `createConversation` action：调用 `api/aiChat.createConversation()` 并设置 conversationId
- [x] 4.3 实现 `sendMessage` action：追加 user 消息 → 设 isStreaming=true → 调用 `streamChat` → onToken 追加 assistant 内容 → onDone 设 isStreaming=false → onError 设 error
- [x] 4.4 实现 `reset` action：恢复初始状态
- [x] 4.5 运行测试确认 GREEN
- [ ] 4.6 提交：`feat(ai-chat): GREEN - Zustand store`

## 5. AiChatPanel 组件 — TDD RED

- [x] 5.1 新增 `app/_components/AiChatPanel.test.tsx`：测试空状态引导文案、用户消息气泡样式、AI 消息气泡样式
- [x] 5.2 新增测试：streaming 时发送按钮 disabled + Loader2 图标
- [x] 5.3 新增测试：Enter 键发送消息 + 输入框清空
- [x] 5.4 运行测试确认 RED
- [ ] 5.5 提交：`test(ai-chat): RED - AiChatPanel`

## 6. AiChatPanel 组件 — TDD GREEN

- [x] 6.1 新增 `app/_components/AiChatPanel.tsx`："use client" 组件
- [x] 6.2 实现消息列表区：flex-1 overflow-y-auto，空状态引导文案，消息气泡（user 右对齐蓝色，assistant 左对齐灰色）
- [x] 6.3 实现输入区：Input 文本框 + Button 发送按钮，Enter 发送 / Shift+Enter 换行
- [x] 6.4 streaming 时发送按钮 disabled + Loader2 旋转图标
- [x] 6.5 新消息自动滚动到底部（useEffect + scrollIntoView）
- [x] 6.6 运行测试确认 GREEN
- [ ] 6.7 提交：`feat(ai-chat): GREEN - AiChatPanel`

## 7. AiLauncherSlot 集成

- [x] 7.1 修改 `app/regions/AiLauncherSlot.test.tsx`：将 "coming soon" 断言改为 AiChatPanel 断言
- [x] 7.2 运行测试确认 RED
- [x] 7.3 修改 `app/regions/AiLauncherSlot.tsx`：Dialog 内容替换为 `<AiChatPanel />`，Desktop Dialog 尺寸改为 `sm:max-w-lg h-[70vh]`
- [x] 7.4 修改 Sheet 内容替换为 `<AiChatPanel />`，Mobile Sheet 尺寸改为 `h-[85vh]`
- [x] 7.5 面板首次打开自动调用 `createConversation()`（useEffect 或 store 初始化）
- [x] 7.6 运行测试确认 GREEN
- [ ] 7.7 提交：`feat(ai-chat): integrate AiChatPanel into AiLauncherSlot`

## 8. 全量验证

- [x] 8.1 `npm test` 全量测试绿灯
- [x] 8.2 `npm run build` 构建通过
- [ ] 8.3 启动前端 + 后端，手动测试聊天面板交互（需 DASHSCOPE_API_KEY）
