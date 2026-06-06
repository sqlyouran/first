## 1. 依赖与项目结构

- [x] 1.1 安装 zustand 依赖 (`npm install zustand`)
- [x] 1.2 创建 `app/(auth)/` 路由组目录结构（login/page.tsx, register/page.tsx）

## 2. Mock API 层

- [x] 2.1 创建 `lib/mock/auth.ts`，实现 mockLogin / mockSendCode / mockRegister 函数，覆盖 spec 定义的各状态码响应
- [x] 2.2 创建 `lib/api/auth.ts`，导出 login / sendCode / register 函数（当前指向 mock 实现）
- [x] 2.3 为 mock 函数编写单元测试

## 3. Auth Store

- [x] 3.1 创建 `lib/stores/auth.ts`，实现 Zustand store（accessToken, isAuthenticated, setToken, logout）
- [x] 3.2 为 auth store 编写单元测试（登录后更新、登出清空）

## 4. 登录页面

- [x] 4.1 创建 `app/(auth)/login/page.tsx`——email + password 表单 UI（shadcn/ui Card + Input + Button）
- [x] 4.2 实现表单前端校验（email 格式、password 非空）
- [x] 4.3 实现提交逻辑：调用 auth API → 成功存 token + 跳转首页
- [x] 4.4 实现错误态展示（401/423/403/429 各场景提示文案）
- [x] 4.5 为登录页面编写测试（成功跳转、各错误态展示）

## 5. 注册页面

- [x] 5.1 创建 `app/(auth)/register/page.tsx`——Step 1: 邮箱输入 + 发送验证码按钮
- [x] 5.2 实现 Step 1 逻辑：调用 sendCode → 成功切换到 Step 2 + 60s 倒计时
- [x] 5.3 实现 Step 2 UI：验证码 + 密码输入 + 提交按钮
- [x] 5.4 实现 Step 2 逻辑：调用 register → 成功跳转 /login + 显示成功提示
- [x] 5.5 实现注册错误态展示（400 invalid_code / expired_code、429）
- [x] 5.6 实现注册表单前端校验（email 格式、验证码非空、密码 ≥ 8 位）
- [x] 5.7 为注册页面编写测试（两步流程、各错误态）

## 6. 验收

- [x] 6.1 运行全量前端测试 `npm test`，确保全绿
- [x] 6.2 手动验证 `/login` 和 `/register` 页面渲染正常、交互流程完整
