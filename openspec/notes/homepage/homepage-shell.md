# homepage-shell Spec

> 路径：`openspec/specs/homepage/homepage-shell.md`
> 实现位置：`frontend/app/page.tsx` + `frontend/app/layout.tsx` + `frontend/app/regions/*Slot.tsx`
> 角色：所有其它 6 个区块单元的**前置底座**

---

## 1. 模块边界

### 1.1 In Scope

- **重写** `frontend/app/page.tsx`：作为 Server Component，依次渲染 5 个 region Slot（不含 ai-launcher）
- **修改** `frontend/app/layout.tsx`：在 `<body>` 内 `{children}` 之后挂 `<AiLauncherSlot />`，使其跨页面常驻
- **创建** `frontend/app/regions/` 目录，下含 6 个空 Slot 组件文件：
  `HeroSlot.tsx` / `FeatureNavSlot.tsx` / `CityGridSlot.tsx` / `HotPostsSlot.tsx` / `HotSpotsSlot.tsx` / `AiLauncherSlot.tsx`
- 每个 Slot 渲染一个带 `data-region="<name>"` + `aria-label="<name> placeholder"` 的**空容器**（页内 5 个用 `<section>`，ai-launcher 用 `<div>`）
- 移除 `app/page.tsx` 当前对 `HelloMessage` / `fetchFromBackend` 的渲染（HelloMessage.tsx 与 lib/backend.ts 文件保留）
- 单测覆盖：5 个 region 按文档顺序存在 + page 内不出现 ai-launcher

### 1.2 Out of Scope

- 任何区块内部内容（文案、图片、数据、样式、交互）
- 任何 CSS 框架引入（Tailwind / shadcn 等留给独立 `frontend-styling-stack` change）
- 任何 mock 数据 / API 调用 / BFF 新逻辑
- 删除 `HelloMessage.tsx` 或 `lib/backend.ts`（链路覆盖保留）
- `backend/` 任何修改

---

## 2. 核心场景

### Scenario 1：page 渲染 5 个 region 按文档顺序

- **GIVEN** `app/page.tsx` 已重写
- **WHEN** 在 RTL 中执行 `render(<Page />)` 并取 `container.querySelectorAll('[data-region]')`
- **THEN** NodeList 长度等于 `5`
- **AND** 各节点 `data-region` 值依次为 `['hero','feature-nav','city-grid','hot-posts','hot-spots']`

### Scenario 2：page 内不渲染 ai-launcher（守护）

- **WHEN** `render(<Page />)` 后 `container.querySelector('[data-region="ai-launcher"]')`
- **THEN** 返回 `null`

### Scenario 3：layout 注入 ai-launcher 常驻槽位

- **GIVEN** 前端 dev server 已起
- **WHEN** `curl http://localhost:<port>/`
- **THEN** 响应 HTML 中存在恰好 1 个 `data-region="ai-launcher"` 元素
- **AND** 该元素在 DOM 顺序上**位于** 5 个页内 region 之后

### Scenario 4：HelloMessage 链路覆盖未被打断（回归）

- **WHEN** `cd frontend && npm test` 运行
- **THEN** `HelloMessage.test.tsx` 仍 GREEN
- **AND** `lib/backend.ts` 首行仍为 `import "server-only";`

### Scenario 5：BFF 边界守护

- **WHEN** 在 `frontend/app/` 下执行 `find . -name 'route.ts' -o -name 'route.tsx'`
- **THEN** 输出为空

### Scenario 6：Slot 独立渲染产物为空

- **GIVEN** 任一 Slot（如 `HeroSlot`）
- **WHEN** 在 RTL 中独立 `render(<HeroSlot />)`
- **THEN** 渲染出唯一一个带 `data-region` + `aria-label` 的空元素，无任何子节点文本

### Scenario 7：端到端首屏（异常路径——后端未起仍可访问）

- **GIVEN** Spring Boot 后端**未启动**（8080 不通）
- **WHEN** `curl http://localhost:<port>/`
- **THEN** 仍返回 HTTP `200`（page.tsx 不再依赖后端）
- **AND** HTML 含 6 个 `data-region` 占位

---

## 3. 数据结构

### 3.1 Slot 组件签名

所有 Slot 在骨架阶段**无 props**：

```ts
// frontend/app/regions/HeroSlot.tsx 示例（其它 5 个同形）
export default function HeroSlot(): JSX.Element {
  return <section data-region="hero" aria-label="hero placeholder" />;
}
```

### 3.2 Region 名与挂载位映射

| `data-region` 值 | Slot 文件 | 渲染位置 | 容器元素 |
|---|---|---|---|
| `hero` | `HeroSlot.tsx` | `app/page.tsx` 第 1 个 | `<section>` |
| `feature-nav` | `FeatureNavSlot.tsx` | `app/page.tsx` 第 2 个 | `<section>` |
| `city-grid` | `CityGridSlot.tsx` | `app/page.tsx` 第 3 个 | `<section>` |
| `hot-posts` | `HotPostsSlot.tsx` | `app/page.tsx` 第 4 个 | `<section>` |
| `hot-spots` | `HotSpotsSlot.tsx` | `app/page.tsx` 第 5 个 | `<section>` |
| `ai-launcher` | `AiLauncherSlot.tsx` | `app/layout.tsx` `{children}` 之后 | `<div>` |

### 3.3 数据来源

- 无任何数据；纯结构骨架
- 不引入常量文件、不引入 mock、不接 API、不读 env

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 文件结构

- [ ] `frontend/app/regions/` 目录存在
- [ ] 6 个 Slot 文件均存在并 default export 一个 React 组件
- [ ] `app/page.tsx` 仅 import 前 5 个 Slot，**未** import `AiLauncherSlot`
- [ ] `app/layout.tsx` import 且渲染 `<AiLauncherSlot />`，位于 `{children}` 之后

### 4.2 TDD

- [ ] `frontend/app/page.test.tsx` 新增 `renders 5 regions in document order` 用例
- [ ] 实现前该用例 RED，实现后 GREEN
- [ ] 新增护栏用例 `does not render ai-launcher region in page` 直接 GREEN
- [ ] `HelloMessage.test.tsx` 不动且仍 GREEN

### 4.3 端到端

- [ ] `cd frontend && npm test` 全绿
- [ ] `cd frontend && npm run build` 通过
- [ ] `curl http://localhost:<port>/` 返回 `200` 且 HTML 含 6 个 `data-region`
- [ ] 输出 HTML **不**含 `<h1>hello`（HelloMessage 已从首页 UI 移除）

### 4.4 边界守护

- [ ] `frontend/app/` 下无 `route.ts` / `route.tsx`
- [ ] `frontend/lib/backend.ts` 文件保留且首行仍为 `import "server-only";`
- [ ] 父仓 `git diff backend` 为空（submodule 指针未变）
- [ ] 未引入任何 CSS 框架或新 npm 依赖

### 4.5 文档同步

- [ ] `frontend/README.md` 追加《首页骨架》小节，列出 6 个 region 与对应后续 spec 单元
- [ ] `openspec/specs/http-server/spec.md` 中"通过前端 Next.js SSR 调后端访问" Scenario 同步调整断言（HelloMessage 链路存在性 → 由单测保住）

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **本单元依赖** | 无 | 所有其它 6 个单元的前置；必须先落地、archive |
| **被本单元解锁** | `homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-posts` / `homepage-hot-spots` / `homepage-ai-launcher` | 本单元 archive 后可并行启动 |
| **不依赖** | 任何后端 API / mock / 样式栈 | 纯结构 |
