## Context

Wanderchina 面向境外旅行者，首页已有完整的品牌视觉语言（全幅 Hero + 渐变遮罩 + Plus Jakarta Sans 粗体标题 + blue-700 主色调 + slate 灰色系）。登录/注册页面功能已就绪（表单逻辑、校验、错误处理、mock API、auth store），但视觉是通用 SaaS 风格（纯白背景 + 居中 Card + 中文文案），与产品品牌严重割裂。

技术栈约束：Tailwind CSS 4 + shadcn/ui + lucide-react，不引入外部 CSS 方案。

## Goals / Non-Goals

**Goals:**

- 登录/注册页面与首页品牌视觉一致：Split Layout + CSS 氛围背景
- 所有用户可见文案改为英文（与产品面向境外用户的定位一致）
- 注册页新增步骤指示器增强 UX
- 移动端保留精简品牌氛围（顶部渐变条）
- 新增可复用的文字 Logo 组件

**Non-Goals:**

- 不改变任何功能行为（表单逻辑、校验规则、错误处理、API 调用）
- 不引入真实摄影图片（纯 CSS 实现氛围背景）
- 不改变路由结构（仍为 `/login` + `/register`）
- 不实现 dark mode 适配（后续变更）
- 不修改 auth store 或 mock API 层

## Decisions

### 1. 页面布局：Split Layout + Auth Layout 组件

**选择**：新增 `app/(auth)/layout.tsx` 共享布局，桌面端左右 50/50 分割（左氛围面板 + 右表单区），移动端折叠为上下结构。

**替代方案**：Full-bleed 背景 + 浮动卡片居中

**理由**：
- Split Layout 在桌面端品牌展示面积更大（50% vs 卡片周围少量可见背景）
- 表单区保持白底高对比度，可读性与表单交互体验更好
- 行业惯例（Vercel / Linear / Notion 登录页均采用 Split 或类似方案）
- 移动端折叠为顶部品牌条 + 全宽表单，比 Full-bleed 背景上的浮动卡片更适合小屏

### 2. 氛围面板：纯 CSS 实现

**选择**：用 Tailwind 的 gradient + clip-path（或 SVG 内联）实现"夜空山峦"意境

视觉构成：
- 底色：`from-slate-900 via-blue-950 to-indigo-950` 深色渐变
- 山峦：底部 clip-path polygon 或内联 SVG path，层叠 2-3 层不同透明度
- 星光：几个 `radial-gradient` 小圆点（或用 `after` 伪元素）
- 远方光晕：一个 `bg-amber-500/10` 的大模糊圆（模拟城市灯火）

**替代方案**：使用 Unsplash 真实照片

**理由**：
- 零外部依赖，无加载延迟，无版权风险
- 完美适配任何视口尺寸
- 与首页 Hero gradient overlay 设计语言一致
- 后续可随时增加/替换为真实摄影

### 3. Logo 组件：文字 Logo

**选择**：`Compass` icon (lucide-react) + "Wanderchina" 文字，字体用 `font-heading`（Plus Jakarta Sans）

**理由**：
- 项目当前无图形 Logo 资源
- lucide 的 Compass 与旅行探索主题契合
- 文字 Logo 复用项目已有的 heading 字体，品牌感一致
- 后续如有图形 Logo 可直接替换

### 4. 文案策略：全英文

**选择**：按钮、占位符、错误信息、链接文案全部改为英文

**文案对照表**：

| 当前中文 | 改后英文 |
|---------|---------|
| 登录 | Sign In |
| 登录中... | Signing in... |
| 邮箱 | Email address |
| 密码 | Password |
| 请输入有效的邮箱地址 | Please enter a valid email address |
| 请输入密码 | Please enter your password |
| 邮箱或密码错误 | Invalid email or password |
| 账户已锁定，请于 {time} 后重试 | Account locked. Please try again after {time} |
| 邮箱未验证，请先完成验证 | Email not verified. Please verify your email first |
| 请求过于频繁，请稍后重试 | Too many requests. Please try again later |
| 网络连接失败，请检查网络后重试 | Network error. Please check your connection |
| 服务暂时不可用，请稍后重试 | Service temporarily unavailable. Please try again later |
| 没有账号？ | Don't have an account? |
| 去注册 | Sign up |
| 注册 | Create Account |
| 注册中... | Creating account... |
| 发送验证码 | Send Code |
| 发送中... | Sending... |
| 重新发送 (Xs) | Resend (Xs) |
| 验证码 | Verification code |
| 密码（至少 8 位） | Password (min. 8 characters) |
| 请输入验证码 | Please enter the verification code |
| 密码长度不能少于 8 位 | Password must be at least 8 characters |
| 验证码错误，请重新输入 | Invalid code. Please try again |
| 验证码已过期，请重新发送 | Code expired. Please resend |
| 该邮箱已注册，请直接登录 | Email already registered. Please sign in |
| 重新发送 | Resend |
| 已有账号？ | Already have an account? |
| 去登录 | Sign in |
| 验证码已发送至 {email} | Code sent to {email} |

### 5. 注册步骤指示器

**选择**：两步圆点指示器 `● ─── ○`，放在表单顶部（CardHeader 内），带文字标注 "Step 1 of 2" / "Step 2 of 2"

**理由**：
- 让用户清楚知道注册流程有多少步、当前在哪步
- 简洁不抢表单焦点

### 6. 组件拆分策略

```
app/(auth)/
├── layout.tsx          ← NEW: Split Layout 外壳
├── _components/
│   ├── AuthPanel.tsx   ← NEW: 左侧/顶部氛围面板
│   ├── BrandLogo.tsx   ← NEW: 文字 Logo
│   └── StepIndicator.tsx ← NEW: 注册步骤指示器
├── login/
│   └── page.tsx        ← MODIFY: 去掉外层布局wrapper，文案改英文
└── register/
    └── page.tsx        ← MODIFY: 去掉外层布局wrapper，文案改英文，加 StepIndicator
```

## Risks / Trade-offs

- **[测试断言全量更新]** → 文案中英切换导致测试中所有 `getByText` / `getByRole` / `getByPlaceholderText` 断言需同步修改。风险可控：逐测试更新，改一条验一条。
- **[CSS 氛围面板跨浏览器]** → clip-path polygon 在现代浏览器支持良好（Can I Use > 97%），不需要 fallback。
- **[移动端品牌条高度]** → 120px 固定高度可能在极小屏（<360px）显得压迫。实际实现时用 `min-h-[120px] max-h-[30vh]` 限制。
