## Context

当前 AI 聊天架构：

```
AiChatController → AiChatService → ChatClient.prompt()
                                     .messages(contextMessages)  ← 滑动窗口 + RAG
                                     .stream()
                                     .content()
                                     .subscribe(token → SSE)
```

- `AiConfig` 构建 `ChatClient` bean，仅配置 `defaultSystem(SYSTEM_PROMPT)`
- `AiChatService` 通过 `buildContextMessages()` 组装历史对话 + RAG 知识片段
- `WeatherService` 和 `ExchangeRateService` 已使用 `@Tool` 注解，但仅作为 **MCP Server 工具**暴露给外部 MCP 客户端，未接入内部 `ChatClient`
- Spring AI 1.0.0 支持 `ToolCallbackProvider` 模式：注册 `@Tool` bean 后，`ChatClient` 自动在 prompt 中声明函数签名，LLM 识别意图后调用函数，Spring AI 框架自动将结果回传给 LLM

**约束**：
- 后端 Spring Boot 3.3.5 + Java 17，Spring AI 1.0.0 BOM
- 测试环境 `@MockBean ChatClient` + H2 内存库
- 现有 `AiChatServiceTest` mock 了 `chatClient.prompt().messages().stream()` 链路

## Goals / Non-Goals

**Goals:**
- AI 助手能精确查询平台景点数据（列表、详情、排行榜）
- 通过 Spring AI `@Tool` + `ToolCallbackProvider` 标准模式注册工具
- Function Calling 与 RAG 共存：RAG 提供模糊语义匹配（攻略文本），Function Calling 提供精确结构化查询（景点列表）
- 流式响应（SSE）兼容 Function Calling：LLM 先调函数再流式输出回答
- 测试覆盖工具注册 + 工具调用场景

**Non-Goals:**
- 不接入现有 Weather/ExchangeRate 工具（scope 聚焦景点查询）
- 不做城市查询、帖子搜索等其他工具（后续按需扩展）
- 不做前端改动（Function Calling 对前端透明）
- 不做 MCP Server 侧改动（现有 MCP 工具暴露不受影响）

## Decisions

### D1: 工具注册方式 — ToolCallbackProvider Bean

**选择**: 新增 `SpotToolCallbackProvider` 配置类，通过 `SyncToolCallbackProvider(toolObjects...)` 注册  
**备选**: `ChatClient.Builder.defaultTools()` 直接传入对象  
**理由**:
- `ToolCallbackProvider` 是 Spring AI 1.0.0 标准模式，自动发现 `@Tool` 方法并生成 JSON Schema
- 与现有 MCP Server 工具注册模式一致
- 便于后续新增工具（只需在 Provider 中追加 bean）

### D2: 工具类位置 — 独立 SpotQueryTool

**选择**: 新建 `service/SpotQueryTool.java`，注入 `SpotRepository` / `SpotService`  
**备选**: 在 `SpotService` 上直接加 `@Tool`  
**理由**:
- `SpotService` 是业务 Service（CRUD + 排序），工具是 AI 适配层，职责不同
- 工具方法签名面向 LLM（简单参数 + 自然语言描述），与业务方法签名不同
- 独立类便于单元测试

### D3: 三个工具函数设计

| 函数 | 参数 | 底层调用 | 返回 |
|------|------|---------|------|
| `searchSpotsByCity` | `cityName: String` | `SpotRepository.findByCitySlugAndDeletedFalse` + PageRequest(0, 10) | 景点列表摘要（name, nameZh, rating, tags） |
| `getSpotDetails` | `nameOrSlug: String` | `SpotRepository.findBySlugAndDeletedFalse` | 景点完整信息（含 description, gallery, tags） |
| `getTopRatedSpots` | `limit: int` (1-10) | `SpotService.getRanking("rating", limit)` | 评分最高的景点列表 |

**设计要点**：
- 返回给 LLM 的数据精简为文本摘要（非完整 JSON response），减少 token 消耗
- 每个函数有明确的 `@ToolParam` 描述，帮助 LLM 理解参数含义

### D4: Function Calling + 流式响应兼容

**选择**: 保持 `ChatClient.prompt().stream().content().subscribe()` 模式不变  
**理由**:
- Spring AI 1.0.0 + DashScope 支持 stream 模式下的 function calling
- LLM 识别到 function call 时，框架自动执行函数并将结果注入对话，然后继续流式输出最终回答
- 无需修改 `AiChatService` 的 stream 逻辑

### D5: Function Calling + RAG 共存

**选择**: 两者共存，由 LLM 自主决定何时调用工具、何时依赖 RAG 知识  
**理由**:
- RAG 提供攻略文本的模糊匹配（"西湖怎么玩"→ 攻略片段）
- Function Calling 提供精确结构化查询（"杭州景点列表"→ 数据库查询结果）
- 两者互补，LLM 根据问题类型自主选择最优路径

## Risks / Trade-offs

- **[风险] LLM 误判 function call 时机** → prompt 中明确工具使用场景描述；DashScope qwen-plus 对 function calling 支持成熟
- **[风险] 流式 + function calling 延迟增加** → 函数调用是同步的（数据库查询 < 100ms），LLM 拿到结果后再流式输出，体感延迟增加 < 1s
- **[风险] 测试中 Mock ChatClient 链路需适配** → `AiChatServiceTest` 需 mock `.tools()` 调用链；`SpotQueryTool` 独立测试不依赖 ChatClient
- **[权衡] 仅景点查询，不含城市/帖子** → 控制 scope，验证 function calling 模式可行后再扩展
