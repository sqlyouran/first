# Tasks: Replace @DirtiesContext with @Transactional

## Batch 1: 低风险 Controller 测试 (快速批量替换)

- [x] 1.1 替换 AuthMeExtendedTest
- [x] 1.2 替换 KnowledgeControllerTest
- [x] 1.3 替换 SpotBookmarkControllerTest
- [x] 1.4 替换 SpotCommentControllerTest
- [x] 1.5 替换 BookmarkControllerTest
- [x] 1.6 替换 CommentControllerTest
- [x] 1.7 跑 Batch 1 全部测试 → 确认全绿

> **发现**: BookmarkControllerTest / CommentControllerTest / SpotBookmarkControllerTest / SpotCommentControllerTest
> 依赖 RateLimitService 内存 fallback (ConcurrentHashMap)，@Transactional 不回滚内存状态，导致限流误触发。
> 这 4 个类回退为 @DirtiesContext(AFTER_EACH_TEST_METHOD)，AuthMeExtendedTest 和 KnowledgeControllerTest 保留 @Transactional。

## Batch 2: 高耗时 Controller 测试 (重点验证)

- [x] 2.1 替换 PostControllerTest (87.6s → 15.1s ✅)
- [x] 2.2 替换 ConversationControllerTest (45.4s → 10.7s ✅)
- [x] 2.3 替换 SecurityIntegrationTest (34.5s → 13.5s ✅)
- [x] 2.4 替换 ProfileControllerTest (25.7s → 2.9s ✅)
- [x] 2.5 替换 AuthControllerTest (25.2s → 1.4s ✅)
- [x] 2.6 替换 VoteControllerTest (12.2s → 2.2s ✅)
- [x] 2.7 跑 Batch 2 全部测试 → 确认全绿 + 记录耗时对比

## Batch 3: Service 测试

- [x] 3.1 替换 AiChatServiceTest
- [ ] 3.2 替换 AiChatServiceRagTest → **保留 @DirtiesContext**（VectorStore mock 跨测试污染，仅 3 用例 2.7s，收益小）
- [x] 3.3 替换 KnowledgeBuilderServiceTest
- [x] 3.4 跑 Batch 3 全部测试 → 确认全绿

## Batch 4: 全量验证

- [x] 4.1 跑全量测试 → 确认无回归 (540/540 全绿 ✅)
- [x] 4.2 记录总耗时对比: ~360s → 125s (提速 2.9x ✅)
- [ ] 4.3 归档变更
