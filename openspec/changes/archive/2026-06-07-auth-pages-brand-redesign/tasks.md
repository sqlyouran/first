## 1. 新增共享组件

- [x] 1.1 创建 `app/(auth)/_components/BrandLogo.tsx`——Compass icon + "Wanderchina" 文字 Logo 组件，使用 `font-heading` 字体
- [x] 1.2 为 BrandLogo 编写测试（渲染 icon + 文字）
- [x] 1.3 创建 `app/(auth)/_components/AuthPanel.tsx`——CSS 氛围面板组件（深蓝→靖青渐变 + clip-path 山峦剪影 + 星光点缀 + 品牌 tagline "Discover the China beyond postcards."）
- [x] 1.4 为 AuthPanel 编写测试（渲染 tagline 文案 + BrandLogo）
- [x] 1.5 创建 `app/(auth)/_components/StepIndicator.tsx`——两步进度指示器组件，接收 `currentStep` 和 `totalSteps` props，展示 `● ─── ○` 样式 + "Step X of Y" 文字
- [x] 1.6 为 StepIndicator 编写测试（step 1 和 step 2 两种状态渲染正确）

## 2. Auth Layout（Split Layout）

- [x] 2.1 创建 `app/(auth)/layout.tsx`——桌面端左右 50/50（左 AuthPanel + 右 children），移动端上下折叠（顶部精简品牌条 + 下方 children）
- [x] 2.2 为 auth layout 编写测试（渲染 AuthPanel + children slot）

## 3. 登录页面改造

- [x] 3.1 修改 `app/(auth)/login/page.tsx`——去掉外层 `min-h-screen items-center justify-center` wrapper（由 layout 负责），去掉 Card 外壳（表单区已在白底容器内），所有文案改英文
- [x] 3.2 更新 `app/(auth)/login/page.test.tsx`——所有断言中的中文文案改为对应英文

## 4. 注册页面改造

- [x] 4.1 修改 `app/(auth)/register/page.tsx`——去掉外层 wrapper 和 Card 外壳，所有文案改英文，顶部加 StepIndicator 组件
- [x] 4.2 更新 `app/(auth)/register/page.test.tsx`——所有断言中的中文文案改为对应英文，新增 StepIndicator 渲染验证

## 5. 验收

- [x] 5.1 运行全量前端测试 `npm test`，确保全绿
- [x] 5.2 启动 dev server 手动验证登录/注册页桌面端和移动端渲染效果
