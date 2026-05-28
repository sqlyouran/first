# Proposal: SpringBoot Skeleton（前后端分离极简骨架）

## Why

`0001-bootstrap-project` 留了一道 Open Question——「项目最终用什么语言栈？」。
现在拍板：**Java 17 + Spring Boot 3.x + Maven**（后端）与 **Vite + React**（前端），前后端分离，monorepo 共仓。
这次变更把这套技术栈固化为可运行的最小骨架：`mvn test` 与 `npm run dev` 都能跑通，浏览器看到一句来自后端的 `hello`，作为后续所有业务 change 的起点。

## What Changes

- 在仓库根落地 **`backend/` + `frontend/`** 双工程并排布局：
  - 删除 `src/.gitkeep`，新增 `backend/src/main/java/.gitkeep`
  - `backend/pom.xml`：Spring Boot 3.x 稳定版（`spring-boot-starter-web` + `spring-boot-starter-test`），单模块，jar 打包
  - `backend/src/main/java/com/mooc/app/AppApplication.java`：`@SpringBootApplication` 启动类
  - `backend/src/main/java/com/mooc/app/HelloController.java`：`GET /api/hello` 返回固定文本
  - `backend/src/test/java/com/mooc/app/HelloControllerTest.java`：`@WebMvcTest` 切片测试（先 RED 再 GREEN）
  - `backend/src/main/resources/application.yml`：`server.port=8080`
- 前端工程（**Vite + React** 模板）：
  - `frontend/package.json` + `vite.config.js`：dev server 端口 5173，`/api` 反代到 `http://localhost:8080`
  - `frontend/src/App.jsx`：启动时 `fetch('/api/hello')` 渲染响应
  - `frontend/index.html`、`frontend/src/main.jsx` 等模板文件
- 工程化辅助：
  - 更新根 `.gitignore`：忽略 `backend/target/`、`frontend/node_modules/`、`frontend/dist/`、IDE 元数据
  - 更新 `openspec/project.md` 的「技术栈」小节，回填本次决定
  - 更新根 `README.md`：增加「本地开发」一段（如何起后端、如何起前端、如何跑测试）
- TDD 落地：先写 `HelloControllerTest` 看红 → 再写 controller 看绿 → 不重构（极简档没东西好重构）

## Out of Scope

- 数据库、JPA、Redis、消息队列等任何中间件
- 鉴权、登录、CORS 生产级配置（开发期由 Vite 代理覆盖）
- Swagger/OpenAPI、统一返回体、全局异常处理（YAGNI，等真有第二个接口再说）
- Docker、CI/CD、部署脚本
- 前端组件库、状态管理、路由（默认模板就够用）
- 多模块 Maven、parent pom、依赖锁定策略

## Open Questions

- [ ] Spring Boot 具体小版本号锁定哪一个？（建议在 design.md 决策时选当下最新稳定版）
- [x] Java 包名：采用 `com.mooc.app`（用户在 propose 阶段确认）
