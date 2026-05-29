---
name: ap:review
description: "Review code and create review tasks. Planner-only."
argument-hint: "[scope]"
---

# /ap:review

审查代码并创建 review task。省略 scope 时审查整个项目或当前未提交变更。

## 工作流

1. 读取 `.agent-memory/agent-protocol.md` 确认角色匹配。
2. 加载 `.agent-memory/tasks.json`。
3. 检查代码，发现问题创建 task（type: `review`），追加到 tasks 数组。
4. 设置 `status: "pending"`、`created_by: "planner"`，填充 `id`、`title`、`context`、`spec`。
5. 不修改业务代码，仅创建 review task。
