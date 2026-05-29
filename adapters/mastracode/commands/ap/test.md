---
name: ap:test
description: "Run verification and record results. Executor-only."
argument-hint: "[task-id]"
---

# /ap:test

运行验证并记录结果。省略参数时针对当前 `in_progress` task。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 定位 task，运行相关测试或检查。
4. 将结果写入 `implementation_notes`，更新 `updated_at`。
