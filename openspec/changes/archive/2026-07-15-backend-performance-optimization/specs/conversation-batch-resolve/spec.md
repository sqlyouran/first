## ADDED Requirements

### Requirement: 会话列表批量预取对方用户

`GET /api/conversations` SHALL 通过批量查询获取所有会话的对方用户信息，而非逐条 `findById`。

#### Scenario: 20 条会话的对方用户查询次数

- **GIVEN** 当前页有 20 条会话
- **WHEN** 调用会话列表接口
- **THEN** 对方用户信息查询 SHALL 最多执行 1 次（批量 `findAllById`），而非 20 次

### Requirement: 会话列表批量获取最新消息

`GET /api/conversations` SHALL 通过批量查询获取所有会话的最新消息内容，而非逐条查询。

#### Scenario: 最新消息批量查询

- **GIVEN** 当前页有 20 条会话
- **WHEN** 调用会话列表接口
- **THEN** 最新消息查询 SHALL 最多执行 1 次（批量子查询或 IN 查询），而非 20 次

### Requirement: 会话列表批量获取未读数

`GET /api/conversations` SHALL 通过批量查询获取所有会话的未读消息数，而非逐条 `countBy`。

#### Scenario: 未读数批量查询

- **GIVEN** 当前页有 20 条会话
- **WHEN** 调用会话列表接口
- **THEN** 未读数查询 SHALL 最多执行 1 次（GROUP BY 聚合），而非 20 次

### Requirement: 未读消息总数聚合查询

`GET /api/conversations/unread-count` SHALL 通过单条聚合 SQL 计算未读消息总数，不再加载全部会话到内存。

#### Scenario: 未读总数单次聚合

- **GIVEN** 用户有 100 个会话
- **WHEN** 调用未读计数接口
- **THEN** SHALL 执行 1 条聚合 SQL 返回总数，不再使用 `Integer.MAX_VALUE` 加载全部会话

#### Scenario: 无会话时返回零

- **GIVEN** 用户没有任何会话
- **WHEN** 调用未读计数接口
- **THEN** 返回 `unread_count: 0`

### Requirement: API 响应格式不变

会话列表和未读计数的 API 响应字段和格式 SHALL 保持不变。

#### Scenario: 响应结构与优化前一致

- **WHEN** 调用会话相关接口
- **THEN** 响应 JSON 结构 SHALL 与优化前完全一致
