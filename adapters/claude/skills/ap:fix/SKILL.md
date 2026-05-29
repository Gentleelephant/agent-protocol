---
description: "Fix a specific bug or review task (Executor-only)"
argument-hint: "[task-id]"
---

# /ap:fix

用户执行了 `/ap:fix $ARGUMENTS`。

请加载 `agent-protocol` skill 并以 Executor 角色修复指定 bug/review task。
省略参数时选择匹配的 claimed (in_progress) 或 pending bug/review task。
