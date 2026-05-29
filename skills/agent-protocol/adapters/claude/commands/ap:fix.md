---
name: ap:fix
description: "Fix a specific bug or review task. Executor-only."
argument-hint: "[task-id]"
---

# /ap:fix

修复指定 bug/review task。省略参数时匹配 claimed (`in_progress`) 或 pending bug/review task。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 定位 task：有参数按 task-id 查找，省略时找 type 为 `bug` 或 `review` 的 `in_progress` 或 `pending` task。
4. 改为 `in_progress`，按 `spec` 修复。
5. 完成后标记 `done`，填写 `implementation_notes`。
