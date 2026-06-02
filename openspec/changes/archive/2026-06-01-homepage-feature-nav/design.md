## Context

`homepage-shell` 已落地的 6 个 region 容器中，`feature-nav` 是首个被注入实际内容的目标。本变更 scope 极小（单文件改写 + 单文件新增），主要**不是**为了功能本身，而是为了：

1. 跑通"区块内容注入"工作流，让后续 5 个区块可以同形复用
2. 验证「打破骨架空容器约束」时 OpenSpec delta 的写法是否清晰
3. 在最低复杂度下确认 BFF 边界守护、构建、测试链路全部不受影响

当前用户旅游业务尚未明确，所有 item 均为占位（label 可为通用词、href 全部 `#`）。后续接入后端或本地配置由独立 propose 启动。

## Goals / Non-Goals

**Goals:**
- 用最少的代码（≤ 30 行 component + ≤ 10 行 data）让 feature-nav region 从空变为含至少 1 个可见 `<a>` 子节点
- 数据来源：硬编码 TS 常量数组（`FeatureNavItem[]`）；不引入任何依赖、不动 lib/backend
- 测试覆盖：FeatureNavSlot 单元测试断言 region 节点 + 至少 1 个 `<a>` 子节点
- 治理：archive 时同步 `homepage-shell` 主 spec，将 feature-nav 从"完全空容器"约束中移除

**Non-Goals:**
- ❌ 设计图标系统、icon 映射规则
- ❌ 设计响应式 grid / 视觉规范
- ❌ 接后端或本地 JSON / config 数据源（属于后续独立 propose）
- ❌ 创建 `/flights` `/hotels` 等业务路由（YAGNI，全部 `#`）
- ❌ 解除其它 4 个页内 Slot 或 ai-launcher 的"空容器"约束
- ❌ 引入 shadcn/ui 或新组件库

## Decisions

### D1：数据存放位置 = `frontend/app/regions/featureNav.data.ts`

**选项：**
- A. 与组件同文件内常量（slot.tsx 顶部）
- B. 同目录独立 `featureNav.data.ts`（**选定**）
- C. `frontend/lib/data/featureNav.ts`（顶层 lib）

**理由：**
- 与组件同目录便于一起维护；DRY 原则下后续接数据源切换时仅替换该文件
- 不放 `lib/`：lib 是面向跨 region 共享的位置，feature-nav data 当前只服务于 FeatureNavSlot，YAGNI

### D2：FeatureNavItem 字段 = `{ label: string; href: string }`

**理由：**
- 当前唯一可见展示 = 文字，唯一可交互行为 = 链接占位。无 icon、无 description、无 group。
- YAGNI：后续真要加字段时再加，不预留。

### D3：item 数量 = 至少 1 项（不强制 5/8 项）

**理由：**
- 用户已选「不限项目占位主」选项；spec 只要求 `length >= 1`，给后续扩展留弹性，不锁数字
- 避免 spec 过早绑定具体业务清单

### D4：渲染元素 = `<a>` 而非 `<button>` / 自定义组件

**理由：**
- 语义最准确（导航 = 链接）
- href `#` 不会触发实际跳转，符合占位需求
- 浏览器原生 keyboard / a11y 支持开箱即用

### D5：homepage-shell 主 spec 的 delta 形态 = MODIFIED（约束收窄）

**目标 Requirement：** "所有 Slot 必须为完全空容器"
**delta 形态：** MODIFIED + 重写 Requirement 文本，把 FeatureNavSlot 从「必须为空」对象集合中移除；新增子条款"FeatureNavSlot 的内容契约见 `homepage-feature-nav` 主 spec"

**理由：**
- 不能用 REMOVED：其它 4 个页内 Slot 与 ai-launcher 仍需保留该约束
- MODIFIED 比"加例外脚注"更清晰可追

### D6：测试策略 = 单元 + 不做 SSR / curl 验证

**理由：**
- 数据完全静态，SSR 渲染产物 = 单元测试产物，无新增运行期风险
- 跳过冗余的 curl 验证保持 tasks.md 短小

## Risks / Trade-offs

- **[Risk] FeatureNavSlot 一旦改写，homepage-shell 主 spec 中"完全空容器"约束就破了** → Mitigation：本变更归档时必须同步更新主 spec（D5 + tasks 6.x 强制化）
- **[Risk] 占位 `#` 可能被误认为可点击业务入口** → Mitigation：tasks 中要求所有 item 的 `href` 严格 `=== "#"`；spec 加一条 Scenario 守护
- **[Trade-off] 不限制 item 数量上界** → spec 只断言 `>= 1`；具体数量由 data 文件控制，不强制 spec 锁定。后续如果 hot-posts 等区块需要锁数量再各自约束
