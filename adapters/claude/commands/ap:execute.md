---
name: ap:execute
description: "Claim and execute pending tasks. Executor-only."
argument-hint: "[task-id|next]"
---

# /ap:execute

认领并执行 pending task。省略参数时默认为 `next`。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 选择 task：按 `priority`（high > medium > low）排序，同优先级按 `created_at` 升序。
4. 将选中的 task 改为 `in_progress`。
5. 按 `spec` 实现，完成后标记 `done`，填写 `implementation_notes`。
6. 不修改 Planner 字段，不标记 `verified`。
