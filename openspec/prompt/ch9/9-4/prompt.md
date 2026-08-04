```
/opsx:explore

目的：景点排行榜每次请求都查MySQL，想加一层缓存提速

1. 加Redis依赖
   - pom.xml 添加 spring-boot-starter-data-redis

2. 加Redis连接配置
   - application.yml 添加 localhost:6379 的连接信息

3. 新建 RankingCacheService
   - 方法1：查询排行榜缓存
     先从Redis里找有没有缓存的数据
     → 有，直接返回（不用查MySQL了）
     → 没有，调原来的SpotService查数据库
       → 查完后把结果存一份到Redis
       → Redis里这份数据5分钟后自动删除（避免太旧）
   - 方法2：清除排行榜缓存
     景点数据有变化时，把Redis里存的那份删掉

4. 改造SpotService.getRanking()
   - 不再直接查数据库
   - 改为调用RankingCacheService
     让缓存来决定走Redis还是走数据库

5. 缓存key格式：spot:ranking:{type}
   例如：spot:ranking:heat
```