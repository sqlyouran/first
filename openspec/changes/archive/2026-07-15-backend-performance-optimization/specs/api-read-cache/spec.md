## ADDED Requirements

### Requirement: 帖子列表缓存

`GET /api/posts` SHALL 支持 Redis 缓存，首次请求查数据库后写入缓存，后续请求直接返回缓存数据。

#### Scenario: 缓存命中时不查数据库

- **GIVEN** 缓存中存在 key `cache:posts:list:{sort}:{page}:{size}` 的有效数据
- **WHEN** 调用 `GET /api/posts?sort=latest&page=1&size=20`
- **THEN** SHALL 直接返回缓存数据，不执行数据库查询

#### Scenario: 缓存未命中时查库并写入缓存

- **GIVEN** 缓存中不存在对应 key
- **WHEN** 调用帖子列表接口
- **THEN** SHALL 查询数据库，将结果序列化后写入 Redis，TTL 为 2 分钟

#### Scenario: 创建/更新/删除帖子时清除缓存

- **GIVEN** 帖子列表缓存存在
- **WHEN** 帖子被创建、更新或删除
- **THEN** 所有 `cache:posts:*` 缓存 key SHALL 被清除

### Requirement: 景点列表缓存

`GET /api/spots` SHALL 支持 Redis 缓存。

#### Scenario: 缓存命中时不查数据库

- **GIVEN** 缓存中存在 key `cache:spots:list:{cityId}:{sort}:{page}:{size}` 的有效数据
- **WHEN** 调用景点列表接口
- **THEN** SHALL 直接返回缓存数据

#### Scenario: 缓存 TTL

- **WHEN** 景点列表数据写入缓存
- **THEN** TTL SHALL 为 5 分钟

### Requirement: 城市列表缓存

`GET /api/cities` SHALL 支持 Redis 缓存，城市数据变动频率极低，适合较长 TTL。

#### Scenario: 城市列表缓存命中

- **GIVEN** 缓存中存在 key `cache:cities:list` 的有效数据
- **WHEN** 调用城市列表接口
- **THEN** SHALL 直接返回缓存数据

#### Scenario: 城市列表缓存 TTL

- **WHEN** 城市列表数据写入缓存
- **THEN** TTL SHALL 为 30 分钟

### Requirement: 帖子详情缓存

`GET /api/posts/{slug}` SHALL 支持 Redis 缓存。

#### Scenario: 详情缓存命中

- **GIVEN** 缓存中存在 key `cache:posts:detail:{slug}` 的有效数据
- **WHEN** 调用帖子详情接口
- **THEN** SHALL 直接返回缓存数据

#### Scenario: 帖子更新时清除详情缓存

- **WHEN** 帖子被更新
- **THEN** `cache:posts:detail:{slug}` SHALL 被清除

### Requirement: 景点详情缓存

`GET /api/spots/{slug}` SHALL 支持 Redis 缓存。

#### Scenario: 景点详情缓存命中

- **GIVEN** 缓存中存在 key `cache:spots:detail:{slug}` 的有效数据
- **WHEN** 调用景点详情接口
- **THEN** SHALL 直接返回缓存数据

#### Scenario: 景点详情缓存 TTL

- **WHEN** 景点详情数据写入缓存
- **THEN** TTL SHALL 为 10 分钟

### Requirement: 缓存降级

当 Redis 不可用时，所有缓存接口 SHALL 降级为直接查数据库，不影响正常功能。

#### Scenario: Redis 连接失败

- **GIVEN** Redis 服务不可用
- **WHEN** 调用任意带缓存的接口
- **THEN** SHALL 降级为直接查数据库返回结果，不抛出异常
