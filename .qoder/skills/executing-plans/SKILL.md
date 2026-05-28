---
name: executing-plans
description: 按批次推进 tasks.md，每批次设人类检查点
when-to-use: tasks.md 已签字，开始线性推进实现
---

# executing-plans

## 节奏

```
拿出下一批 (3-5 条) → TDD 实现 → 全部绿灯 → 汇报 → 等用户 OK → 下一批
```

## 每条任务的内部循环

委托给 `test-driven-development` skill：

1. RED：写测试，运行，确认失败。
2. GREEN：写最小实现，运行，确认通过。
3. REFACTOR：在绿灯下整理结构。
4. 在 tasks.md 中把 `- [ ]` → `- [x]`。

## 批次汇报模板

```
完成 1.1 ~ 1.4：
- 新增测试 4 个，全部通过
- 改动文件：src/foo.py, tests/test_foo.py
- 偏离 design 的地方：无 / <说明>

是否继续下一批 (1.5 ~ 1.8)？
```

## 何时停下

- 测试失败且 30 秒内修不好 → 停下问用户。
- 发现 design 有问题 → 停下回 propose。
- 完成 3-5 条 → 停下汇报。

## 反模式

- 一口气做完所有任务才汇报。
- 测试红着继续往下做。
- 在没记录的地方偷偷修改了 design 决策。
