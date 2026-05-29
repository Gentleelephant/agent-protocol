---
name: ap:done
description: "Mark task done and fill implementation notes. Executor-only."
argument-hint: "[task-id]"
---

# /ap:done

标记 task 为 `done` 并填写实现说明。省略参数时针对当前 `in_progress` task。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 定位目标 task：有参数时按 task-id 查找，省略时找当前 `in_progress` task。
4. 将 task `status` 改为 `done`，填写 `implementation_notes` 和 `updated_at`。
5. 不修改 Planner 字段（`spec`、`context`、`title`、`created_by`）。
6. 不标记 `verified`——那是 Planner 的工作。
