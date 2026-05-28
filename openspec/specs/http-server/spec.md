# http-server Specification

## Purpose

定义本仓库 HTTP 服务的端到端契约：后端 Spring Boot 暴露的 API 端点、前端 Vite dev server 的代理转发、以及后端测试切片对端点的覆盖方式。骨架阶段仅声明一个 `GET /api/hello` 联通契约，业务端点按各自 change 增量补充。

## Requirements

### Requirement: 后端必须暴露 `GET /api/hello` 端点

The backend service SHALL expose a `GET /api/hello` endpoint that returns HTTP `200 OK` with plain-text body `hello` once the Spring Boot application is started and listening on port 8080.
此端点是骨架阶段唯一的契约，用来验证 Maven 后端、Spring Boot Web 以及前端 Vite 代理三段链路在开发期可端到端连通。后续业务端点不在本 spec 范围。

#### Scenario: 直接访问后端

- **GIVEN** Spring Boot 应用已通过 `mvn -f backend/pom.xml spring-boot:run` 启动并监听 8080 端口
- **WHEN** 客户端发送 `GET http://localhost:8080/api/hello`
- **THEN** 响应状态码为 `200`
- **AND** 响应体为文本字符串 `hello`

#### Scenario: 通过前端 dev server 代理访问

- **GIVEN** 后端已在 8080 启动
- **AND** 前端 `npm run dev` 已在 5173 启动并加载了 `vite.config.js` 中的 `/api → http://localhost:8080` 代理
- **WHEN** 浏览器加载 `http://localhost:5173/`，`App` 组件挂载并触发 `fetch('/api/hello')`
- **THEN** Vite dev server 将该请求代理到后端
- **AND** 页面 DOM 中出现文本 `hello`

#### Scenario: 测试切片覆盖该端点

- **GIVEN** 后端测试类 `HelloControllerTest` 使用 `@WebMvcTest(HelloController.class)` 注解
- **WHEN** 运行 `mvn -f backend/pom.xml test`
- **THEN** 测试用例通过 `mockMvc.perform(get("/api/hello"))` 断言响应状态 `200` 且响应体等于 `hello`
- **AND** 该测试在没有 `HelloController` 时必须先失败（RED），实现后再通过（GREEN）
