# Proposal: Bootstrap Project Skeleton

## Why

我们要让任何 AI agent 进入这个仓库就能立刻按一致的工作流推进开发，而不是每次重新讨论"怎么干"。
解决方案：把 Harness（IDE 配置）+ OpenSpec（spec 驱动）+ Superpowers（skills 方法论）三层理念固化为目录骨架。

## What Changes

- 运行 `npx @fission-ai/openspec@latest init --tools qoder --force`，完成官方初始化：
  - 生成 `openspec/config.yaml`（schema: spec-driven）
  - 注入官方 4 个斜杠命令：`.qoder/commands/opsx/{propose,apply,archive,explore}.md`
  - 注入官方 4 个 skill：`.qoder/skills/openspec-{propose,apply-change,archive-change,explore}/SKILL.md`
- 手工补充 Superpowers 理念（`.qoder/skills/` 下 8 个）：brainstorming, writing-plans, executing-plans, test-driven-development, subagent-driven-development, using-git-worktrees, requesting-code-review, verification-before-completion
- 手工补充 `.qoder/rules/`（coding-conventions, spec-driven-workflow）与 `.qoder/agents/README.md`
- 补全 `openspec/project.md`、`openspec/specs/`、`openspec/changes/archive/`
- 新增根级 `AGENTS.md` / `README.md` / `.gitignore` / `src/.gitkeep`

## Out of Scope

- 选定具体编程语言或测试框架（留到 `0002-pick-tech-stack`）
- 初始化 git 仓库、配置 CI、Docker 等基础设施
- 编写任何业务逻辑代码

## Open Questions

- [x] 项目最终用什么语言栈？已在 `0002-springboot-skeleton` 中选定 Java 17 + Spring Boot 3.3.5 + Vite/React，并回填 `openspec/project.md`
- [ ] 是否需要在后续 change 中调整，让 superpowers skill 与 openspec-* skill 明确职责划分
