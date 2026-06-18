## MODIFIED Requirements

### Requirement: 帖子点赞 Toggle

系统 SHALL 在 `VoteService.toggleVote()` 中集成通知创建：点赞时创建 `POST_LIKED` 通知给帖子作者，取消点赞时删除对应通知。

#### Scenario: 点赞触发通知

- **WHEN** 用户 B toggle 点赞用户 A 的帖子（从未赞到赞）
- **THEN** 投票成功 + 为用户 A 创建 `POST_LIKED` 通知

#### Scenario: 取消点赞删除通知

- **WHEN** 用户 B toggle 取消点赞（从赞到未赞）
- **THEN** 投票取消 + 删除用户 A 收到的来自 B 的对应 `POST_LIKED` 通知（如存在）

#### Scenario: 自我点赞不通知

- **WHEN** 用户 A 点赞自己的帖子
- **THEN** 投票成功但不创建通知
