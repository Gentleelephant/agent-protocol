---
description: "Claim and execute pending tasks (Executor-only)"
argument-hint: "[task-id|next]"
---

# /ap:execute

用户执行了 `/ap:execute $ARGUMENTS`。

请加载 `agent-protocol` skill 并以 Executor 角色认领并执行 pending task。
按 `spec` 实现，完成后标记 `done` 并填写 `implementation_notes`。
