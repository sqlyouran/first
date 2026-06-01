# homepage-hot-posts Spec

> 路径：`openspec/specs/homepage/homepage-hot-posts.md`
> 承接挂载位：`homepage-shell` 在 `app/page.tsx` 第 4 个 region 提供的 `data-region="hot-posts"` 槽位
> 实现位置：`frontend/app/regions/HotPostsSlot.tsx`
> 数据：本期 mock，TS 类型同时作为后续 `api-hot-posts` 单元的契约占位

## 0. 前置依赖

依赖 `frontend-styling-stack`（待 propose）引入 Tailwind + shadcn/ui。

---

## 1. 模块边界

### 1.1 In Scope

- 渲染**至多** 10 条社区帖子卡片，按 **过去 7 天 Upvote 数** 降序
- 每条帖子卡片：**标题** + **作者名** + **Upvote 数** + **跳转链接** `/post/<id>`
- 响应式：`< 768px` 单列 / `≥ 768px` 双列
- 区域顶部含小标题 `<h2>"热门帖子"`
- mock 数据驱动；TS 类型 `HotPost` 作为后续真实 API 契约
- 数据为空 / 不足 10 条时的空态与降级展示
- a11y：列表语义 `<ul>` / `<li>`、整卡可聚焦

### 1.2 Out of Scope

- **真实后端 API**（属独立单元 `api-hot-posts`）
- 帖子详情页（`/post/<id>` 路由本身属其它 spec）
- 分页 / 加载更多 / 无限滚动
- 帖子内联点赞、收藏、评论交互
- 排序切换（"最新" / "最热" 切换 tab）
- 用户维度个性化推荐
- 实时刷新 / SSE 推送

---

## 2. 核心场景

### Scenario 1：渲染 Top 10 按 upvote 降序（happy path）

- **GIVEN** mock 数组含 ≥ 10 条 `HotPost`
- **WHEN** 渲染 `HotPostsSlot`
- **THEN** 区域内含恰好 10 个 `<li>` 帖子卡片
- **AND** 卡片顺序按 `weeklyUpvotes` 字段**降序**排列
- **AND** 第 1 张的 `weeklyUpvotes` ≥ 第 10 张

### Scenario 2：mock 给的顺序被打散（排序逻辑守护）

- **GIVEN** mock 数组按 `id` 升序但 `weeklyUpvotes` 乱序
- **WHEN** 渲染
- **THEN** 渲染结果仍按 `weeklyUpvotes` 降序，与输入顺序无关

### Scenario 3：数据不足 10 条（降级路径）

- **GIVEN** mock 数组长度 `n` 满足 `0 < n < 10`
- **WHEN** 渲染
- **THEN** 全部 `n` 条都展示，按 upvote 降序
- **AND** 不出现"占位骨架"或"加载中"
- **AND** 容器底部不留空 padding

### Scenario 4：数据为空（空态）

- **GIVEN** mock 数组为 `[]`
- **WHEN** 渲染
- **THEN** 区域显示空态文案 `"暂无热门帖子，去社区逛逛？"` + 跳转 `/community` 的链接
- **AND** **不**渲染任何 `<li>`
- **AND** `<h2>` 标题仍渲染

### Scenario 5：相同 upvote 的稳定排序

- **GIVEN** 两条帖子 `weeklyUpvotes` 相同
- **WHEN** 排序
- **THEN** 较新的（`createdAt` 较大）排在前
- **AND** `createdAt` 也相同时按 `id` 字典序排（保证渲染稳定，无 React key 抖动）

### Scenario 6：响应式

- **WHEN** 视口 `< 768px`
- **THEN** 卡片单列纵排（`grid-cols-1`）
- **WHEN** 视口 `≥ 768px`
- **THEN** 卡片双列（`md:grid-cols-2 gap-4`）

### Scenario 7：SSR 真实存在

- **WHEN** `curl /`
- **THEN** HTML 直接包含至少前 5 条帖子的标题与作者文本（非客户端水合）

### Scenario 8：异常输入（构建期防护）

- **GIVEN** mock 中某条 `weeklyUpvotes < 0` 或 `id` 重复
- **WHEN** 单测加载 mock
- **THEN** 用例失败（`expect(allUnique(ids)).toBe(true)` + `expect(every(p => p.weeklyUpvotes >= 0)).toBe(true)`）

---

## 3. 数据结构

### 3.1 类型定义（同时作为后续 API 契约）

```ts
// frontend/lib/mocks/hot-posts.ts
export type HotPost = {
  /** 帖子唯一 ID */
  id: string;
  /** 帖子标题 */
  title: string;
  /** 作者展示名 */
  author: string;
  /** 过去 7 天净 upvote 数（已减 downvote） */
  weeklyUpvotes: number;
  /** ISO 8601 创建时间，用于同分排序 */
  createdAt: string;
  /** 跳转 href，必须形如 /post/<id> */
  href: string;
};
```

### 3.2 mock 数据约束

```ts
export const HOT_POSTS_MOCK: readonly HotPost[] = [
  // ... 建议 10–15 条；本 spec 不固定具体内容
];
```

