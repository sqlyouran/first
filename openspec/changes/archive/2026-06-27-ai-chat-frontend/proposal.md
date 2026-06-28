## Why

后端 AI 对话接口就绪后，前端需要将"Plan with AI"按钮的 coming soon 占位升级为真实聊天界面，让用户能在 Dialog/Sheet 中与 AI 助手进行多轮流式对话。

## What Changes

- 升级 `AiLauncherSlot`：Dialog/Sheet 内容从 "coming soon" 占位替换为 `<AiChatPanel />` 聊天组件
- 新增 `AiChatPanel` Client Component：消息列表 + 输入框 + 发送按钮，纯文本渲染（无 markdown）
- 新增 `lib/api/aiChat.ts`：SSE 流式消费函数，直接 fetch 后端 `/api/ai/chat`（Client Component 行为，不违反 BFF 边界）
- 新增 `lib/stores/aiChat.ts`：Zustand store，管理 conversationId、messages 列表、streaming 状态
- 桌面 Dialog 扩大为聊天面板（`max-w-lg h-[70vh]`），移动 Sheet 全屏聊天（`h-[85vh]`）
- 第一版纯文本，不做 markdown 渲染、对话历史列表

## Capabilities

### New Capabilities
- `ai-chat-frontend`: AI 助手前端聊天界面——聊天面板 UI、SSE 流式消费、Zustand 对话状态管理

### Modified Capabilities
- `homepage-ai-launcher`: Dialog/Sheet 内容从占位文本升级为真实聊天面板，button 行为从"打开占位弹窗"变为"打开聊天界面"

## Impact

- **Frontend**: 新增 `AiChatPanel.tsx` + `lib/api/aiChat.ts` + `lib/stores/aiChat.ts`，修改 `AiLauncherSlot.tsx`
- **Dependencies**: 无新增 npm 依赖（SSE 用原生 fetch + ReadableStream）
- **API 消费**: 前端直接调用后端 `/api/ai/conversations` + `/api/ai/chat`（Client Component fetch，不经 BFF）
- **现有测试**: `AiLauncherSlot.test.tsx` 需更新（"coming soon" 断言改为聊天面板断言）
