## Why

登录/注册页是新用户认知 Wanderchina 品牌的第一触点。当前页面是纯白背景 + 居中 Card 的通用 SaaS 表单风格，与首页的旅行探索沉浸感完全割裂——像两个不同产品。

Wanderchina 面向境外旅行者，首页通过全幅 Hero、渐变遮罩、粗体标题和蓝色主色调传达"探索冒险"情绪。登录/注册页应延续这种品牌一致性，让用户在身份验证环节感受到"旅途即将开始的期待感"。

此外，当前页面文案为中文，与产品英文优先（面向境外用户）的内容策略不一致。

## What Changes

- 重构登录/注册页面为 Split Layout（桌面左右 50/50 分割，移动端上下折叠）
- 左侧/顶部新增 CSS 品牌氛围面板（深蓝→靛青渐变 + 抽象山峦剪影 + 星光点缀）
- 新增文字 Logo 组件（Compass icon + "Wanderchina"）
- 所有文案改为英文
- 注册页新增两步进度指示器（● ○ 样式）
- 移动端保留精简品牌条（~120px）

## Capabilities

### Modified Capabilities

- `auth-frontend`: 登录/注册页面 UI 样式重构——从通用表单升级为品牌一致的 Split Layout，文案改英文，增加氛围面板与进度指示器

## Impact

- **前端代码**：修改 `app/(auth)/login/page.tsx`、`app/(auth)/register/page.tsx`；可能新增共享布局组件 `app/(auth)/layout.tsx` 或氛围面板组件
- **新依赖**：无（纯 Tailwind CSS + lucide-react 已有图标）
- **测试**：更新登录/注册页面测试中的文案断言（中文→英文）
- **后端**：无影响
- **功能行为**：不变——仅视觉与文案重构，所有表单逻辑、校验、错误处理保持不变
