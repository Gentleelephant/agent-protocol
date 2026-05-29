---
description: "Review code and create review tasks (Planner-only)"
argument-hint: "[scope]"
---

# /ap:review

用户执行了 `/ap:review $ARGUMENTS`。

请加载 `agent-protocol` skill 并以 Planner 角色执行代码审查。
不修改业务代码，仅创建 review task 并追加到 `.agent-memory/tasks.json`。
