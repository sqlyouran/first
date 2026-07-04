## 1. 后端 DTO + 异常

- [x] 1.1 新增 `dto/AiPostAssistRequest.java` — record，含 `action`（@NotBlank @Pattern 限定 generate_title|recommend_tags|polish）、`content`（@NotBlank @Size max=50000）、`title`（@Size max=200，可选）
- [x] 1.2 新增 `dto/response/AiPostAssistResponse.java` — 继承 `BaseResponse`，含 `result` 字段（String 类型，JSON 数组时序列化为 JSON 字符串）
- [x] 1.3 新增 `exception/AiPostAssistException.java` — 继承 `RuntimeException`，持有 `HttpStatus` + `errorCode` + `message`

## 2. 后端 Service

- [x] 2.1 新增 `service/AiPostAssistService.java` — 构造器注入 `ChatClient`；定义三个 prompt 常量（GENERATE_TITLE_SYSTEM_PROMPT / RECOMMEND_TAGS_SYSTEM_PROMPT / POLISH_SYSTEM_PROMPT）；实现 `assist(AiPostAssistRequest, String requestId)` 方法，按 action 分发
- [x] 2.2 `generate_title` 实现：组装 prompt → `ChatClient.prompt().system(...).user(...).call().content()` → 截断到 200 字符 → 返回 `AiPostAssistResponse`
- [x] 2.3 `recommend_tags` 实现：组装 prompt（含 content + title）→ 调用 ChatClient → 解析返回的标签列表 → JSON 序列化为字符串返回
- [x] 2.4 `polish` 实现：组装 prompt（含 content）→ 调用 ChatClient → 返回润色后的完整 Markdown 文本

## 3. 后端 Controller

- [x] 3.1 新增 `controller/AiPostAssistController.java` — 构造器注入 `AiPostAssistService` + `JwtService`；`@PostMapping("/api/ai/post-assist")` 接收 `@Valid @RequestBody AiPostAssistRequest`，调用 `AuthUtil.requireUserId()` 认证，委托 service
- [x] 3.2 确认 `SecurityConfig` 已放行 `/api/ai/**`（当前已配置，无需改动）

## 4. 后端测试

- [x] 4.1 新增 `service/AiPostAssistServiceTest.java` — `@MockBean ChatClient`，mock `prompt().system().user().call().content()` 链路；测试三种 action 的成功场景 + content 为空时的异常
- [x] 4.2 新增 `controller/AiPostAssistControllerTest.java` — `@MockBean AiPostAssistService`；测试：成功 200、422（校验失败）、401（无 token）、无效 action
- [x] 4.3 运行全量后端测试 `mvn -f backend/pom.xml test`，确保全部通过

## 5. 前端 API 封装

- [x] 5.1 新增 `frontend/lib/api/aiPostAssist.ts` — 导出 `assistPost(action, content, title?)` 函数，返回 `ApiResponse<{ result: string }>`；处理 network error / server error
- [x] 5.2 新增 `frontend/lib/api/aiPostAssist.test.ts` — 测试成功响应、服务端错误、网络错误三种场景

## 6. 前端 PostForm 改造

- [x] 6.1 修改 `frontend/app/posts/_components/PostForm.tsx` — 标题输入框旁增加「✨ AI 生成标题」按钮（Sparkles 图标），调用 `assistPost("generate_title", content)` 成功后填充 title
- [x] 6.2 正文编辑器旁增加「✨ AI 润色」按钮，调用 `assistPost("polish", content)` 成功后替换 content
- [x] 6.3 标签输入旁增加「🏷️ AI 推荐标签」按钮（Tags 图标），调用 `assistPost("recommend_tags", content, title)` 成功后解析 JSON 数组填充 tags
- [x] 6.4 三个按钮在 `content` 为空时 disabled；点击时显示 loading（Loader2 旋转）；失败时恢复按钮并显示错误提示
- [x] 6.5 新增 `frontend/app/posts/_components/PostForm.test.tsx` — 测试按钮渲染、disabled 状态、loading 状态、成功填充、失败恢复
- [x] 6.6 运行前端测试 `cd frontend && npm test`，确保全部通过
