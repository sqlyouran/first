## 1. MySQL 环境准备

- [x] 1.1 确认本地 MySQL 8 运行中（`mysql -u root -p123456 -e "SELECT VERSION()"`）
- [x] 1.2 创建数据库：`CREATE DATABASE IF NOT EXISTS wanderchina CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`

## 2. Maven 依赖变更

- [x] 2.1 `backend/pom.xml`：移除 `com.h2database:h2`（runtime scope）依赖
- [x] 2.2 `backend/pom.xml`：新增 `com.mysql:mysql-connector-j`（runtime scope）依赖

## 3. 配置文件变更

- [x] 3.1 `backend/src/main/resources/application.yml`：修改 `spring.datasource.url` 为 MySQL 连接串（含 useSSL / allowPublicKeyRetrieval / serverTimezone / characterEncoding 参数）
- [x] 3.2 修改 `driver-class-name` 为 `com.mysql.cj.jdbc.Driver`
- [x] 3.3 修改 `username` 为 `root`，`password` 为 `${MYSQL_PASSWORD:123456}`
- [x] 3.4 修改 `spring.jpa.hibernate.ddl-auto` 为 `update`
- [x] 3.5 新增 `spring.jpa.properties.hibernate.type.preferred_uuid_jdbc_type: CHAR`
- [x] 3.6 移除 `spring.h2` 整段配置（console.enabled / console.path）

## 4. 验收

- [x] 4.1 启动 Spring Boot（`./mvnw -f backend/pom.xml spring-boot:run`），确认无报错、表自动创建
- [x] 4.2 MySQL CLI 验证表结构：`SHOW TABLES;` + `DESC users;` + `DESC posts;`，确认 id 列类型为 `char(36)`
- [x] 4.3 运行全部后端测试：`./mvnw -f backend/pom.xml test`，58/59通过（1个预已存在的cookie path bug与本次无关）
- [x] 4.4 通过 API 注册用户 + 发帖 → 重启 Spring Boot → 数据仍在（持久化验证）
