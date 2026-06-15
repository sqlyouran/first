## 1. SpotPostEntity 关联实体

- [x] 1.1 TDD: 编写 SpotPostEntityTest（持久化、联合唯一约束、spotId/postId NOT NULL 校验）
- [x] 1.2 实现 SpotPostEntity（继承 BaseEntity，spotId + postId UUID 字段，spots_posts 表，联合唯一约束）

## 2. SpotPostRepository

- [x] 2.1 TDD: 编写 SpotPostRepositoryTest（findBySpotIdAndDeletedFalse、findByPostIdAndDeletedFalse、existsBySpotIdAndPostIdAndDeletedFalse、逻辑删除过滤）
- [x] 2.2 实现 SpotPostRepository（继承 JpaRepository，3 个查询方法）

## 3. DTO 响应类

- [x] 3.1 实现 SpotPostsResponse（继承 BaseResponse，items: List<PostResponse> + total + page + size）
- [x] 3.2 实现 PostSpotsResponse（继承 BaseResponse，items: List<SpotResponse>）

## 4. SpotPostService 关联查询服务

- [x] 4.1 TDD: 编写 SpotPostServiceTest — getPostsBySpotId（正常分页、DRAFT 过滤、景点不存在 404）
- [x] 4.2 TDD: 编写 SpotPostServiceTest — getSpotsByPostId（返回列表、帖子不存在 404）
- [x] 4.3 实现 SpotPostService（getPostsBySpotId：关联查询 + PostRepository 批量查询 + 状态过滤 + 分页）
- [x] 4.4 实现 SpotPostService（getSpotsByPostId：关联查询 + SpotRepository 批量查询 + 状态过滤）

## 5. Controller 端点

- [x] 5.1 TDD: 编写 SpotController 新增测试 — GET /api/spots/{id}/posts（正常、空列表、404、size 超限 400）
- [x] 5.2 修改 SpotController 新增 GET /api/spots/{id}/posts 端点（注入 SpotPostService）
- [x] 5.3 TDD: 编写 PostController 新增测试 — GET /api/posts/{id}/spots（正常、空列表、404）
- [x] 5.4 修改 PostController 新增 GET /api/posts/{id}/spots 端点（注入 SpotPostService）

## 6. 种子数据

- [x] 6.1 在 data.sql 追加帖子种子数据（至少 5 条 PUBLISHED 帖子，使用固定 UUID）
- [x] 6.2 在 data.sql 追加 spots_posts 关联种子数据（至少 5 条，覆盖多个景点与帖子）

## 7. 集成验证

- [x] 7.1 启动应用，验证 GET /api/spots/{id}/posts 返回关联帖子列表
- [x] 7.2 验证 GET /api/posts/{id}/spots 返回关联景点列表
- [x] 7.3 验证不存在 ID 返回 404，参数越界返回 400
