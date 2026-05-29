---
name: ap:task
description: "Save discussion result as a pending task. Planner-only."
argument-hint: "[summary]"
---

# /ap:task

把当前讨论结果保存为 pending task。省略 summary 时总结最近讨论主题。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 根据讨论内容创建 task，追加到 tasks 数组。
4. 设置 `status: "pending"`、`created_by: "planner"`，填充所有必填字段。
