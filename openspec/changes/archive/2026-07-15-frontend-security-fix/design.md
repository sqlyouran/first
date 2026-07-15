## Context

前端安全体检发现 4 类问题，严重程度从高到低：

1. **AI 聊天直连后端（高）**：`lib/api/aiChat.ts` 使用 `NEXT_PUBLIC_BACKEND_URL` 从浏览器直接向后端发请求，绕过 Next.js `/api/*` 代理，且不携带认证 Token。这违反了 AGENTS.md 中的 BFF 边界约束，且暴露后端真实地址。
2. **缺少安全响应头（中）**：`next.config.ts` 未配置 CSP、X-Frame-Options 等安全头，XSS 和点击劫持没有第二道防线。
3. **`cover_image` URL 校验可绕过（中）**：`PostForm.tsx` 中的正则校验仅在 UI 层，攻击者可直接调 API 绕过。恶意 URL 被插入 CSS `backgroundImage` 可用于用户追踪或 CSS 注入。
4. **中间件只查 cookie 存在性（中）**：`middleware.ts` 用 `request.cookies.has("refresh_token")` 判断登录态，任何人可伪造 cookie 绕过路由守卫。Edge Runtime 无法做 JWT 验证，这是固有限制。

现有基础设施：`authFetch` 封装了 Bearer Token 注入和 401 自动刷新逻辑；`next.config.ts` 已有 `/api/*` → `localhost:8080/api/*` 的 rewrite 代理规则；`lib/api/aiPostAssist.ts` 已展示了正确的 `authFetch` + 相对路径调用模式，可作为参考。

## Goals / Non-Goals

**Goals:**
- AI 聊天请求走 Next.js 代理路径，携带认证 Token，不再暴露后端地址
- 所有页面响应包含 CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy 安全头
- `cover_image` URL 在 API 客户端层有协议白名单校验，拒绝非 http/https 协议
- 中间件的设计限制在代码注释中文档化

**Non-Goals:**
- 不在后端添加 `cover_image` URL 校验（后端改动另开 change）
- 不在中间件中做 JWT 验证（Edge Runtime 限制，且现有 401 兜底已足够）
- 不引入 DOM 净化库（如 DOMPurify），react-markdown 默认已安全
- 不修改 Mock 数据文件中的测试凭据（不影响生产）
- 不修改头像 URL 校验（后端应负责，前端 `<img src>` 在现代浏览器中已不可执行 JS）

## Decisions

### D1: AI 聊天请求改造——authFetch + 代理路径

**选择**：将 `aiChat.ts` 中的裸 `fetch` 替换为 `authFetch`，URL 从 `${BACKEND_URL}/api/ai/...` 改为相对路径 `/api/ai/...`，移除 `NEXT_PUBLIC_BACKEND_URL` 变量。

**理由**：
- `authFetch` 已封装 Bearer Token 注入和 401 自动刷新，与项目其他 API 调用一致
- 相对路径 `/api/ai/...` 走 `next.config.ts` 的 rewrite 代理，后端地址不暴露给客户端
- `lib/api/aiPostAssist.ts` 已使用此模式（`authFetch("/api/ai/post-assist", ...)`），可参考

**SSE 流式响应兼容性**：Next.js rewrite 代理支持透传 streaming response。`authFetch` 返回原始 `Response` 对象，`aiChat.ts` 中的 `res.body.getReader()` 读取流的方式不需要改变。唯一区别是 `authFetch` 可能因 401 触发一次 token 刷新后再重试，这对 SSE 流来说不会有问题——刷新发生在请求发出前。

**`createConversation` 错误处理**：当前函数无 try/catch，`res.json()` 失败会抛未捕获异常。改造时补充错误处理，返回结构化结果而非裸抛。

**替代方案**：在 `app/api/ai/chat/route.ts` 创建 Route Handler 做 SSE 中继——但 AGENTS.md 明确禁止创建 `app/api/**/route.ts`（BFF 边界约束），否决。

### D2: 安全响应头——在 next.config.ts 中配置

**选择**：在 `next.config.ts` 中添加 `headers()` 配置，返回一组安全响应头。

**头清单**：

