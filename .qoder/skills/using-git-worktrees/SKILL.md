---
name: using-git-worktrees
description: 在隔离 worktree 上推进变更，主分支保持干净
when-to-use: design.md 通过后，进入实现前
---

# using-git-worktrees

## 为什么

- 主分支随时可演示，实验性改动隔离在 worktree。
- 多个变更可并行推进，不互相污染。
- 切回主分支不需要 stash。

## 标准流程

1. **创建 worktree**（变更名与分支名一致）：
   ```bash
   git worktree add ../<repo>-<change-name> -b <change-name>
   cd ../<repo>-<change-name>
   ```

2. **运行项目初始化**：依赖安装、env 准备、跑一遍测试基线。

3. **确认绿灯基线**：所有现有测试在新 worktree 里都通过，否则不能开始改。

4. **开始 TDD 循环**。

5. **完成后**：合并/PR 决策走 `finishing-a-development-branch`（本骨架未单列，由 archive 命令承担）。

## 命名约定

- worktree 目录：`../<repo-name>-<change-name>`
- 分支：与 `openspec/changes/<change-name>/` 同名

## 何时**不**用

- 仓库尚未 `git init`：先 init 再说。
- 单人短周期改动且改动小：直接在主分支也行，但仍需走 OpenSpec 文档流。
