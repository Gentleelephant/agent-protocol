---
description: "Verify done tasks and mark valid ones as verified (Planner-only)"
argument-hint: "[task-id|all]"
---

# /ap:verify

用户执行了 `/ap:verify $ARGUMENTS`。

请加载 `agent-protocol` skill 并以 Planner 角色验收 done task。
通过则标记为 `verified`，不通过则退回 `in_progress` 并追加反馈到 `implementation_notes`。
