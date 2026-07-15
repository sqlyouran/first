## ADDED Requirements

### Requirement: PostEntity 冗余计数字段

PostEntity SHALL 新增 `cachedUpVoteCount`（int）和 `cachedCommentCount`（int）两个冗余字段，用于避免列表排序时的运行时 COUNT 子查询。

#### Scenario: 新建帖子时计数为零

- **GIVEN** 创建一篇新帖子
- **WHEN** 帖子持久化成功
- **THEN** `cachedUpVoteCount` SHALL 为 0，`cachedCommentCount` SHALL 为 0

#### Scenario: 字段映射到数据库列

- **WHEN** 应用启动时 Hibernate 执行 DDL
- **THEN** posts 表 SHALL 新增 `cached_up_vote_count` 和 `cached_comment_count` 两列，默认值为 0

### Requirement: 投票时维护冗余计数

当用户对帖子投票（up）或取消投票时，SHALL 同步更新对应帖子的 `cachedUpVoteCount`。

#### Scenario: 点赞时计数加一

- **GIVEN** 帖子 A 的 `cachedUpVoteCount` 为 5
- **WHEN** 用户对帖子 A 点赞（vote_type = UP）
- **THEN** 帖子 A 的 `cachedUpVoteCount` SHALL 变为 6

#### Scenario: 取消点赞时计数减一

- **GIVEN** 帖子 A 的 `cachedUpVoteCount` 为 5，用户已点赞
- **WHEN** 用户取消点赞（删除 UP vote）
- **THEN** 帖子 A 的 `cachedUpVoteCount` SHALL 变为 4

### Requirement: 评论时维护冗余计数

当用户创建或删除帖子评论时，SHALL 同步更新对应帖子的 `cachedCommentCount`。

#### Scenario: 新增评论时计数加一

- **GIVEN** 帖子 A 的 `cachedCommentCount` 为 3
- **WHEN** 用户对帖子 A 发布一条评论
- **THEN** 帖子 A 的 `cachedCommentCount` SHALL 变为 4

#### Scenario: 删除评论时计数减一

- **GIVEN** 帖子 A 的 `cachedCommentCount` 为 3
- **WHEN** 用户删除帖子 A 的一条评论（软删除）
- **THEN** 帖子 A 的 `cachedCommentCount` SHALL 变为 2

#### Scenario: 回复评论时计数也加一

- **GIVEN** 帖子 A 的 `cachedCommentCount` 为 3
- **WHEN** 用户对帖子 A 的某条评论进行回复
- **THEN** 帖子 A 的 `cachedCommentCount` SHALL 变为 4（回复也是评论）

### Requirement: 排序查询使用冗余字段

帖子列表的排序查询 SHALL 使用 `cachedUpVoteCount` 和 `cachedCommentCount` 字段，不再使用 COUNT 子查询。

#### Scenario: most_upvoted 排序无子查询

- **WHEN** 调用 `GET /api/posts?sort=most_upvoted`
- **THEN** SQL 排序 SHALL 基于 `cached_up_vote_count` 列，不包含 `SELECT COUNT(*) FROM votes` 子查询

#### Scenario: most_commented 排序无子查询

- **WHEN** 调用 `GET /api/posts?sort=most_commented`
- **THEN** SQL 排序 SHALL 基于 `cached_comment_count` 列，不包含 `SELECT COUNT(*) FROM comments` 子查询

#### Scenario: cursor 分页排序同样使用冗余字段

- **WHEN** 使用 cursor 模式翻页并按 most_upvoted 排序
- **THEN** cursor 比较和排序 SHALL 均基于 `cached_up_vote_count`

### Requirement: API 响应格式不变

帖子列表和详情的 API 响应字段 SHALL 保持不变。`up_vote_count` 和 `comment_count` 响应字段的值来源从实时聚合改为冗余字段读取。

#### Scenario: 响应中互动统计值正确

- **GIVEN** 帖子有 5 个赞、3 条评论
- **WHEN** 调用帖子列表或详情接口
- **THEN** `up_vote_count` SHALL 为 5，`comment_count` SHALL 为 3（值来源为冗余字段）
