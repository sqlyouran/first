## MODIFIED Requirements

### Requirement: 知识库增量更新单个景点 Document

系统 SHALL 提供按 slug 增量更新 Chroma 向量库中单个景点 Document 的能力，使采集数据刷新后 Chroma 立即反映最新信息，无需等待全量重建。

#### Scenario: 增量更新单个景点 Document

- **GIVEN** Chroma 中存在 slug="forbidden-city" 的 Spot Document（旧数据：ticketPrice="旺季60元"）
- **GIVEN** MySQL 中对应 SpotEntity 的 ticketPrice 已更新为"旺季80元"，`dataRefreshedAt` 已刷新
- **WHEN** 调用 `KnowledgeBuilderService.refreshSpotDocument(spotEntity)`
- **THEN** 系统 SHALL 删除 Chroma 中 metadata.slug="forbidden-city" 的旧 Document
- **AND** 写入新 Document（text 中包含 "Ticket Price: 旺季80元"）
- **AND** 新 Document 的 metadata 与 `toSpotDocument()` 生成规则一致

#### Scenario: 增量更新不存在的景点

- **GIVEN** Chroma 中不存在 slug="new-spot" 的 Document
- **WHEN** 调用 `KnowledgeBuilderService.refreshSpotDocument(spotEntity)`
- **THEN** 系统 SHALL 直接写入新 Document（删除步骤无副作用）
- **AND** 不抛出异常

#### Scenario: 增量更新不影响其他 Document

- **GIVEN** Chroma 中有 50 个 Document
- **WHEN** 对 slug="forbidden-city" 执行 `refreshSpotDocument`
- **THEN** 其他 49 个 Document SHALL 不受影响
- **AND** Chroma 中总 Document 数量保持 50（删 1 写 1）
