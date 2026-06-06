## Why

首页骨架和视觉区块已落地，项目需要用户身份识别基建来支撑后续 UGC 功能。auth spec 已完整定义后端契约，但后端尚未实现。为了前端并行推进、尽早验证交互流程，现在先用 mock API 落地登录/注册前端页面，后续后端就绪后仅需替换 mock 层。

## What Changes

- 新增 `/login` 页面：email + password 表单，错误态展示（401/423/403/429）
- 新增 `/register` 页面：两步流程（发送验证码 → 填码+密码注册），错误态展示（400/429）
- 新增 auth store（Zustand）：管理 access_token、user state、登录/登出动作
- 新增 mock API 层：模拟 auth spec 定义的 `/api/auth/*` 端点响应
- 登录成功后跳转回首页

## Capabilities

### New Capabilities

- `auth-frontend`: 登录/注册前端页面 UI、表单验证、错误态展示、mock API 交互、auth 状态管理（Zustand store）

### Modified Capabilities

（无——auth spec 定义的后端契约不变，本次仅实现前端消费层）

## Impact

- **前端代码**：新增 `app/(auth)/login/`、`app/(auth)/register/` 路由页面；新增 `lib/stores/auth.ts`；新增 `lib/mock/auth.ts`
- **新依赖**：`zustand`
- **现有页面**：首页导航可能需要展示登录状态入口（后续变更 scope，本次不涉及）
- **后端**：无影响
