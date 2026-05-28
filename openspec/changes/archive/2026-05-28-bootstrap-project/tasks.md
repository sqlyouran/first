# Tasks: Bootstrap Project Skeleton

> 注：本变更已由初始化脚手架直接落地，下方任务全部标记为 `[x]`，作为审计轨迹保留。
> 后续真实开发请在新建 change 中按此模板编写，并严格走 RED→GREEN→REFACTOR。

## 1. 根目录与文档
- [x] 1.1 创建 `AGENTS.md`（三层架构与硬规则）
- [x] 1.2 创建 `README.md`（项目说明与上手指引）
- [x] 1.3 创建 `.gitignore`（通用忽略）
- [x] 1.4 创建 `src/.gitkeep`（业务代码占位）

## 2. Harness 层（.qoder/）
- [x] 2.1 `rules/coding-conventions.md`（YAGNI/DRY/TDD）
- [x] 2.2 `rules/spec-driven-workflow.md`（强制流程顺序，指向 `/opsx:*`）
- [x] 2.3 `agents/README.md`【subagent 占位】
- [x] 2.4 删除手写的 `commands/{propose,apply,archive}.md`（与 `opsx/` 重复）

## 3. Skills 层（.qoder/skills/）

### 3a Superpowers 手写（8 个）
- [x] 3a.1 `brainstorming/SKILL.md`
- [x] 3a.2 `writing-plans/SKILL.md`
- [x] 3a.3 `executing-plans/SKILL.md`
- [x] 3a.4 `test-driven-development/SKILL.md`
- [x] 3a.5 `subagent-driven-development/SKILL.md`
- [x] 3a.6 `using-git-worktrees/SKILL.md`
- [x] 3a.7 `requesting-code-review/SKILL.md`
- [x] 3a.8 `verification-before-completion/SKILL.md`

### 3b OpenSpec init 注入（4 个）
- [x] 3b.1 `openspec-propose/SKILL.md`
- [x] 3b.2 `openspec-apply-change/SKILL.md`
- [x] 3b.3 `openspec-archive-change/SKILL.md`
- [x] 3b.4 `openspec-explore/SKILL.md`
- [x] 3b.5 官方同时注入 `.qoder/commands/opsx/{propose,apply,archive,explore}.md`

## 4. OpenSpec 层（openspec/）
- [x] 4.1 `nvm install --lts` 升级 Node 到 v24（原 20.18 < 20.19 要求）
- [x] 4.2 运行 `npx @fission-ai/openspec@latest init --tools qoder --force`
- [x] 4.3 生成 `openspec/config.yaml`（schema: spec-driven）
- [x] 4.4 从脚手架备份迁回 `openspec/project.md`
- [x] 4.5 补全 `openspec/specs/.gitkeep`、`openspec/changes/archive/.gitkeep`
- [x] 4.6 本变更目录 `0001-bootstrap-project/{proposal,design,tasks}.md`

## 5. 验证
- [x] 5.1 目录树存在且结构与 `design.md` 中的图一致
- [x] 5.2 所有 markdown 模板包含必要 frontmatter（skills/rules）
- [x] 5.3 README 与 AGENTS.md 中的内部链接路径指向实际生成的 `opsx/` 与 `openspec-*` skills
- [x] 5.4 `npx @fission-ai/openspec@latest list` 可识别本仓库（依赖后续 change 验证）

## 后续（不在本变更范围）
- [x] 由用户选定语言栈后，新建 change `0002-pick-tech-stack` 回填 `project.md` 的“技术栈”小节——已由 `0002-springboot-skeleton` 完成（只是改名为 springboot-skeleton）
- [ ] 用户运行 `git init` 并首次提交（留给用户外部执行，不属代码变更）
