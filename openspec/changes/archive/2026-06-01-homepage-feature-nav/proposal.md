## Why

`homepage-shell` 已落地 6 个 region 容器，但全部为空。要让首页骨架开始具备业务可视化价值，需要按区块逐个注入内容。`feature-nav` 是 6 个区块中复杂度最低的（纯静态 UI、无后端依赖、无动态数据），适合作为「区块内容注入」工作流的首条试跑链路：先把"打破空容器、提供具体内容、保持薄 BFF 边界"的模式跑通，后续 5 个区块可参照同形推进。

## What Changes

- 新增最小化的 `FeatureNavItem` 数据结构（只含 `label` / `href`，硬编码常量数组）
- 改写 `frontend/app/regions/FeatureNavSlot.tsx`：从空 `<section>` 改为渲染 1 个 `<a>` 子节点（**BREAKING** 对 `homepage-shell` 中"FeatureNavSlot 完全空容器"约束的契约变更）
- 新增 `frontend/app/regions/featureNav.data.ts`（或同等命名）作为硬编码常量来源
- 单测覆盖：`FeatureNavSlot` 渲染出至少 1 个 `<a>` 子节点 + `data-region="feature-nav"` 仍存在
- 不创建任何 `app/<route>/page.tsx`、不动 `lib/backend.ts`、不动后端

## Capabilities

### New Capabilities

- `homepage-feature-nav`: 首页 feature-nav 区块的内容契约（最小可见、硬编码、占位链接）

### Modified Capabilities

- `homepage-shell`: 解除"FeatureNavSlot 必须为完全空容器"的约束（仅针对 feature-nav 子条款；其它 4 个页内 Slot 与 ai-launcher 仍保持空容器约束不变）

## Impact

- **代码**：仅 `frontend/app/regions/FeatureNavSlot.tsx`（改写）+ `frontend/app/regions/featureNav.data.ts`（新增）+ 对应 `*.test.tsx`
- **依赖**：不引入新 npm 依赖
- **后端**：完全不动
- **BFF 边界**：仍不创建 `app/api/**/route.ts`，`lib/backend.ts` 首行 `import "server-only";` 守护未变
- **治理文档**：归档时同步更新 `openspec/specs/homepage-shell/spec.md` 中"所有 Slot 必须为完全空容器"该条 Requirement，将 FeatureNavSlot 从其约束范围内移除
