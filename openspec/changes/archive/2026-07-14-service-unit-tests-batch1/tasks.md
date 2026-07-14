## 1. TokenBlacklistService 测试（纯内存，5 个用例）

- [x] 1.1 创建 `TokenBlacklistServiceTest.java`，配置 `@BeforeEach` 初始化 service
- [x] 1.2 `emptyBlacklist_returnsFalse` — 新 service 查任何 jti 返回 false
- [x] 1.3 `addThenCheck_returnsTrue` — add 后 isBlacklisted 返回 true
- [x] 1.4 `unaddedJti_returnsFalse` — 只加 A，查 B 返回 false
- [x] 1.5 `addIsIdempotent` — 同一 jti 加两次不报错
- [x] 1.6 `multipleJtisIndependent` — 加 A 和 B，分别查都 true

## 2. VerificationCodeStore 测试（纯内存，10 个用例）

- [x] 2.1 创建 `VerificationCodeStoreTest.java`，配置 `@BeforeEach` 初始化 store
- [x] 2.2 `saveAndGetCode_returnsCode` — 存了就能取到
- [x] 2.3 `emailCaseInsensitive` — 大小写不敏感
- [x] 2.4 `unsavedEmail_returnsEmpty` — 没存过返回 empty
- [x] 2.5 `expiredCode_returnsEmpty` — ttl=0 存，getCode 返回 empty
- [x] 2.6 `expiredCode_isExpiredTrue` — ttl=0 后 isExpired 返回 true
- [x] 2.7 `validCode_isExpiredFalse` — ttl=600 后 isExpired 返回 false
- [x] 2.8 `nonexistentEmail_isExpiredTrue` — 没存过 isExpired 返回 true
- [x] 2.9 `remove_deletesCode` — 存 → remove → getCode 返回 empty
- [x] 2.10 `removeNonexistent_noException` — 删不存在的 key 不报错
- [x] 2.11 `saveOverwrites` — 同 email 存两次，取到第二次的值

## 3. AuthService 测试（Mockito，22 个用例）

- [x] 3.1 创建 `AuthServiceTest.java`，mock 6 个依赖，配置 `@BeforeEach`
- [x] 3.2 `sendCode_savesVerificationCode` — 正常发送
- [x] 3.3 `sendCode_ipRateLimited_throws429` — IP 限流
- [x] 3.4 `sendCode_emailRateLimited_returnsSilently` — email 限流静默
- [x] 3.5 `register_createsUser` — 正常注册
- [x] 3.6 `register_ipRateLimited_throws429` — IP 限流
- [x] 3.7 `register_invalidCode_throwsError` — 验证码不存在
- [x] 3.8 `register_expiredCode_throwsError` — 验证码过期
- [x] 3.9 `register_wrongCode_throwsError` — 验证码不匹配
- [x] 3.10 `register_emailExists_throws409` — 邮箱已注册
- [x] 3.11 `login_successReturnsTokens` — 正常登录
- [x] 3.12 `login_ipRateLimited_throws429` — IP 限流
- [x] 3.13 `login_nonexistentEmail_throwsError` — 邮箱不存在
- [x] 3.14 `login_deletedUser_throwsError` — deleted 用户
- [x] 3.15 `login_lockedNotExpired_throwsError` — 锁定未过期
- [x] 3.16 `login_lockedExpired_unlocksAccount` — 锁定已过期，解锁
- [x] 3.17 `login_emailUnverified_throws403` — 未验证邮箱
- [x] 3.18 `login_wrongPassword_incrementsFailedAttempts` — 密码错误 +1
- [x] 3.19 `login_5thWrongPassword_locksAccount` — 第 5 次锁定
- [x] 3.20 `login_correctPassword_resetsFailedAttempts` — 正确密码重置失败次数
- [x] 3.21 `refresh_returnsNewAccessToken` — 正常刷新
- [x] 3.22 `refresh_blacklistedJti_throwsError` — 黑名单 jti
- [x] 3.23 `logout_addsJtiToBlacklist` — 注销加黑名单

## 4. VoteService 测试（Mockito，12 个用例）

- [x] 4.1 创建 `VoteServiceTest.java`，mock VoteRepository、PostRepository、NotificationService
- [x] 4.2 `voteUp_createsVoteAndNotification` — 首次 UP
- [x] 4.3 `voteDown_createsVoteNoNotification` — 首次 DOWN
- [x] 4.4 `sameUpVote_cancelsAndDeletesNotification` — 重复 UP 取消
- [x] 4.5 `sameDownVote_cancelsNoNotification` — 重复 DOWN 取消
- [x] 4.6 `switchUpToDown_deletesNotification` — UP→DOWN 切换
- [x] 4.7 `switchDownToUp_createsNotification` — DOWN→UP 切换
- [x] 4.8 `invalidVoteType_throwsError` — 无效类型
- [x] 4.9 `postNotFound_throwsError` — 帖子不存在
- [x] 4.10 `removeVote_deletesExisting` — 删除已有投票
- [x] 4.11 `removeVote_noVote_noException` — 无投票不报错
- [x] 4.12 `getVoteStats_withUser_returnsCountsAndVote` — 登录用户
- [x] 4.13 `getVoteStats_noUser_returnsNullUserVote` — 未登录

## 5. PostService 测试（Mockito，19 个用例）

- [x] 5.1 创建 `PostServiceTest.java`，mock PostRepository、UserRepository、VoteRepository、BookmarkRepository、CommentRepository
- [x] 5.2 `createPost_generatesSlug` — slug 生成
- [x] 5.3 `createPost_userNotFound_throwsError` — 用户不存在
- [x] 5.4 `createPost_invalidStatus_throwsError` — 无效状态
- [x] 5.5 `updatePost_byAuthor_updatesFields` — 作者更新
- [x] 5.6 `updatePost_nonAuthor_throwsForbidden` — 非作者
- [x] 5.7 `updatePost_notFound_throwsError` — 不存在
- [x] 5.8 `deletePost_byAuthor_marksDeleted` — 作者删除
- [x] 5.9 `deletePost_nonAuthor_throwsForbidden` — 非作者
- [x] 5.10 `getPost_byUuid_returnsPublished` — UUID 查找
- [x] 5.11 `getPost_bySlug_returnsPublished` — slug 查找
- [x] 5.12 `getPost_nonPublished_throwsNotFound` — 非 PUBLISHED
- [x] 5.13 `getPost_notFound_throwsError` — 不存在
- [x] 5.14 `listPosts_firstLoad_returnsCursor` — 首次加载
- [x] 5.15 `listPosts_cursorMode_paginates` — cursor 翻页
- [x] 5.16 `listPosts_sizeCappedAt100` — size 上限
- [x] 5.17 `listUserPosts_filtersByAuthor` — 限定作者
- [x] 5.18 `slug_specialCharsCleaned` — 特殊字符清洗
- [x] 5.19 `slug_longTitleTruncated` — 超长截断
- [x] 5.20 `createPost_nullTags_defaultsToEmptyList` — null tags 默认空列表

## 6. 验证

- [x] 6.1 运行全部 5 个测试文件，68 个测试全部通过
- [x] 6.2 Code review 自检（全量 493 个测试无失败）