| Header | Value | 作用 |
|--------|-------|------|
| Content-Security-Policy | `default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' https: data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'` | 限制资源加载来源，防止 XSS 和点击劫持 |
| X-Frame-Options | `DENY` | 禁止页面被 iframe 嵌套（CSP `frame-ancestors 'none'` 的旧浏览器兼容） |
| X-Content-Type-Options | `nosniff` | 防止 MIME 嗅探 |
| Referrer-Policy | `strict-origin-when-cross-origin` | 跨域请求只泄露 origin 不泄露完整路径 |
| Strict-Transport-Security | `max-age=31536000; includeSubDomains` | 强制 HTTPS（生产环境生效） |

**CSP 策略说明**：
- `'unsafe-inline'` for script-src：Next.js 内联脚本需要（如 `__NEXT_DATA__`）。后续可引入 nonce 收紧
- `'unsafe-inline'` for style-src：Tailwind + shadcn/ui 使用内联样式
- `img-src 'self' https: data:`：允许 https 图片和 data URI（占位图），不允许 `http://` 图片
- `connect-src 'self'`：AJAX 请求只允许同源（走代理），不允许直连外部
- `frame-ancestors 'none'`：等价于 X-Frame-Options: DENY

**为什么 `connect-src 'self'` 足够**：修复 D1 后，AI 聊天也走代理，所有请求都是同源。如果 D1 不修，CSP 的 `connect-src 'self'` 会直接阻断 AI 聊天的直连请求——所以 D1 必须先于 D2 完成。

### D3: `cover_image` URL 校验——API 客户端层第二道防线

**选择**：在 `lib/api/posts.ts` 的 `createPost` 函数中，发送请求前校验 `cover_image` 的 URL 协议。

**校验逻辑**：
```typescript
if (payload.cover_image && !/^https?:\/\/.+/.test(payload.cover_image)) {
  return { status: 0, error: { request_id: "unknown", error_code: "validation_error", message: "Cover image URL must use http or https protocol" } };
}
```

**理由**：
- 前端 UI 层校验（`PostForm.tsx`）可被绕过（直接调 `createPost`）
- 在 API 客户端层加校验，即使 UI 层被绕过也能拦截
- 后端也应做校验，但后端改动不在本 change 范围

**不引入完整 URL 解析库**：YAGNI——正则 `^https?:\/\/.+` 足够拦截 `javascript:`、`data:`、`file:` 等危险协议。完整的 URL 语法校验应由后端负责。

### D4: 中间件限制——文档化而非修复

**选择**：在 `middleware.ts` 中添加注释说明设计决策，不做代码改动。

**理由**：
- Edge Runtime 无法访问数据库或做 JWT 签名验证（无 Node.js crypto 完整支持）
- 当前设计已有兜底：`authFetch` 在 401 时自动重定向到 `/login`
- 中间件的作用是 UX 层面的路由引导，不是安全边界——真正的安全边界在后端 API 鉴权层
- 添加注释让后续开发者理解这个设计决策，避免误以为是 bug

## Risks / Trade-offs

| 风险 | 缓解措施 |
|------|----------|
| CSP `unsafe-inline` for script-src 限制不够严格 | 后续 change 可引入 nonce-based CSP；当前先建立基础 CSP 防线 |
| AI 聊天改走代理后 SSE 流可能有缓冲问题 | Next.js rewrite 代理透传 streaming response；如有问题可在 `next.config.ts` 中调整 proxy 配置 |
| `cover_image` 前端校验仍可被绕过（直接调后端 API） | 后端应做校验（另开 change）；前端校验是深度防御的一环 |
| Strict-Transport-Security 在开发环境（HTTP）不生效 | 该头只在 HTTPS 响应中生效，开发环境无影响 |

## Migration Plan

1. Phase 1（D1）：改造 `aiChat.ts` → 适配测试 → 验证 AI 聊天功能正常
2. Phase 2（D2）：添加安全响应头 → 验证不影响现有功能
3. Phase 3（D3）：添加 URL 校验 → 测试校验逻辑
4. Phase 4（D4）：添加中间件注释
5. 回滚策略：每个 Phase 独立，可单独回滚

## Open Questions

- CSP 是否需要为 AI 聊天的 SSE 连接额外放宽 `connect-src`？（修复 D1 后不需要，SSE 走代理是同源）
- 后端 `cover_image` 校验何时添加？（另开 backend change）
