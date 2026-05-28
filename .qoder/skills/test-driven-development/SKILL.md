---
name: test-driven-development
description: 严格的 RED-GREEN-REFACTOR 循环，不可绕过
when-to-use: 任何会改变运行时行为的代码改动
---

# test-driven-development

**核心信条**：没有失败测试在先的实现代码，必须删除重来。

## 循环

### RED — 红
1. 写一个**新测试**，断言尚不存在的行为。
2. 运行测试套件，亲眼看它失败。
3. 失败信息必须是**业务相关**的（"AssertionError: expected 4 got 0"），而不是 ImportError、SyntaxError。

### GREEN — 绿
1. 写**让该测试通过的最小代码**——硬编码返回值都可以接受。
2. 运行测试，确认通过。
3. 不在这一步追求优雅。

### REFACTOR — 重构
1. 在所有测试都绿的状态下，整理结构、消除重复。
2. 每次小改完都跑一次测试。
3. 红了立刻回退。

## 反模式（来自 superpowers）

- **跳过 RED**：先写实现再补测试 → 测试可能误报通过。
- **大跳跃 GREEN**：一次写一大段实现 → 失去节奏。
- **重构期改行为**：refactor 时新增/修改测试 → 你已经离开 refactor 阶段了。
- **不看失败信息**：跳过"亲眼看它失败"这一步 → 你不知道测试是不是在测对的东西。

## 例外

- 纯文档、注释、配置改动：无需 TDD。
- 探索性 spike：写一次性脚本可以不测，但成果**必须**走 TDD 重写后才进 `src/`。
