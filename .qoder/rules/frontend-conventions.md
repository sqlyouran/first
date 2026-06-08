---
trigger: always_on
---
# 前端编码规约

前端采用 Next.js 16 (App Router) + React 19 + TypeScript。以下为 SHOULD 级约定。

## 目录结构

```
app/
├── regions/          ← 首页 Region-Slot 组件
├── (group)/          ← 路由组（如 (auth)）
│   ├── _components/  ← 路由组内部复用组件
│   └── page.tsx
├── layout.tsx        ← 根布局（AuthProvider + 全局组件）
└── page.tsx          ← 页面编排
components/ui/        ← shadcn/ui 基础组件（不手动修改）
lib/
├── api/              ← API 客户端函数
├── stores/           ← Zustand stores
└── utils.ts          ← 纯工具函数
```

## Region-Slot 模式（首页区域）

- 每个区域由 `*Slot.tsx`（视图）+ `*.data.ts`（静态数据 + 类型定义）配对
- Slot 组件根元素带 `data-region="xxx"` 属性
- Slot 组件不 import fetch / `lib/backend`（测试中强制验证）
- 数据文件导出 `readonly` 数组 + 类型

## 组件原则

- 默认 Server Component，仅在需要交互/浏览器 API 时加 `"use client"`
- 路由组内部复用组件放 `_components/` 目录
- shadcn/ui 组件通过 `@/components/ui/xxx` 导入，不手动修改其源码

## 状态管理

- 用 Zustand：`create<T>()` 模式
- 一个领域一个 store 文件（如 `stores/auth.ts`）
- store 内聚合 state + actions，不拆分

## API 封装层

- 统一使用 `ApiResponse<T>` 泛型包装返回值
- 每个 API 函数内部处理 network error / server error 兜底
- 错误结构：`ApiError { request_id, error_code, message, details? }`
- 仅 `"use client"` 文件中直接调用 API 函数

## 路由守卫

- 通过 `middleware.ts` 实现（基于 cookie 判断）
- 不在组件内部做重定向逻辑（除非是 post-action 跳转）

## 测试

- 用 Vitest + React Testing Library
- 测试文件与源文件同目录（`Xxx.test.tsx`）
- Region-Slot 测试需验证：DOM 结构 + data-region 属性 + 不依赖 fetch
