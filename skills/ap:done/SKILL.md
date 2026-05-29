---
description: "Mark task done and fill implementation notes (Executor-only)"
argument-hint: "[task-id]"
---

# /ap:done

用户执行了 `/ap:done $ARGUMENTS`。

请加载 `agent-protocol` skill 并以 Executor 角色标记 task 为 `done` 并填写 `implementation_notes`。
省略参数时针对当前 in_progress task。
