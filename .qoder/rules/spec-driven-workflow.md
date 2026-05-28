---
description: Spec-driven 工作流强制规则，always-on 全局生效
trigger: always_on
---

# Spec-Driven Workflow

任何涉及 `src/` 改动的请求，必须按下列顺序推进，**不可跳步**：

```
brainstorming  →  propose  →  design  →  tasks  →  TDD 实现  →  code review  →  archive
```

## 各阶段约束

| 阶段 | 触发 | 产出物 | 人类把关点 |
|---|---|---|---|
| brainstorming | `.qoder/skills/brainstorming` | 对话产出的需求要点 | 用户确认需求理解 |
| propose | `/opsx:propose` (`.qoder/commands/opsx/propose.md`) | `openspec/changes/<name>/{proposal,design,tasks}.md` | 用户签字三件套 |
| 实现 | `/opsx:apply` + `.qoder/skills/test-driven-development` + `executing-plans` | `src/` 代码 + 测试 | 测试全绿 |
| review | `.qoder/skills/requesting-code-review` | review 报告 | critical 问题清零 |
| archive | `/opsx:archive` (`.qoder/commands/opsx/archive.md`) | `openspec/changes/archive/<date>-<name>/` | — |

## 例外

- 修复明显 typo / 注释 / 文档：可以跳过 propose，但仍需 TDD（如改了行为）。
- 仅修改 `.qoder/` 或 `openspec/` 自身的配置文件：无需走 OpenSpec 流程。

## 违反处理

如果发现 agent 跳步直接写 `src/`，立刻停止、回退、从 brainstorming 重来。
