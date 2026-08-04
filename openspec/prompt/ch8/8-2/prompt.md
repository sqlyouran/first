```
/opsx:explore

目的：为帖子(posts)模块设计capability spec

1. 参考project.md中"旅行攻略/Story"的定义
   以及auth-backend-api的spec结构
   输出posts的capability spec

2. 帖子数据模型：Markdown富文本
   字段：title/content(Markdown)/coverImage/tags/status
   支持：发布、编辑、列表、详情

3. 接口需要JWT认证（写操作），读操作公开

4. 参考auth spec的WHEN/THEN格式定义验收标准
```

```
/opsx:explore

目的：根据posts spec实现后端CRUD

1. PostEntity继承BaseEntity
   业务字段：authorId/title/content(Markdown)/
   coverImage/tags(JSON)/status(draft|published)

2. 严格遵循三层架构 + DTO分离
   Response继承BaseResponse，禁止返回Entity

3. 写操作（POST/PUT/DELETE）需要JWT认证
   参考AuthController的Bearer token提取模式
   读操作（GET列表/GET详情）公开

4. 遵循backend-conventions + database-conventions
```

```
/opsx:explore

目的：根据posts spec实现前端页面

1. 页面路由（参考(auth)路由分组模式）：
   - app/(posts)/page.tsx → 帖子列表
   - app/(posts)/create/page.tsx → 发布（需登录）
   - app/(posts)/[id]/page.tsx → 详情

2. 选用合适的React Markdown编辑器组件（带工具栏）
   支持标题、Markdown正文、封面图URL、标签输入

3. API封装参考lib/api/auth.ts的
   ApiResponse<T> + parseResponse模式

4. 遵循frontend-conventions + styling-conventions
```