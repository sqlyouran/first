# http-server Specification

## Purpose

定义本仓库 HTTP 服务的端到端契约：后端 Spring Boot 暴露的 API 端点、前端 Next.js Server Component 通过薄 BFF（`frontend/lib/backend.ts`）SSR 预取后端数据、以及后端测试切片对端点的覆盖方式。骨架阶段仅声明一个 `GET /api/hello` 联通契约，业务端点按各自 change 增量补充。

## Requirements

### Requirement: 后端必须暴露 `GET /api/hello` 端点

The backend service SHALL expose a `GET /api/hello` endpoint that returns HTTP `200 OK` with plain-text body `hello` once the Spring Boot application is started and listening on port 8080.
此端点是骨架阶段唯一的契约，用来验证 Maven 后端、Spring Boot Web 以及前端 Next.js Server Component SSR 预取三段链路在开发期可端到端联通。后续业务端点不在本 spec 范围。

#### Scenario: 直接访问后端

- **GIVEN** Spring Boot 应用已通过 `mvn -f backend/pom.xml spring-boot:run` 启动并监听 8080 端口
- **WHEN** 客户端发送 `GET http://localhost:8080/api/hello`
- **THEN** 响应状态码为 `200`
- **AND** 响应体为文本字符串 `hello`

#### Scenario: 通过前端 Next.js SSR 调后端访问

- **GIVEN** 后端已在 8080 启动
- **AND** 前端 `npm run dev` 已在 3000（或 fallback 端口）启动，`frontend/.env.local` 包含 `BACKEND_URL=http://localhost:8080`
- **WHEN** 浏览器加载 `http://localhost:3000/`，`app/page.tsx`（Server Component）调用 `fetchFromBackend('/api/hello')`
- **THEN** Next.js Server Component 在服务端拼 `BACKEND_URL + /api/hello` 后端 fetch（无 CORS）
- **AND** SSR 返回的初始 HTML 中包含 `<h1>hello</h1>`（验证 SSR 生效，非 hydrate 后才出现）

#### Scenario: 后端测试切片覆盖该端点

- **GIVEN** 后端测试类 `HelloControllerTest` 使用 `@WebMvcTest(HelloController.class)` 注解
- **WHEN** 运行 `mvn -f backend/pom.xml test`
- **THEN** 测试用例通过 `mockMvc.perform(get("/api/hello"))` 断言响应状态 `200` 且响应体等于 `hello`
- **AND** 该测试在没有 `HelloController` 时必须先失败（RED），实现后再通过（GREEN）

#### Scenario: 前端 Client Component 单测覆盖呈现逻辑

- **GIVEN** 前端测试文件 `frontend/app/HelloMessage.test.tsx` 使用 Vitest + @testing-library/react
- **WHEN** 运行 `cd frontend && npm test`
- **THEN** `render(<HelloMessage message="hello" />)` 后 h1 文本为 `hello`
- **AND** 该测试在没有 `HelloMessage.tsx` 时必须先失败（RED），实现后再通过（GREEN）
