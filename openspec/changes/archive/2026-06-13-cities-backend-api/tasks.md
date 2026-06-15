## 1. Entity 层（CityEntity + 测试）

- [x] 1.1 编写 `CityEntityTest`（@DataJpaTest）：验证 BaseEntity 字段自动填充（id / createdAt / updatedAt / deleted=false）、slug UNIQUE 约束冲突抛异常
- [x] 1.2 实现 `entity/CityEntity.java`：继承 BaseEntity，字段 name / nameZh / slug / coverImage / description / bestSeason，getter/setter

## 2. Repository 层（CityRepository + 测试）

- [x] 2.1 编写 `CityRepositoryTest`（@DataJpaTest）：验证 `findByDeletedFalse(Pageable)` 分页返回未删除记录、逻辑删除记录不出现在结果中、`findByIdAndDeletedFalse` 对已删除记录返回 empty
- [x] 2.2 实现 `repository/CityRepository.java`：继承 `JpaRepository<CityEntity, UUID>`，声明 `findByDeletedFalse(Pageable)` 和 `findByIdAndDeletedFalse(UUID)`

## 3. 异常处理（CityException + GlobalExceptionHandler 扩展 + 测试）

- [x] 3.1 实现 `exception/CityException.java`：继承 RuntimeException，持有 HttpStatus / errorCode / message（对齐 PostException 模式）
- [x] 3.2 在 `GlobalExceptionHandler` 中新增 `@ExceptionHandler(CityException.class)` 处理器
- [x] 3.3 编写 `GlobalExceptionHandlerTest`（@WebMvcTest 或 @SpringBootTest）：验证 CityException 被正确映射到 ErrorResponse（status / error_code / message）

## 4. DTO 层（CityResponse + CityListResponse）

- [x] 4.1 实现 `dto/response/CityResponse.java`：继承 BaseResponse，字段 id / name / nameZh / slug / coverImage / description / bestSeason / createdAt / updatedAt，全部 private final + @JsonProperty snake_case
- [x] 4.2 实现 `dto/response/CityListResponse.java`：继承 BaseResponse，字段 items（List\<CityResponse\>）/ total（long）/ page（int）/ size（int）

## 5. Service 层（CityService + 测试）

- [x] 5.1 编写 `CityServiceTest`（@ExtendWith(MockitoExtension.class)）：mock CityRepository，验证 listCities 分页参数转换（page 从 1-based 转 0-based）、size 超过 100 时抛 CityException、结果按 name 升序；验证 getCity 存在时返回 CityResponse、不存在时抛 NOT_FOUND CityException
- [x] 5.2 实现 `service/CityService.java`：注入 CityRepository，实现 `listCities(page, size, requestId)` 和 `getCity(id, requestId)`，包含 size>100 校验和 not_found 异常

## 6. Controller 层（CityController + 测试）

- [x] 6.1 编写 `CityControllerTest`（@WebMvcTest）：mock CityService，验证 `GET /api/cities` 默认参数调用、`GET /api/cities?page=1&size=3` 透传参数、`GET /api/cities/{id}` 存在时 200、不存在时 404、无需 Authorization header
- [x] 6.2 实现 `controller/CityController.java`：@RestController，两个 GET 端点，从 request attribute 取 requestId，委托 CityService

## 7. 种子数据（data.sql + application.yml 配置）

- [x] 7.1 在 `application.yml` 追加配置：`spring.jpa.defer-datasource-initialization: true` 和 `spring.sql.init.mode: always`
- [x] 7.2 创建 `resources/data.sql`：8 条 `INSERT IGNORE INTO cities` 语句（Beijing / Shanghai / Chengdu / Xi'an / Hangzhou / Guilin / Lijiang / Xiamen），字段完整（name / name_zh / slug / cover_image / description / best_season / created_at / updated_at / deleted=false）

## 8. 集成验证

- [x] 8.1 运行全量后端测试（`mvn test`），确认所有新增测试通过、无回归
- [x] 8.2 启动应用，用 curl 验证 `GET /api/cities` 返回 8 条记录（分页结构正确）、`GET /api/cities/{id}` 返回完整详情、`GET /api/cities/{不存在的id}` 返回 404
