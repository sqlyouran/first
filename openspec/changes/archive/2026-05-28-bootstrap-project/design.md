# Design: Bootstrap Project Skeleton

## 决策一览

| 决策 | 选择 | 理由 |
|---|---|---|
| Harness 配置目录命名 | `.qoder/` | 当前用户使用 Qoder IDE，原生对齐 |
| OpenSpec 落地方式 | `npx @fission-ai/openspec@latest init --tools qoder` | 拿到官方 schema、config.yaml、opsx 命令与 openspec-* skill，与上游同步演进 |
| Node 环境 | nvm 安装 LTS（v24+） | OpenSpec CLI 要求 ≥ 20.19；本机原装为 20.18 |
| Skills 双轨 | OpenSpec 官方 4 个 + Superpowers 8 个共存 | 官方 skill 驱动 spec 工作流；Superpowers skill 补充质量边界（TDD/review/worktree） |
| 代码变更命名空间 | 官方 `opsx/` + 本项目作为首个 change | 自描述：脚手架本身就是第一次“变更”，同时演示完整流程 |

## 三层映射图

```
        用户
         |
         v
   ┌─────────────┐
   │  Harness    │  .qoder/   (rules / commands / agents / skills)
   │  (Qoder)    │
   └──────┬──────┘
          | 读取规则与 skill，触发命令
          v
   ┌─────────────┐
   │  OpenSpec   │  openspec/  (project.md / specs / changes)
   │  (流程产物) │
   └──────┬──────┘
          | 实现产出
          v
   ┌─────────────┐
   │   src/      │  业务代码
   └─────────────┘
```

## 备选方案

**方案 B：纯理念落地，不跑 init**——零依赖、可移植。
拒绝：用户明确要求“使用 openspec init 完成初始化”；且原版 init 带来 schema 验证、`/opsx:explore`、`update` 等能力，手工仿写越走越远。

**方案 C：`npm i -g` 安装**——藏在 PATH 里随手可用。
拒绝：`/usr/local/lib/node_modules` 不可写，要 sudo；npx 同样能调，且不会锁版本。

## 风险

- OpenSpec 官方 skill 与 Superpowers skill 可能职责重叠（都涵盖 propose/apply/archive）。**缓解**：按“官方 skill 负责 spec 产出，Superpowers skill 负责实现质量”划分，在 `spec-driven-workflow.md` 中明示。
- Node 版本依赖升级路径如果未来变更。**缓解**：README 明写 ≥ 20.19。
- 没有 git init，agent 试图 `git worktree` 会失败。**缓解**：`using-git-worktrees` 的“何时不用”中显式说明。

## 不引入

- 任何 lint/formatter/CI 配置——等具体语言栈定了再说。
- 真实 subagent 定义——`agents/` 仅留 README 模板。