| 字段 | 约束 |
|---|---|
| `id` | 全数组唯一，`^[a-z0-9-]+$` |
| `title` | CJK 4–40 字 / 拉丁 8–80 字符 |
| `author` | CJK 2–10 字 / 拉丁 2–20 字符 |
| `weeklyUpvotes` | 整数 ≥ 0 |
| `createdAt` | 合法 ISO 8601 字符串 |
| `href` | 必须等于 `/post/${id}` |

### 3.3 组件 Props

```ts
// frontend/app/regions/HotPostsSlot.tsx
export type HotPostsSlotProps = {
  /** 可选注入；默认使用 HOT_POSTS_MOCK */
  posts?: readonly HotPost[];
  /** 取前 N 条；默认 10 */
  limit?: number;
};
```

### 3.4 排序契约

```ts
// frontend/app/regions/hot-posts.utils.ts
export function sortByUpvotes(posts: readonly HotPost[]): HotPost[] {
  return [...posts].sort((a, b) => {
    if (b.weeklyUpvotes !== a.weeklyUpvotes) return b.weeklyUpvotes - a.weeklyUpvotes;
    if (a.createdAt !== b.createdAt) return b.createdAt.localeCompare(a.createdAt);
    return a.id.localeCompare(b.id);
  });
}
```

### 3.5 数据来源

- **本期**：`frontend/lib/mocks/hot-posts.ts` 静态 mock 数组
- **后续**：`api-hot-posts` 单元落地后，将 `HotPostsSlot` 改为 async Server Component，`await fetchFromBackend('/api/hot-posts')`，返回 JSON 即 `HotPost[]`
- 本单元**不**改 `lib/backend.ts`、**不**新增 Route Handler

---

## 4. 验收标准（ACCEPTANCE Checklist）

### 4.1 结构

- [ ] `HotPostsSlot.tsx` 是 Server Component，根节点 `<section data-region="hot-posts">`
- [ ] section 含 `<h2>` 小标题"热门帖子"
- [ ] 数据非空时含 `<ul>` + ≤10 个 `<li>`
- [ ] 数据为空时含空态文案与 `<a href="/community">`

### 4.2 排序逻辑

- [ ] 排序函数 `sortByUpvotes` 单元测试覆盖：
  - [ ] 不同 upvote 降序
  - [ ] 相同 upvote 时按 createdAt 降序
  - [ ] 三者均同时按 id 升序
- [ ] 渲染结果与 `sortByUpvotes(mock).slice(0, limit)` 严格一致

### 4.3 视觉与响应式

- [ ] 容器 class：`grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4`
- [ ] 卡片用 shadcn `<Card>`，含 `<CardTitle>` `<CardDescription>` `<CardFooter>`
- [ ] 标题字号 `text-base md:text-lg`，2 行截断 `line-clamp-2`
- [ ] Upvote 数字带 `<TrendingUp />` 图标 + 数字
- [ ] 卡片整体可点击（`<a>` 包裹），hover 态 `hover:shadow-md`

### 4.4 mock 数据校验

- [ ] `HOT_POSTS_MOCK` 长度 `≥ 10`
- [ ] 单元测试断言：所有 `id` 唯一、所有 `href === '/post/' + id`、所有 `weeklyUpvotes ≥ 0`、所有 `createdAt` 为合法 ISO 字符串

### 4.5 测试（TDD）

- [ ] `hot-posts.utils.test.ts`：
  - [ ] RED → GREEN：3 个排序用例
- [ ] `HotPostsSlot.test.tsx`：
  - [ ] 用例：mock ≥10 条 → 渲染 10 个 `<li>` 且降序
  - [ ] 用例：mock < 10 条 → 渲染全部
  - [ ] 用例：mock 为空 → 空态文案 + 跳社区链接
  - [ ] 用例：传 `limit=5` → 渲染 5 个
- [ ] `app/page.test.tsx` 仍 GREEN

### 4.6 端到端

- [ ] `npm run build` 通过
- [ ] `npm test` 全绿
- [ ] `curl /` HTML 包含至少前 5 条帖子标题（验证 SSR 真实生效）
- [ ] Lighthouse a11y ≥ 95

### 4.7 边界守护

- [ ] 未新增 `route.ts` / `route.tsx`
- [ ] `lib/backend.ts` 未被本单元修改
- [ ] `backend/` submodule 指针未变
- [ ] 未引入网络请求库（无 axios / swr / react-query）

---

## 5. 与其它单元的依赖关系

| 关系 | 单元 | 说明 |
|---|---|---|
| **必须先于本单元落地** | `homepage-shell` | 提供 `data-region="hot-posts"` 挂载位 |
| **必须先于本单元落地** | `frontend-styling-stack`（待 propose） | Tailwind + shadcn/ui + lucide-react |
| **本单元定义、后续单元消费** | `api-hot-posts`（未来 propose） | 共享 `HotPost` 类型；mock 替换为 `await fetchFromBackend('/api/hot-posts')` |
| **与本单元正交** | `homepage-hero` / `homepage-feature-nav` / `homepage-city-grid` / `homepage-hot-spots` / `homepage-ai-launcher` | 各自独立 Slot |
| **本单元不依赖** | `backend/` 改动 | 后端 API 由 `api-hot-posts` 负责 |
