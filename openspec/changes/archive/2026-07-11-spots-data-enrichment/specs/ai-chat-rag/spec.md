## MODIFIED Requirements

### Requirement: 知识库文档构建（ETL Pipeline）

系统 SHALL 在启动时从数据库全量加载平台结构化数据（City / Spot / Post），将其转换为 Spring AI `Document` 对象并写入 Chroma 向量库。每个 Document 包含文本内容与结构化 metadata。

#### Scenario: 城市实体转为 Document

- **GIVEN** 数据库中存在 CityEntity（name="Beijing", nameZh="北京", description="Ancient capital...", bestSeason="Autumn"）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：
  - text = "City: Beijing (北京)\nDescription: Ancient capital with imperial grandeur\nBest Season: Autumn"
  - metadata = `{ "entity_type": "city", "slug": "beijing", "name": "Beijing", "name_zh": "北京" }`

#### Scenario: 景点实体转为 Document（含实用信息字段）

- **GIVEN** 数据库中存在 SpotEntity（name="Forbidden City", cityName="Beijing", tags=["heritage","history"], description="...", rating=4.8, ticketPrice="旺季60元/淡季40元", openingHours="08:30-17:00", address="北京市东城区景山前街4号"）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 生成一个 Document：
  - text = "Spot: Forbidden City (故宫)\nCity: Beijing\nTags: heritage, history\nRating: 4.8\nTicket Price: 旺季60元/淡季40元\nOpening Hours: 08:30-17:00\nAddress: 北京市东城区景山前街4号\nDescription: The world's largest palace complex with 600 years of imperial history"
  - metadata = `{ "entity_type": "spot", "slug": "forbidden-city", "city_name": "Beijing", "tags": "heritage,history", "name": "Forbidden City", "name_zh": "故宫" }`
- **AND** 当 ticketPrice / openingHours / address 为 null 时，对应行 SHALL 被省略（不输出 "Ticket Price: null"）

#### Scenario: 攻略实体转为 Document（按段落切片）

- **GIVEN** 数据库中存在 PostEntity（title="A Week in Beijing", content 含多个段落，tags=["beijing","heritage"]）
- **WHEN** 知识库构建服务执行文档生成
- **THEN** 若 content 长度 ≤ 1000 字符：生成一个 Document
- **AND** 若 content 长度 > 1000 字符：按段落切分为多个 Document，每个 ≤ 800 token，overlap 约 100 token
- **AND** 每个 Document 的 metadata = `{ "entity_type": "post", "slug": "a-week-in-beijing", "title": "A Week in Beijing", "tags": "beijing,heritage" }`

#### Scenario: 仅索引已发布内容

- **GIVEN** 数据库中存在 PostEntity status=DRAFT
- **WHEN** 知识库构建服务执行文档生成
- **THEN** DRAFT 状态的 Post 不被索引到向量库
- **AND** status=DELETED 的实体（逻辑删除）同样不被索引

### Requirement: SpotQueryTool 景点详情输出

`SpotQueryTool.getSpotDetails()` SHALL 在输出文本中包含实用信息字段（门票价格、开放时间、地址），使 AI 助手能够回答用户的实用信息问题。

#### Scenario: 景点详情包含实用信息

- **GIVEN** 数据库中存在 slug="forbidden-city" 的景点，ticketPrice="旺季60元/淡季40元", openingHours="08:30-17:00", address="北京市东城区景山前街4号"
- **WHEN** 调用 `spotQueryTool.getSpotDetails("forbidden-city")`
- **THEN** 返回文本 SHALL 包含 "Ticket Price: 旺季60元/淡季40元"、"Opening Hours: 08:30-17:00"、"Address: 北京市东城区景山前街4号"

#### Scenario: 景点无实用信息时优雅降级

- **GIVEN** 数据库中存在 slug="some-spot" 的景点，ticketPrice=null, openingHours=null, address=null
- **WHEN** 调用 `spotQueryTool.getSpotDetails("some-spot")`
- **THEN** 返回文本 SHALL 不包含 "Ticket Price" / "Opening Hours" / "Address" 行（避免输出 null）
