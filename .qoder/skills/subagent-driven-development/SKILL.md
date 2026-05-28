---
name: subagent-driven-development
description: 派发 fresh subagent 执行单条任务，二阶段评审
when-to-use: 任务可独立完成 / 需要并发推进 / 主上下文窗口快满
---

# subagent-driven-development

每个任务派一个**全新上下文**的 subagent 干活，干完两阶段 review，再合并回主线。

## 派发模板

```
Task: <task-id from tasks.md>
Inputs:
  - design.md 相关章节
  - tasks.md 该条目
  - 涉及的源文件路径
Output:
  - 改动文件列表
  - 测试结果摘要
  - 偏离 design 的说明（若有）
```

## 二阶段评审

第一阶段：**spec 合规**（用 `spec-reviewer` subagent）
- 改动是否落在 design.md 范围内？
- 是否完成了 tasks.md 该条所有验证步骤？
- 是否有 YAGNI 违规（多写了不该写的）？

第二阶段：**代码质量**（用 `code-reviewer` subagent）
- 命名、可读性、错误处理。
- 测试覆盖、边界情况。
- 性能与安全的明显坑。

任一阶段不通过 → 退回当前 subagent 修复，主上下文不接收脏代码。

## 何时**不**用

- 任务 < 2 分钟：直接做更快。
- 任务严重依赖前一个任务的运行时输出：派出去会丢上下文。
- 全局重构：跨文件协调，subagent 看不全。
