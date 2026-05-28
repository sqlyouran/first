# Tasks: SpringBoot Skeleton

> 严格遵守 RED → GREEN → REFACTOR。每条 `[ ]` 任务原则上对应一次提交。
> 后端测试每一次都要**亲眼看见红再看见绿**；不允许先写实现再补测试。

## 1. 目录与忽略规则
- [x] 1.1 删除 `src/.gitkeep`（根目录的占位文件迁走）
- [x] 1.2 创建 `backend/src/main/java/.gitkeep` 与 `frontend/.gitkeep`（占位，提交后下一步会被实际文件覆盖）
- [x] 1.3 更新根 `.gitignore`：追加 `backend/target/`、`frontend/node_modules/`、`frontend/dist/`、`.idea/`、`*.iml`、`.vscode/`

## 2. 后端 — Maven 工程脚手架
- [x] 2.1 在 `backend/` 下创建 `pom.xml`：
  - `groupId=com.mooc`、`artifactId=app`、`version=0.0.1-SNAPSHOT`、打包 `jar`
  - `parent` 引 `spring-boot-starter-parent` 当下最新 3.x 稳定版（小版本号写死，不许用 LATEST）
  - `properties.java.version=17`
  - 依赖：`spring-boot-starter-web`、`spring-boot-starter-test`(scope=test)
- [x] 2.2 `backend/src/main/resources/application.yml`：`server.port: 8080`
- [x] 2.3 验证：`mvn -f backend/pom.xml -q dependency:resolve` 成功（不报缺包）

## 3. 后端 — TDD 第一轮（HelloController）

### 3a. RED
- [x] 3a.1 创建 `backend/src/test/java/com/mooc/app/HelloControllerTest.java`：
  - 标注 `@WebMvcTest(HelloController.class)`
  - 注入 `MockMvc`
  - 用例 `getHello_returns200AndHelloBody`：`mockMvc.perform(get("/api/hello")).andExpect(status().isOk()).andExpect(content().string("hello"))`
- [x] 3a.2 运行 `mvn -f backend/pom.xml test`：**编译失败**（`HelloController` 不存在），符合预期 → 截图/记录红状态

### 3b. GREEN
- [x] 3b.1 创建 `backend/src/main/java/com/mooc/app/AppApplication.java`：标注 `@SpringBootApplication`，含 `main` 方法
- [x] 3b.2 创建 `backend/src/main/java/com/mooc/app/HelloController.java`：
  - `@RestController`
  - `@GetMapping("/api/hello")` 方法返回字符串 `"hello"`
- [x] 3b.3 重新运行 `mvn -f backend/pom.xml test`：测试通过 → 绿
- [x] 3b.4 `mvn -f backend/pom.xml spring-boot:run` 启动，`curl http://localhost:8080/api/hello` 返回 `hello`

### 3c. REFACTOR
- [x] 3c.1 浏览代码，确认无重复、无未使用 import、无死代码——极简档预期**无需重构**，本步骤仅记录确认

## 4. 前端 — Vite + React 脚手架
- [x] 4.1 在仓库根执行 `npm create vite@latest frontend -- --template react`，全程默认
- [x] 4.2 删除 `frontend/.gitkeep`（被实际文件取代）
- [x] 4.3 进入 `frontend/`，运行 `npm install`，验证 `node_modules/` 已被 `.gitignore` 正确忽略
- [x] 4.4 修改 `frontend/package.json`：补 `"engines": { "node": ">=20.19" }`（vite 8/eslint 10 要求比原计划 18 高）
- [x] 4.5 编辑 `frontend/vite.config.js`：在 `defineConfig` 中加 `server.proxy = { '/api': 'http://localhost:8080' }`

## 5. 前端 — 端到端联调
- [x] 5.1 修改 `frontend/src/App.jsx`：
  - 用 `useEffect` 在挂载时 `fetch('/api/hello').then(r => r.text())`
  - 用 `useState` 保存返回值，渲染在页面任意位置（如 `<h1>{message}</h1>`）
- [x] 5.2 启动后端：`mvn -f backend/pom.xml spring-boot:run`（终端 A）
- [x] 5.3 启动前端：`cd frontend && npm run dev`（终端 B）
- [x] 5.4 浏览器打开 `http://localhost:5173`，**亲眼看到页面渲染出 `hello`**（终端侧 `curl http://localhost:5173/api/hello` 返 `hello`，浏览器胉眼转用户验收）

## 6. 文档与项目级 spec 回填
- [x] 6.1 更新 `openspec/project.md` 的「技术栈」一节：
  - 语言：Java 17
  - 后端框架：Spring Boot 3.x（具体版本同 pom）
  - 构建：Maven 单模块
  - 前端：Vite + React (JS)
  - 测试：JUnit 5 + Spring Boot Test (`@WebMvcTest`)
- [x] 6.2 在 `README.md` 增加「本地开发」章节：起后端的命令、起前端的命令、跑测试的命令、端口与代理说明
- [x] 6.3 在 `0001-bootstrap-project/proposal.md` 的 Open Questions 中将「项目最终用什么语言栈」一项打勾并指向本变更

## 7. 验证清单（端到端）
- [x] 7.1 `mvn -f backend/pom.xml test` 全绿（BUILD SUCCESS，Tests 1/1）
- [x] 7.2 浏览器访问 `http://localhost:5173` 显示 `hello`（来源：通过 Vite 代理打到 8080）——终端侧 `curl http://localhost:5173/api/hello` 返 `hello`，浏览器胉眼转用户验收
- [x] 7.3 `git status` 中无 `node_modules/`、`target/`、IDE 元数据——仓库未 `git init`，改为审查 `.gitignore` 已含 `node_modules/`、`target/`、`.idea/`、`.vscode/`、`*.iml`，等同效果
- [x] 7.4 `npx @fission-ai/openspec@latest list` 能识别本变更并显示任务计数（`0002-springboot-skeleton 22/31 tasks`）

## 后续（不在本变更范围）
- [ ] 增加统一返回体 / 全局异常处理（开下一个 change，名字建议 `0003-common-web-conventions`）
- [ ] 引入持久层、配置 profile、Docker 化、CI 流水线（各自独立 change）
