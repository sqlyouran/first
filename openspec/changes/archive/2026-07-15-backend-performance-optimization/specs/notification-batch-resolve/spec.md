## ADDED Requirements

### Requirement: 通知列表批量预取用户信息

`GET /api/notifications` SHALL 通过批量查询获取所有通知涉及的 actor 用户信息（nickname、avatarUrl、username），而非逐条查询。

#### Scenario: 20 条通知的 actor 信息查询次数

- **GIVEN** 当前页有 20 条通知，涉及 5 个不同的 actor
- **WHEN** 调用 `GET /api/notifications?page=1&size=20`
- **THEN** 用户信息查询 SHALL 最多执行 1 次（批量 `findAllById`），而非 60 次（每条通知 3 次）

#### Scenario: 同一 actor 多条通知不重复查询

- **GIVEN** 10 条通知来自同一个 actor
- **WHEN** 调用通知列表接口
- **THEN** 该 actor 的信息 SHALL 只查询 1 次并复用

### Requirement: 通知列表批量预取帖子标题

`GET /api/notifications` SHALL 通过批量查询获取所有通知涉及的 target 帖子标题，而非逐条查询。

#### Scenario: 通知关联的帖子标题批量查询

- **GIVEN** 当前页有 15 条通知关联了不同的帖子
- **WHEN** 调用通知列表接口
- **THEN** 帖子标题查询 SHALL 最多执行 1 次（批量 `findAllByIdIn`）

#### Scenario: entityId 为 null 的通知不触发查询

- **GIVEN** 通知的 entityId 为 null
- **WHEN** 构建通知响应
- **THEN** targetTitle SHALL 为 null，不触发数据库查询

### Requirement: API 响应格式不变

通知列表的 API 响应字段和格式 SHALL 保持不变，仅优化内部查询实现。

#### Scenario: 响应结构与优化前一致

- **WHEN** 调用 `GET /api/notifications`
- **THEN** 响应 JSON 结构 SHALL 与优化前完全一致
