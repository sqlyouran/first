## Context

`AiLauncherSlot` 当前在 Desktop 用 Dialog、Mobile 用 Sheet，内容均为 "AI Trip Planner coming soon" 占位文本。后端 `ai-chat-backend` change 就绪后，前端需将占位内容替换为真实聊天面板。

前端是薄 BFF，SSE 流式消费属于 Client Component 行为，直接 fetch 后端端点不违反 BFF 边界。

## Goals / Non-Goals

**Goals:**
- 将 Dialog/Sheet 内容升级为 `<AiChatPanel />` 聊天组件
- 实现 SSE 流式消费（原生 fetch + ReadableStream，无新依赖）
- Zustand store 管理对话状态（messages、conversationId、isStreaming）
- 纯文本消息渲染（不做 markdown）
- 桌面 `h-[70vh]`、移动 `h-[85vh]` 的聊天面板尺寸
- TDD 覆盖：AiChatPanel 组件 + Zustand store + SSE 消费函数

**Non-Goals:**
- Markdown 渲染（后续增强）
- 对话历史列表 / 切换对话
- 快捷指令 / 预设问题
- 修改 `aiLauncher.data.ts`（buttonLabel 保持 "Plan with AI"）
- 修改 `AiLauncherSlot` 的浮按钮样式和定位

## Decisions

### D1: SSE 消费 — 原生 fetch + ReadableStream

**选择**: `fetch()` + `response.body.getReader()` 逐块读取 SSE  
**备选**: `EventSource` API / 第三方 SSE 库  
**理由**:
- `EventSource` 只支持 GET，我们需要 POST 发送消息体
- 原生 fetch 零依赖，完全可控
- 封装为 `lib/api/aiChat.ts` 中的 `streamChat(conversationId, message, onToken, onDone, onError)` 函数

### D2: 状态管理 — Zustand store

```ts
interface AiChatState {
  conversationId: string | null;
  messages: AiMessage[];
  isStreaming: boolean;
  error: string | null;
  // actions
  createConversation: () => Promise<void>;
  sendMessage: (content: string) => Promise<void>;
  reset: () => void;
}
```

- 一个 store 文件 `lib/stores/aiChat.ts`
- `sendMessage` 内部调用 SSE 消费函数，逐 token 更新 `messages` 最后一条 assistant 消息

### D3: AiChatPanel 组件结构

```
AiChatPanel ("use client")
├── 消息列表区 (flex-1 overflow-y-auto)
│   ├── 空状态: "Ask me anything about traveling in China!"
│   └── 消息气泡 (user: 右对齐蓝色, assistant: 左对齐灰色)
├── 分隔线
└── 输入区 (flex-shrink-0)
    ├── <Input> 文本框 (Enter 发送, Shift+Enter 换行)
    └── <Button> 发送按钮 (streaming 时 disabled + Loader2 旋转)
```

### D4: Dialog/Sheet 尺寸升级

| 形态 | 当前 | 目标 |
|------|------|------|
| Desktop Dialog | `sm:max-w-md` + 自适应高度 | `sm:max-w-lg` + `h-[70vh]` |
| Mobile Sheet | `side="bottom"` + 自适应高度 | `side="bottom"` + `h-[85vh]` |

### D5: AiLauncherSlot 集成方式

`AiLauncherSlot.tsx` 的 Dialog/Sheet 内容区从硬编码占位替换为 `<AiChatPanel />`。浮按钮（trigger）不变。

### D6: 自动创建会话

面板首次打开时，Zustand store 自动调用 `createConversation()` 获取 conversationId，无需用户手动触发。

## Risks / Trade-offs

- **[风险] SSE 连接中断** → store 设 `error` 状态，UI 显示错误提示 + 重试按钮
- **[风险] Dialog 关闭后状态丢失** → 关闭时不 reset store，重新打开可续聊（同一会话）
- **[Trade-off] 无 markdown** → AI 输出含 markdown 语法时显示原始文本，可接受作为 MVP
- **[Trade-off] 单会话模式** → 用户无法切换历史对话，后续增强
