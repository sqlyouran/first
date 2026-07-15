## Why

前端安全体检发现 4 类问题：AI 聊天模块绕过 BFF 代理直连后端且无认证、缺少 CSP 等安全响应头、用户可控的 `cover_image` URL 仅前端校验可被绕过、中间件仅检查 cookie 存在性不验证有效性。其中 AI 聊天直连后端同时违反了项目 AGENTS.md 中"薄 BFF 边界"的硬约束，是最需要优先修复的问题。

## What Changes

- **修复 AI 聊天直连后端**：`lib/api/aiChat.ts` 当前使用 `NEXT_PUBLIC_BACKEND_URL` 从浏览器直连后端 8080 端口，且使用裸 `fetch` 不携带认证 Token。改为走 Next.js `/api/*` 代理路径，使用 `authFetch` 携带认证，移除 `NEXT_PUBLIC_BACKEND_URL` 依赖
- **添加安全响应头**：`next.config.ts` 当前只配置了 rewrites，缺少 CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy、Strict-Transport-Security 等安全头。添加 `headers()` 配置
- **加固 `cover_image` URL 校验**：`PostForm.tsx` 中的前端校验可被绕过（直接调 API）。在前端 API 客户端层 `lib/api/posts.ts` 的 `createPost` 函数中增加 URL 协议白名单校验作为第二道防线（后端也应校验，但后端改动不在本 change 范围内）
- **文档化中间件限制**：`middleware.ts` 仅检查 `refresh_token` cookie 是否存在，不验证有效性。这是 Edge Runtime 的固有限制。在代码中添加注释说明设计决策，并确认现有 `authFetch` 的 401 自动重定向机制已作为兜底

## Capabilities

### New Capabilities

- `frontend-security-hardening`: 前端安全加固——AI 聊口认证修复、安全响应头、URL 校验加固、中间件限制文档化

### Modified Capabilities

_无。本次变更不修改已有 capability 的需求级行为，API 契约不变。_

## Impact

- **前端修改**：`lib/api/aiChat.ts`（重写请求方式）、`next.config.ts`（添加 headers 配置）、`lib/api/posts.ts`（增加 URL 校验）、`middleware.ts`（添加注释）
- **前端测试**：`lib/stores/aiChat.test.ts`（适配新的请求方式）、新增安全头测试、新增 URL 校验测试
- **环境变量**：移除 `NEXT_PUBLIC_BACKEND_URL` 的使用（`aiChat.ts` 改走代理后不再需要）
- **API 契约**：无变化
- **后端**：无变化（后端 URL 校验如需加固应另开 change）
