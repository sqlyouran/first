```
我的项目是一个AI对话应用，后端 Spring Boot + JPA + MySQL + Flyway。

帮我制定数据库设计规范，需要包含：
- 主键策略（自增 vs UUID vs 雪花，哪个适合我的场景）
- 每张表必须有的公共字段
- 字段约束原则（什么时候NULL什么时候NOT NULL）
- 索引策略（什么情况该加索引）
```

```
基于我的 openspec/specs/ 里的需求描述，帮我设计核心表结构：
- users（用户）
- conversations（对话）
- messages（消息）

先输出ER关系图（哪些是一对多），再输出建表SQL。
遵循刚才定的规范：公共字段、NOT NULL、合理索引。
```


```
帮我制定 Flyway Migration 的管理规则：
- 文件命名规范
- 已发布的文件能不能改
- 每个文件应该做多少事
- 大表变更怎么处理

然后生成第一个 Migration 文件 V1__init_schema.sql，包含刚才设计的三张表。
最后把数据库规范补充到 .qoder/rules/backend.md 里。
```