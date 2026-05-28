# Subagents

放置自定义 subagent 定义（每个一个 `.md` 文件，含 frontmatter + 系统提示词）。

## 何时建 subagent

- 任务可并行（参考 `.qoder/skills/subagent-driven-development/SKILL.md`）
- 需要独立上下文窗口的专项工作（review、debug、调研）
- 需要二阶段评审：spec 合规检查 + 代码质量检查

## 命名建议

- `spec-reviewer.md` — 检查代码是否偏离 design.md
- `code-reviewer.md` — 通用代码质量审查
- `test-runner.md` — 运行并解读测试输出

## 模板

```markdown
---
name: <agent-name>
description: <一句话说明何时调用>
tools: [read_file, grep_code, search_codebase]
---

# 系统提示词

你是一个专门做 X 的 subagent。每次只关注 ...
返回格式：...
```

当前未预置任何 subagent，按需自行添加。
