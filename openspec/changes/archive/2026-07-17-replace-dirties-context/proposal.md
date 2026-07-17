# Replace @DirtiesContext with @Transactional

## Summary

将 15 个测试类的 `@DirtiesContext(AFTER_EACH_TEST_METHOD)` 替换为 `@Transactional`，消除每个测试方法后重建 Spring 容器的性能瓶颈。

## Motivation

当前测试套件耗时约 360 秒，其中 80% 的时间被 15 个使用 `@DirtiesContext(AFTER_EACH_TEST_METHOD)` 的测试类吃掉。这个注解在每个测试方法后销毁并重建整个 Spring 容器，导致：

- PostControllerTest (34 用例) 耗时 87.6 秒
- ConversationControllerTest (26 用例) 耗时 45.4 秒
- SecurityIntegrationTest (11 用例) 耗时 34.5 秒

预计优化后全量测试从 ~360 秒降至 ~80 秒。

## Scope

- **In scope**: 15 个测试类的注解替换 + 必要的 import 清理
- **Out of scope**: JaCoCo 集成、pre-commit hook、测试架构重构（@WebMvcTest）

## Risk Assessment

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| VerificationCodeStore 内存 fallback 跨用例残留 | 低 | 各测试用不同邮箱，不冲突 |
| MockMvc 请求与测试事务传播 | 低 | MockMvc 同线程执行，加入测试事务 |
| Thread.sleep 等并发问题 | 无 | 仅用于时间戳间隔，不涉及异步 |
