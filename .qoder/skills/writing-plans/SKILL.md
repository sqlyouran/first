---
name: writing-plans
description: 把 design.md 拆成可由实习生执行的 tasks.md
when-to-use: design.md 已签字，准备进入实现阶段
---

# writing-plans

目标：让一个**有热情、判断力差、缺项目上下文、讨厌测试**的初级工程师也能照着做对。

## 任务粒度

- 每条任务 2-5 分钟可完成。
- 每条任务包含：
  - 具体文件路径
  - 完整代码片段或精确改动指引
  - 验证步骤（怎么知道做对了）
  - 测试断言

## tasks.md 模板

```markdown
# Tasks: <change-name>

## 1. <模块名>
- [ ] 1.1 在 `src/foo.py` 创建 `Foo` 类，包含方法 `bar(x: int) -> int`
  - 验证：`pytest tests/test_foo.py::test_bar_returns_double` 通过
- [ ] 1.2 ...

## 2. <下一模块>
- [ ] 2.1 ...
```

## 强制原则

- **TDD 先行**：每个实现任务前必有"写失败测试"任务。
- **YAGNI**：tasks 中不出现"将来扩展"字样。
- **依赖显式**：任务 N 依赖 M 时显式标注 `(depends on M)`。

## 反模式

- 任务模糊（"实现登录功能"——太大）。
- 没有验证步骤。
- 把测试任务和实现任务合并成一条。
