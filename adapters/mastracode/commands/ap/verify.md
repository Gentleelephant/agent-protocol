---
name: ap:verify
description: "Verify done tasks and mark valid ones as verified. Planner-only."
argument-hint: "[task-id|all]"
---

# /ap:verify

验收 done task。通过则标记 `verified`，不通过则退回 `in_progress`。省略参数默认为 `all`。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 读取 task 的 `spec` 和 `implementation_notes`。
4. 检查代码变更是否匹配 task 要求。
5. 通过 → `verified`；不通过 → 退回 `in_progress`，在 `implementation_notes` 中追加反馈。
