## 1. SpotStatus 枚举

- [x] 1.1 TDD: 创建 SpotStatus 枚举（DRAFT / PUBLISHED）

## 2. SpotEntity

- [x] 2.1 RED: SpotEntityTest — 基本持久化 + name 非空约束 + slug 唯一约束
- [x] 2.2 GREEN: 实现 SpotEntity（继承 BaseEntity，所有字段）
- [x] 2.3 验证测试通过

## 3. SpotException + GlobalExceptionHandler 扩展

- [x] 3.1 RED: 测试 GlobalExceptionHandler 对 SpotException 的映射
- [x] 3.2 GREEN: 实现 SpotException + GlobalExceptionHandler 新增 handler

## 4. SpotRepository

- [x] 4.1 RED: SpotRepositoryTest — findByDeletedFalse / findByCityIdAndDeletedFalse / findByIdAndDeletedFalse / findByStatusAndDeletedFalseOrderBy 系列
- [x] 4.2 GREEN: 实现 SpotRepository 接口
- [x] 4.3 验证测试通过

## 5. SpotResponse / SpotListResponse / SpotRankingResponse DTO

- [x] 5.1 实现 SpotResponse（详情 DTO，snake_case JsonProperty）
- [x] 5.2 实现 SpotListResponse（分页列表 DTO）
- [x] 5.3 实现 SpotRankingResponse（排行榜 DTO）

## 6. SpotService

- [x] 6.1 RED: SpotServiceTest — listSpots（默认分页 / 城市筛选 / 排序）
- [x] 6.2 RED: SpotServiceTest — getSpot（正常 / 404 / DRAFT 返回 404）
- [x] 6.3 RED: SpotServiceTest — getRanking（rating / heat / bookmark / 无效 type / top 超限）
- [x] 6.4 GREEN: 实现 SpotService（listSpots + getSpot + getRanking）
- [x] 6.5 验证测试通过

## 7. SpotController

- [x] 7.1 RED: SpotControllerTest — GET /api/spots（默认 / city_id 筛选 / sort 参数）
- [x] 7.2 RED: SpotControllerTest — GET /api/spots/{id}（正常 / 404）
- [x] 7.3 RED: SpotControllerTest — GET /api/spots/ranking（rating / heat / bookmark / 无效 type / top 超限）
- [x] 7.4 GREEN: 实现 SpotController（3 个 GET 端点）
- [x] 7.5 验证测试通过

## 8. 种子数据

- [x] 8.1 data.sql 追加 15+ 景点 INSERT IGNORE（覆盖 5+ 城市，含 rating/viewCount/bookmarkCount）

## 9. 集成验证

- [x] 9.1 启动应用，curl 验证 GET /api/spots（默认分页 + 城市筛选 + 排序）
- [x] 9.2 curl 验证 GET /api/spots/{id}（正常 + 404）
- [x] 9.3 curl 验证 GET /api/spots/ranking（3 种 type + 参数校验）
