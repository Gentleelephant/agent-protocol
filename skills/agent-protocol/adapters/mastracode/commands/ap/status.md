---
name: ap:status
description: "Summarize task counts and next recommended action. Read-only, any role."
---

# /ap:status

汇总任务数量和下一步建议。通用只读命令，任何角色均可执行。

## 工作流

1. 加载 `.agent-memory/tasks.json`。
2. 按 status 统计 task 数量。
3. 给出建议：有 pending → 建议 `/ap:execute next`；有 done → 建议 `/ap:verify all`。
