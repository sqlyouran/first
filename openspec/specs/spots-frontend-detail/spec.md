## ADDED Requirements

### Requirement: 景点详情页 SSR 预取

`app/spots/[id]/page.tsx` SHALL 为 Server Component，SSR 阶段并行 fetch 景点详情 + 收藏状态。

#### Scenario: 正常加载

- **GIVEN** 后端 `GET /api/spots/{id}` 返回景点数据，`GET /api/spots/{id}/bookmark-status` 返回收藏状态
- **WHEN** 访问 `/spots/{id}`
- **THEN** Server Component 并行预取两个接口，渲染完整页面（Gallery + 基本信息 + 收藏按钮初始状态）

#### Scenario: 景点不存在

- **WHEN** 后端返回 404
- **THEN** 调用 `notFound()` 显示 404 页面

---

### Requirement: SpotGallery 图片轮播（含缩略图条）

`app/spots/[id]/_components/SpotGallery.tsx` SHALL 为 Client Component，基于 shadcn Carousel 实现主图 + 缩略图条联动。

#### Scenario: 渲染主图

- **GIVEN** 景点 `gallery` 包含 5 张图片
- **WHEN** 渲染 SpotGallery
- **THEN** 主图 Carousel 显示第一张图片（`aspect-[16/9] bg-cover bg-center`），左右箭头可切换

#### Scenario: 渲染缩略图条

- **GIVEN** 景点 `gallery` 包含 5 张图片
- **WHEN** 渲染 SpotGallery
- **THEN** 主图下方显示缩略图条（5 张小图，`aspect-[4/3]`），第一张高亮（`ring-2 ring-blue-700`）

#### Scenario: 主图切换同步缩略图

- **WHEN** 用户点击主图右箭头切换到第 2 张
- **THEN** 缩略图条第 2 张高亮，第 1 张取消高亮

#### Scenario: 点击缩略图跳转主图

- **WHEN** 用户点击缩略图第 3 张
- **THEN** 主图跳转到第 3 张，缩略图第 3 张高亮

#### Scenario: 无图片时显示占位

- **GIVEN** 景点 `gallery` 为空且 `coverImage` 为 null
- **WHEN** 渲染 SpotGallery
- **THEN** 显示渐变占位（`bg-gradient-to-br from-blue-50 via-slate-50 to-blue-100`）+ 居中 MapPin 图标

---

### Requirement: SpotInfo 基本信息两列布局

`app/spots/[id]/_components/SpotInfo.tsx` SHALL 展示景点基本信息，采用两列 grid 布局。

#### Scenario: 渲染基本信息

- **GIVEN** 景点数据包含 cityName、name、nameZh、status、rating、viewCount、bookmarkCount、createdAt
- **WHEN** 渲染 SpotInfo
- **THEN** 两列布局展示：左列 label（`text-sm text-slate-500`）、右列 value（`text-sm text-slate-900`），包含城市、英文名、中文名、状态、评分、浏览、收藏、创建时间

#### Scenario: 评分星级展示

- **GIVEN** 景点 `rating: 4.8`
- **WHEN** 渲染评分行
- **THEN** 显示 Star 图标 + "4.8"（`text-amber-500`）

---

### Requirement: RelatedPosts 相关攻略预留区块

`app/spots/[id]/_components/RelatedPosts.tsx` SHALL 渲染预留区块，不调用 API。

#### Scenario: 渲染预留区块

- **WHEN** 渲染 RelatedPosts
- **THEN** 显示 Card 容器，标题"相关攻略"，内容区显示居中 BookOpen 图标 + "即将上线" 文案（`text-slate-400`）

---

### Requirement: 景点收藏 API 客户端

`lib/api/interactions.ts` SHALL 支持景点收藏 API 调用。

#### Scenario: fetchSpotBookmarkStatus

- **WHEN** 调用 `fetchBookmarkStatus(entityId, "spot")`
- **THEN** 发送 `GET /api/spots/{entityId}/bookmark-status`
- **AND** 返回 `ApiResponse<BookmarkStatusData>`

#### Scenario: toggleSpotBookmark

- **WHEN** 调用 `toggleBookmark(entityId, "spot")`
- **THEN** 发送 `POST /api/spots/{entityId}/bookmark`，使用 `authFetch`
- **AND** 返回 `ApiResponse<BookmarkData>`

---

### Requirement: 景点评论 API 客户端

`lib/api/interactions.ts` SHALL 支持景点评论 API 调用。

#### Scenario: fetchSpotComments

- **WHEN** 调用 `fetchComments(entityId, "spot", page?, size?)`
- **THEN** 发送 `GET /api/spots/{entityId}/comments?page={page}&size={size}`
- **AND** 返回 `ApiResponse<CommentListData>`

#### Scenario: createSpotComment

- **WHEN** 调用 `createComment(entityId, "spot", content, parentCommentId?)`
- **THEN** 发送 `POST /api/spots/{entityId}/comments`，使用 `authFetch`
- **AND** 返回 `ApiResponse<CommentData>`

---

### Requirement: 页面四态覆盖

景点详情页 SHALL 覆盖 Loading / Content / Empty / Error 四种状态。

#### Scenario: Loading 状态

- **WHEN** SSR 预取进行中
- **THEN** 页面渲染 Skeleton 骨架屏（Gallery 区域 + 标题行 + 信息块）

#### Scenario: Content 状态

- **WHEN** 数据加载成功
- **THEN** 渲染完整页面内容

#### Scenario: Empty（无图片）

- **WHEN** 景点 gallery 为空
- **THEN** Gallery 区域显示渐变占位

#### Scenario: Error 状态

- **WHEN** 后端返回 500 或网络错误
- **THEN** 显示错误描述 + 重试按钮
