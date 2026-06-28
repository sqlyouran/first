## 1. 依赖与配置

- [x] 1.1 `pom.xml` 新增 `spring-ai-alibaba-starter` 依赖（DashScope），保留现有 `spring-ai-bom` BOM 管理
- [x] 1.2 `application.yml` 新增 `spring.ai.dashscope.api-key: ${DASHSCOPE_API_KEY:}` 配置
- [x] 1.3 `test/resources/application.yml` 新增 DashScope mock 配置（`enabled: false` 或 test-key）
- [x] 1.4 新增 `config/AiConfig.java`：`@Configuration` 类，注入 `ChatClient` bean + system prompt 常量

## 2. 实体与 Repository

- [x] 2.1 新增 `entity/AiConversation.java`：继承 BaseEntity，字段 userId(UUID,nullable)、title(String)、lastMessageAt(Instant)
- [x] 2.2 新增 `entity/AiMessage.java`：继承 BaseEntity，字段 conversationId(UUID)、role(AiMessageRole)、content(String @Lob)
- [x] 2.3 新增 `entity/AiMessageRole.java`：枚举 USER / ASSISTANT
- [x] 2.4 新增 `repository/AiConversationRepository.java`：继承 JpaRepository
- [x] 2.5 新增 `repository/AiMessageRepository.java`：继承 JpaRepository，含 `findByConversationIdAndDeletedFalseOrderByCreatedAtAsc`

## 3. DTO

- [x] 3.1 新增 `dto/AiChatRequest.java`：record，字段 conversationId(@NotNull UUID)、message(@NotBlank @Size(max=2000) String)
- [x] 3.2 新增 `dto/response/AiConversationResponse.java`：继承 BaseResponse，字段 id、createdAt
- [x] 3.3 新增 `exception/AiChatException.java`：extends RuntimeException，持有 HttpStatus + errorCode（SSE 场景下无需备用 Response DTO）

## 4. Service — TDD RED

- [x] 4.1 新增 `service/AiChatServiceTest.java`：`@SpringBootTest`，Mock ChatClient，测试 createConversation、sendMessage 持久化、上下文窗口组装
- [x] 4.2 运行测试确认 RED（AiChatService 未实现）
- [ ] 4.3 提交：`test(ai-chat): RED - AiChatService`

## 5. Service — TDD GREEN

- [x] 5.1 新增 `service/AiChatService.java`：构造器注入 AiConversationRepository + AiMessageRepository + ChatClient
- [x] 5.2 实现 `createConversation(UUID userId)`：创建 AiConversation 实体并保存
- [x] 5.3 实现 `sendMessage(UUID conversationId, String message)`：保存用户消息 → 取最近 N 轮上下文 → 调用 ChatClient.stream() → 返回 SseEmitter
- [x] 5.4 实现 Flux→SseEmitter 桥接：subscribe onNext→send token event, onComplete→send done event + 保存 assistant 消息, onError→send error event
- [x] 5.5 运行测试确认 GREEN
- [ ] 5.6 提交：`feat(ai-chat): GREEN - AiChatService`

## 6. Controller — TDD RED

- [x] 6.1 新增 `controller/AiChatControllerTest.java`：`@WebMvcTest`，Mock AiChatService，测试 POST /api/ai/conversations（201）、POST /api/ai/chat（200 SSE）、404、422
- [x] 6.2 运行测试确认 RED
- [ ] 6.3 提交：`test(ai-chat): RED - AiChatController`

## 7. Controller — TDD GREEN

- [x] 7.1 新增 `controller/AiChatController.java`：构造器注入 AiChatService + JwtService
- [x] 7.2 实现 `POST /api/ai/conversations`：可选 JWT 取 userId（匿名为 null），调用 service.createConversation
- [x] 7.3 实现 `POST /api/ai/chat`：参数校验 @Valid，调用 service.sendMessage 返回 SseEmitter
- [x] 7.4 运行测试确认 GREEN
- [ ] 7.5 提交：`feat(ai-chat): GREEN - AiChatController`

## 8. 安全配置

- [x] 8.1 `config/SecurityConfig.java` 新增 `/api/ai/**` 到 permitAll 列表（匿名可访问）
- [x] 8.2 确认现有安全测试不受影响

## 9. 集成验证

- [x] 9.1 启动后端，手动 `POST /api/ai/conversations` 确认 201
- [x] 9.2 手动 `POST /api/ai/chat` 确认 SSE 流（需真实 DASHSCOPE_API_KEY）
- [x] 9.3 全量测试 `mvn -f backend/pom.xml test` 确认绿灯
