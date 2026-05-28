---
name: requesting-code-review
description: 任务批次完成后的自检与请求人类 review
when-to-use: tasks.md 一批完成后 / archive 之前
---

# requesting-code-review

## 自检清单（先自己过一遍）

- [ ] tasks.md 涉及条目全部 `- [x]`
- [ ] 全部测试本地绿灯（贴出运行命令和结果）
- [ ] 没有未在 design.md 中授权的新依赖、新文件、新接口
- [ ] 没有 TODO/FIXME 残留（或显式记录在 tasks.md 中）
- [ ] 注释只在意图不明显处，没有流水账注释
- [ ] 改动 diff 可在 5 分钟内读完，否则需要拆批次

## 请求 review 的格式

```
## 本批次改动

**关联**: openspec/changes/<name>/tasks.md 1.1 ~ 1.4
**Spec 合规**: 是 / 偏离说明

### 文件改动
- `src/foo.py` (+34 -2)
- `tests/test_foo.py` (+58 -0)

### 测试
- 新增 4 个用例，全部通过
- 命令: `pytest tests/test_foo.py -v`

### 已知风险
- <列出潜在问题，按 critical / major / minor 分级>

### 关注请帮我看
- <具体的问题，比如"边界值 0 的处理是否合理">
```

## 严重度

- **Critical**：错误结果、数据丢失、安全问题——必须修完才能往下。
- **Major**：可读性差、漏边界、性能隐患——下批次前修。
- **Minor**：风格、命名——可批量留到 archive 前一次性处理。
