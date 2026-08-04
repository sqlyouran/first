```
我正在开发WanderChina首页。首页包含以下功能区域：

1. Hero区：品牌主视觉背景图 + 品牌标语"Discover China Like a Local" + 副标题"Your AI-powered travel companion for exploring China" + 搜索框（placeholder: "Search destinations, tips, or ask AI..."）
2. 功能导航栏：三大平台入口卡片——旅游社区（图标+标题+一句话描述）、景点攻略（图标+标题+一句话描述）、AI助手（图标+标题+一句话描述）
3. 热门目的地推荐：4-6张卡片，每张含封面图+城市名+一句话亮点+热度标签
4. 社区精选：3-4条UGC帖子摘要（头像+用户名+标题+摘要+点赞数）
5. AI助手悬浮入口：右下角固定悬浮按钮，点击展开迷你对话窗

请将这个页面拆分为独立的Spec开发单元。
拆分标准：每个单元可独立开发、独立测试、独立交付。
输出格式：
- 文件名（specs/homepage-xxx.md）
- 一句话描述
- 该单元的数据依赖（静态/需要API）
- 与其他单元的依赖关系（有/无）
```

```
好的，这个拆分方案我接受。

现在请为第一个单元 homepage-hero 生成完整的Spec文档。

文档结构要求：
1. 模块边界（包含什么功能、不包含什么功能）
2. 核心场景（用WHEN/THEN/AND格式，覆盖正常路径+异常路径）
3. 数据结构（组件Props定义、含类型与约束）
4. 验收标准（ACCEPTANCE Checklist，可勾选）

技术约束：
- React 18 + Next.js 14 App Router
- 样式用Tailwind CSS + shadcn/ui组件
- 响应式设计（mobile-first）
- 图片用next/image优化

输出为Markdown格式，保存为 specs/homepage-hero.md
```