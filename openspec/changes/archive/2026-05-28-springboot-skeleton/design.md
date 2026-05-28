# Design: SpringBoot Skeleton

## 决策一览

| 决策 | 选择 | 理由 |
|---|---|---|
| 仓库布局 | `backend/` + `frontend/` 并排（monorepo） | 前端 `node_modules` 与后端 `target/` 物理隔离，`.gitignore` 简单；语义对称 |
| Java 版本 | JDK 17 (LTS) | Spring Boot 3.x 最低要求；与团队/CI 镜像最易对齐 |
| 后端框架 | Spring Boot 3.x 当下最新稳定版 | 3.x 是当前主线；具体小版本在 `pom.xml` 中由实施者锁定 |
| 构建工具 | Maven 单模块 | 极简档无须父子 pom；YAGNI，等真要拆模块再开 change |
| 打包形式 | jar（内嵌 Tomcat） | `java -jar` 起服务，免外部容器 |
| Java 包名 | `com.mooc.app` | 由用户在 propose 阶段指定 |
| 后端测试策略 | `@WebMvcTest` 切片为主 | 不全量起 `ApplicationContext`，红绿循环秒级反馈 |
| 前端框架 | Vite + React (JS 模板) | 生态最稳、起项目最快；JS 而非 TS 以贴合「极简」 |
| 前端创建方式 | `npm create vite@latest frontend -- --template react` | 官方脚手架，省去手写模板 |
| 开发期跨域 | Vite dev server `/api` 代理至 `localhost:8080` | 后端代码零改动；生产部署的跨域问题不在本变更范围 |
| 端口约定 | 后端 8080 / 前端 5173 | Spring Boot 与 Vite 默认值，避免无谓发明 |
| Hello 契约 | `GET /api/hello` → `200 text/plain "hello"` | 最小可观测端到端链路；前端 fetch 后渲染同样字符串 |

## 系统结构

```
my-first-project/
├── backend/                       Maven 单模块
│   ├── pom.xml                    Spring Boot 3.x parent
│   └── src/
│       ├── main/java/com/mooc/app/
│       │     ├── AppApplication.java          @SpringBootApplication
│       │     └── HelloController.java         GET /api/hello
│       ├── main/resources/application.yml
│       └── test/java/com/mooc/app/
│             └── HelloControllerTest.java     @WebMvcTest
│
├── frontend/                      Vite + React
│   ├── package.json
│   ├── vite.config.js             proxy /api → :8080
│   ├── index.html
│   └── src/
│       ├── main.jsx
│       └── App.jsx                fetch('/api/hello')
│
├── openspec/  ...
└── README.md / .gitignore / AGENTS.md
```

## 端到端数据流（开发期）

```
   浏览器  ──GET /─────────────▶  Vite dev :5173  (静态资源)
      │
      │   App.jsx 内 fetch('/api/hello')
      ▼
   Vite dev :5173 ──proxy /api──▶  Spring Boot :8080 ──▶ HelloController
                                                            │
                                                            ▼
                                                     "hello" (text/plain)
   浏览器 ◀─────────────────────────────────────── 渲染
```

## 备选方案

**布局甲：根目录直接放 `src/main/java`**——后端 Maven 命令在根目录跑最省事。
拒绝：前端 `node_modules` 与后端源码混在一起，`.gitignore` 与 IDE 索引都难受；语义上暗示这只是个后端项目。

**前端选 Vue / 纯 HTML**——Vue 同样可行；纯 HTML 更"极简"。
拒绝：Vue 与 React 同档无显著差异，按生态体量选 React；纯 HTML 不像"框架"，未来加路由/状态时回炉成本高。

**跨域走后端 CORS 白名单**——`@CrossOrigin` 一行解决。
拒绝：要污染业务代码，且生产环境仍需另行处理；Vite 代理在开发期更干净。本变更明确不解决生产部署。

**Maven 多模块（api/service/dao 拆分）**——大型项目常见。
拒绝：YAGNI，骨架阶段没有任何业务边界需要切分。

**测试统一用 `@SpringBootTest`**——一把梭最简单。
拒绝：每次起完整上下文要数秒，TDD 红绿循环被拖慢；切片测试天然适合 controller 单点。

## 风险

- **Spring Boot 小版本漂移**：`spring-boot-starter-parent` 写错版本会拉到不兼容依赖。
  **缓解**：实施时把版本号写死在 pom，禁止用 `LATEST`/`RELEASE`；版本号在 PR 描述里再确认一次。
- **Node 版本不匹配**：Vite 5 要求 Node ≥ 18；本仓库 `0001` 已升到 v24，但新克隆者可能本地版本旧。
  **缓解**：`README.md` 与 `frontend/package.json` 的 `engines` 字段双写最低 Node 版本。
- **代理不生效，浏览器拿到 HTML 的 404 页**：常见的 Vite proxy 配置失误。
  **缓解**：`tasks.md` 验证步里强制要求"在浏览器里看到 hello"，而非只看后端 200。
- **后端测试静默通过（没真启动 controller）**：`@WebMvcTest` 写错注解，测试空跑。
  **缓解**：先写一个**会失败**的断言（响应体匹配 `"hello"`），亲眼看红，再写实现。

## 不引入

- 任何持久层依赖（H2、JPA、MyBatis 等）
- Lombok（极简档不需要，几行代码不值得引依赖）
- Prettier / ESLint / Checkstyle（纳入下一个 change 再说）
- TypeScript（前端 JS 即可；要 TS 单独提）
- 父 pom / BOM 管理 / 依赖锁定文件（`mvn` 自带 lock 行为暂够用）
