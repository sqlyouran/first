# Proposal: 前端从 Vite 一次性切换到 Next.js（App Router）

## Why

仓库现行前端是 **Vite 8 + React 19** SPA（见 `frontend/`），AGENTS.md「技术选型约束」当前锁定 `React + Vite`。在长期运营场景下出现以下硬性短板，已触发该章节的「重新评估」第 3 条（出现明确可维护性瓶颈）：

1. **SSR / SEO 是 Vite SPA 的硬伤**：Vite 默认产物是客户端 SPA，搜索引擎抓取与首屏 LCP 表现不达标。这一项 Vite 无法通过常规手段解决。
2. **工程约定偏弱**：路由/布局嵌套靠 React Router 手动配置，多人协作下易出现风格漂移。Next.js 的文件路由 + `layout.tsx` 嵌套是社区事实标准。
3. **需要"薄 BFF"层**：未来增加多接口聚合、字段裁剪、SSR 数据预取的诉求。当前 SPA 架构里要么自建 Node 服务，要么把这些逻辑塞进后端，均不优雅。

## What Changes

- **前端工程一次性重建**：废弃当前 Vite 工程，在 `frontend/` 用 Next.js 16（App Router）重建，迁移 `/api/hello` 联通用例。
- **薄 BFF 边界严格约束**：Next.js 仅做 SSR 数据预取、多接口聚合、字段裁剪。**所有写操作、事务、权限校验、业务逻辑仍走 Spring Boot**，不允许业务下沉到 Route Handlers / Server Actions。
- **接口契约**：本变更内手写 TS 接口类型；OpenAPI（springdoc-openapi + openapi-typescript）契约管线**留给单独 change 引入**，避免本次变更范围爆炸（YAGNI，当前只有一个 `/api/hello` 端点）。
- **同步更新治理文档**：
  - `AGENTS.md`「技术选型约束」：锁定栈前端 `React + Vite` → `React + Next.js (App Router)`；禁止动作中明确区分「薄 BFF（允许）」与「业务后端（禁止）」；决定性理由补充 SSR/SEO 维度。
  - `openspec/project.md`「技术栈」：前端框架行更新；端口/工具链同步。
  - `openspec/specs/http-server/spec.md`：Scenario「通过前端 dev server 代理访问」中的 Vite 代理改为 Next.js dev server。
- **TDD 落地**：先写一个 Next.js 页面级 RED 测试（断言页面渲染 `hello`），再写实现转绿。
- **部署形态保持**：前端继续 Vercel；后端继续 Docker 自托管。

## Out of Scope

- 引入 TypeScript 全工程链型化以外的语言切换（本次顺势上 TS，但不引入 tRPC / GraphQL 等额外契约层）。
- 引入 OpenAPI 契约管线（springdoc-openapi、openapi-typescript）—— 留给后续 change，触发条件：业务端点 ≥ 3 个。
- 引入 Tailwind / shadcn-ui / 任何 CSS 框架（YAGNI，骨架阶段保持 vanilla CSS）。
- 引入认证、状态管理、国际化、PWA、ISR/边缘函数等。
- 任何 `backend/` 改动（本变更不动 Spring Boot 代码）。
- 部署到 Vercel 的实际操作（保留为后续 change，本次仅确保可本地起服务）。
- Vite 工程的渐进迁移 / 双栈并行（用户已选定**一次性切换**，旧 Vite 工程整体替换）。

## Open Questions

- [ ] 新前端是 **TypeScript** 还是延用 JavaScript？建议 **TS**：Next.js 官方推荐、AI 生成质量更高、为未来 OpenAPI 类型对齐打基础。需用户在 design 阶段确认。
- [ ] 测试栈选 **Vitest + Testing Library** 还是 Jest？建议 Vitest（与 Next.js 官方文档兼容，启动更快）。
- [ ] 旧 Vite 工程的处理：直接覆盖式重建 `frontend/`，还是保留一个 `frontend.legacy/` 归档目录？建议**直接覆盖**——一次性切换的语义不应留尾巴；归档由 git 历史承载。
