# Design: Replace @DirtiesContext with @Transactional

## 变更模式

对每个目标测试类执行：

```java
// BEFORE
import org.springframework.test.annotation.DirtiesContext;

@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class XxxTest { ... }

// AFTER
import org.springframework.test.annotation.DirtiesContext; // 删除
import org.springframework.transaction.annotation.Transactional; // 新增

@Transactional
class XxxTest { ... }
```

## 目标文件清单 (15 个)

### Controller 测试 (12 个)
1. `AuthControllerTest.java`
2. `AuthMeExtendedTest.java`
3. `BookmarkControllerTest.java`
4. `CommentControllerTest.java`
5. `ConversationControllerTest.java`
6. `KnowledgeControllerTest.java`
7. `PostControllerTest.java`
8. `ProfileControllerTest.java`
9. `SpotBookmarkControllerTest.java`
10. `SpotCommentControllerTest.java`
11. `VoteControllerTest.java`
12. `SecurityIntegrationTest.java`

### Service 测试 (3 个)
13. `AiChatServiceTest.java`
14. `AiChatServiceRagTest.java`
15. `KnowledgeBuilderServiceTest.java`

## 验证策略

1. 逐类替换 → 跑该类测试确认全绿
2. 全部替换完 → 跑全量测试确认无回归
3. 对比替换前后耗时
